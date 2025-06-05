#!/bin/bash

# Korwin Generator LXC Setup Script for Proxmox
# Usage: bash -c "$(curl -fsSL https://raw.githubusercontent.com/<your-username>/korwin-generator/main/setup_korwin_lxc.sh)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables (customize these)
CONTAINER_NAME="korwin-web-4545"
TEMPLATE="ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
REPO_URL="https://github.com/<your-username>/korwin-generator.git"
PORT=4545

# Function to print messages
msg() {
    echo -e "${1}"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    msg "${RED}Error: This script must be run as root. Use sudo.${NC}"
    exit 1
fi

# Check if pveam is installed
if ! command -v pveam &> /dev/null; then
    msg "${RED}Error: pveam not found. Ensure Proxmox VE is installed correctly.${NC}"
    exit 1
fi

# Step 1: Ensure the template is available
msg "${YELLOW}Checking for Ubuntu 22.04 template...${NC}"
if [ ! -f "/var/lib/vz/template/cache/$TEMPLATE" ]; then
    msg "${YELLOW}Template not found. Downloading Ubuntu 22.04...${NC}"
    pveam download local "$TEMPLATE" || {
        msg "${RED}Error: Failed to download template. Available templates:${NC}"
        pveam available
        exit 1
    }
fi

# Step 2: Find an unused container ID
msg "${YELLOW}Finding an unused container ID...${NC}"
CTID=100
while lxc-info -n "$CTID" &>/dev/null; do
    CTID=$((CTID + 1))
done
msg "Using container ID: $CTID"

# Step 3: Create the LXC container
msg "${YELLOW}Creating LXC container $CONTAINER_NAME with ID $CTID...${NC}"
if lxc-info -n "$CONTAINER_NAME" &>/dev/null; then
    msg "${YELLOW}Container $CONTAINER_NAME already exists. Stopping and deleting it...${NC}"
    lxc-stop -n "$CONTAINER_NAME" || true
    lxc-destroy -n "$CONTAINER_NAME" || true
fi
pct create "$CTID" "local:vztmpl/$TEMPLATE" -hostname "$CONTAINER_NAME" -cores 1 -memory 512 -net0 name=eth0,bridge=vmbr0,ip=dhcp -password "yourpassword" || {
    msg "${RED}Error: Failed to create container.${NC}"
    exit 1
}
lxc-start -n "$CTID" || {
    msg "${RED}Error: Failed to start container.${NC}"
    exit 1
}
sleep 15  # Wait for container to boot and network to initialize

# Step 4: Install dependencies in the container
msg "${YELLOW}Installing dependencies in the container...${NC}"
lxc-attach -n "$CTID" -- /bin/bash <<'EOF'
apt update
apt install -y python3 python3-pip git supervisor
pip3 install flask
EOF

# Step 5: Clone the GitHub repository
msg "${YELLOW}Cloning the Korwin Generator repository...${NC}"
lxc-attach -n "$CTID" -- /bin/bash <<EOF
mkdir -p /app
cd /app
git clone $REPO_URL .
if [ ! -f "/app/app.py" ]; then
    echo "Error: app.py not found in repository. Check REPO_URL."
    exit 1
fi
EOF

# Step 6: Modify app.py to use port 4545
msg "${YELLOW}Configuring Flask app to run on port $PORT...${NC}"
lxc-attach -n "$CTID" -- /bin/bash <<EOF
sed -i 's/app.run(host="0.0.0.0", port=5000, debug=False)/app.run(host="0.0.0.0", port=$PORT, debug=False)/' /app/app.py
EOF

# Step 7: Create a systemd service to run the Flask app
msg "${YELLOW}Setting up systemd service for the Flask app...${NC}"
lxc-attach -n "$CTID" -- /bin/bash <<'EOF'
cat > /etc/supervisor/conf.d/korwin-web.conf <<'INNEREOF'
[program:korwin-web]
directory=/app
command=/usr/bin/python3 /app/app.py
autostart=true
autorestart=true
stderr_logfile=/var/log/korwin-web.err.log
stdout_logfile=/var/log/korwin-web.out.log
INNEREOF
supervisorctl reread
supervisorctl update
supervisorctl start korwin-web
EOF

# Step 8: Get container IP and verify
msg "${YELLOW}Verifying setup...${NC}"
CONTAINER_IP=$(lxc-ls -f | grep "$CTID" | awk '{print $5}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
if [ -z "$CONTAINER_IP" ]; then
    msg "${RED}Error: Failed to get container IP. Check network configuration. Attempting to fetch IP again...${NC}"
    sleep 10  # Wait a bit longer for network
    CONTAINER_IP=$(lxc-ls -f | grep "$CTID" | awk '{print $5}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
    if [ -z "$CONTAINER_IP" ]; then
        msg "${RED}Error: Still unable to get container IP. Check Proxmox network settings (e.g., vmbr0 bridge, DHCP).${NC}"
        exit 1
    fi
fi

# Step 9: Output results
msg "${GREEN}Setup complete!${NC}"
msg "Container Name: $CONTAINER_NAME"
msg "Container ID: $CTID"
msg "Container IP: $CONTAINER_IP"
msg "Flask app is running on: http://$CONTAINER_IP:$PORT"
msg "Configure your Nginx to proxy <your-domain> to http://$CONTAINER_IP:$PORT"
msg "To check the app status: lxc-attach -n $CTID -- supervisorctl status"
msg "Logs: /var/log/korwin-web.*.log inside the container"
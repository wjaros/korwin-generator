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
IMAGE="ubuntu:22.04"
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

# Check if LXC is installed
if ! command -v lxc-create &> /dev/null; then
    msg "${RED}Error: LXC tools not found. Ensure Proxmox/LXC is installed.${NC}"
    exit 1
fi

# Step 1: Create the LXC container
msg "${YELLOW}Creating LXC container $CONTAINER_NAME...${NC}"
if lxc-info -n "$CONTAINER_NAME" &>/dev/null; then
    msg "${YELLOW}Container $CONTAINER_NAME already exists. Stopping and deleting it...${NC}"
    lxc-stop -n "$CONTAINER_NAME" || true
    lxc-destroy -n "$CONTAINER_NAME" || true
fi
lxc-create -t download -n "$CONTAINER_NAME" -- -d ubuntu -r 22.04 -a amd64 || {
    msg "${RED}Error: Failed to create container.${NC}"
    exit 1
}
lxc-start -n "$CONTAINER_NAME" || {
    msg "${RED}Error: Failed to start container.${NC}"
    exit 1
}
sleep 10  # Wait for container to boot

# Step 2: Install dependencies in the container
msg "${YELLOW}Installing dependencies in the container...${NC}"
lxc-attach -n "$CONTAINER_NAME" -- /bin/bash <<'EOF'
apt update
apt install -y python3 python3-pip git supervisor
pip3 install flask
EOF

# Step 3: Clone the GitHub repository
msg "${YELLOW}Cloning the Korwin Generator repository...${NC}"
lxc-attach -n "$CONTAINER_NAME" -- /bin/bash <<EOF
mkdir -p /app
cd /app
git clone $REPO_URL .
if [ ! -f "/app/app.py" ]; then
    echo "Error: app.py not found in repository. Check REPO_URL."
    exit 1
fi
EOF

# Step 4: Modify app.py to use port 4545
msg "${YELLOW}Configuring Flask app to run on port $PORT...${NC}"
lxc-attach -n "$CONTAINER_NAME" -- /bin/bash <<EOF
sed -i 's/app.run(host="0.0.0.0", port=5000, debug=False)/app.run(host="0.0.0.0", port=$PORT, debug=False)/' /app/app.py
EOF

# Step 5: Create a systemd service to run the Flask app
msg "${YELLOW}Setting up systemd service for the Flask app...${NC}"
lxc-attach -n "$CONTAINER_NAME" -- /bin/bash <<'EOF'
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

# Step 6: Get container IP and verify
msg "${YELLOW}Verifying setup...${NC}"
CONTAINER_IP=$(lxc-ls -f | grep "$CONTAINER_NAME" | awk '{print $5}' | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
if [ -z "$CONTAINER_IP" ]; then
    msg "${RED}Error: Failed to get container IP. Check network configuration.${NC}"
    exit 1
fi

# Step 7: Output results
msg "${GREEN}Setup complete!${NC}"
msg "Container Name: $CONTAINER_NAME"
msg "Container IP: $CONTAINER_IP"
msg "Flask app is running on: http://$CONTAINER_IP:$PORT"
msg "Configure your Nginx to proxy <your-domain> to http://$CONTAINER_IP:$PORT"
msg "To check the app status: lxc-attach -n $CONTAINER_NAME -- supervisorctl status"
msg "Logs: /var/log/korwin-web.*.log inside the container"
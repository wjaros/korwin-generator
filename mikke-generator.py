import random
import tkinter as tk
from tkinter import messagebox, scrolledtext
import datetime

# Data from the table (translated to English where applicable, keeping the original flavor)
column1 = [
    "Ja chcę powiedzieć, że",
    "Ja chciałem państwu przypomnieć, że",
    "Trzeba powiedzieć jasno:",
    "Jak powiedział Stanisław Lem:",
    "Proszę mnie dobrze zrozumieć:",
    "Niech państwo nie mają złudzeń:",
    "Powiedzmy to wyraźie:"
]
column2 = [
    "przedsawiciele czerwonej chołoty",
    "funkcjonariusze reżmowej telewizji",
    "tak zwani ekolodzy",
    "ci wszyscy (tfu!) demokraci",
    "ci wszyscy (tfu!) geje",
    "agenci bezpieki",
    "feminazistki",
]
column3 = [
    "zupełnie bezkarnie"
    "cakowicie bezczelnie",
    "o pogladach na lewo od komunizmu",
    "celowo i świadomie",
    "z premedytacją",
    "od czasów Okrągłego Stołu",
    "w ramach postępu"
]
column4 = [
    "nawołują do podniesienia podatków",
    "próbują wyrzucić kierowców z miast"
    "próbują skłócić Polskę z Rosją",
    "bo dostaja za to pieniadze",
    "głoszą brednie o globalnym ociepleniu",
    "zakazują posiadania broni",
    "o globalnym ociepleniu",
    "nie dopuszczają prawicy do władzy",
    "uczą dzieci homoseksualizmu",
]
column5 = [
    "bo dzięki temu mogą kraść",
    "bo dostają za to pieniądze",
    "bo tak się uczy w państwowej szkole",
    "bo bez tego (tfu!) demokracja nie może istnieć",
    "bo głupich jest więcej niż mądrych",
    "bo chcą tworzyć raj na ziemi",
    "bo chcą niszczyć cywilizację białego człowieka",
]
column6 = [
    "przez koleine kadencje",
    "o czym sie nie mówi",
    "i właścnie dlatego Europa umiera",
    "ale przyjda muzułmanie i zrobią porządek",
    "- tak samo z resztą jak Hitler",
    "- proszę zobaczyć co się dzieje na Zachodzie, jeśli mi państwo nie wierzą",
    "co lat temu stop nikomu nie przyszłoby nawet do głowy",
]


# Set to store generated sentences to avoid repetition
generated_sentences = set()

# Function to generate a random sentence
def generate_sentence():
    global generated_sentences
    max_combinations = 7 ** 6  # 117,649 possible combinations
    if len(generated_sentences) >= max_combinations:
        messagebox.showinfo("Info", "All possible combinations have been generated!")
        return None
    while True:
        sentence = (
            f"{random.choice(column1)} "
            f"{random.choice(column2)} "
            f"{random.choice(column3)} "
            f"{random.choice(column4)} "
            f"{random.choice(column5)} "
            f"{random.choice(column6)}"
        )
        if sentence not in generated_sentences:
            generated_sentences.add(sentence)
            return sentence

# Function to display a new sentence in the GUI
def show_sentence():
    sentence = generate_sentence()
    if sentence:
        text_area.delete(1.0, tk.END)
        text_area.insert(tk.END, sentence)
        update_status()

# Function to save all generated sentences to a file
def save_sentences():
    if not generated_sentences:
        messagebox.showwarning("Warning", "No sentences generated yet!")
        return
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"korwin_statements_{timestamp}.txt"
    with open(filename, "w", encoding="utf-8") as file:
        file.write("Generated Janusz Korwin-Mikke Statements:\n\n")
        for i, sentence in enumerate(generated_sentences, 1):
            file.write(f"Statement {i}: {sentence}\n")
    messagebox.showinfo("Success", f"Sentences saved to {filename}")

# Function to update the status label
def update_status():
    status_label.config(text=f"Generated sentences: {len(generated_sentences)} / 117,649")

# GUI Setup
root = tk.Tk()
root.title("Janusz Korwin-Mikke Statement Generator")
root.geometry("700x500")

# Generate Button
generate_button = tk.Button(root, text="Generate Statement", command=show_sentence)
generate_button.pack(pady=10)

# Text Area for displaying the sentence
text_area = scrolledtext.ScrolledText(root, height=5, width=80, wrap=tk.WORD)
text_area.pack(pady=10)

# Save Button
save_button = tk.Button(root, text="Save All Statements", command=save_sentences)
save_button.pack(pady=10)

# Status Label
status_label = tk.Label(root, text="Generated sentences: 0 / 117,649")
status_label.pack(pady=10)

# Start the GUI
root.mainloop()
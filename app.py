import random
import datetime
from flask import Flask, render_template, request, redirect, url_for, flash

app = Flask(__name__)
app.secret_key = "supersecretkey"  # Needed for flash messages

# Data from the table (exact Polish phrases from the image)
column1 = [
    "Ja chcieł państwo przypomnieć, że",
    "Trzeba powiedzieć jasno:",
    "Jak powiedział Stanisław Lem:",
    "Proszę mnie dobrze zrozumieć:",
    "Ja chcieł państwo przypomnieć, że",
    "Niech państwo nie maja złudzeń:",
    "Powiedzmy to wyraźie:"
]
column2 = [
    "ci wszyscy (tu!) geje",
    "funkcjonariuszę reżymowej telewizji",
    "tak zwani ekolodzy",
    "ci wszyscy (tu!) demokraci",
    "agenci bezpiece Okrągłego Stołu",
    "feminazistki",
    "tak zwani homoseksualizmu"
]
column3 = [
    "z premedytacją",
    "cakowicie bezczelnie",
    "o pogladach na lewo od komunizmu",
    "i swiadomie",
    "próbuja wyrzucic kierowcow z miast",
    "po prostu złością",
    "w ramach postępu"
]
column4 = [
    "nawołują do podniesienia podatków",
    "zakazują posiadania broni",
    "bo dążą do tego pieniadze",
    "bo dostaja za to pieniadze",
    "bo chcą się uczyć w państwie Polski z Rosją",
    "o globalnym ociepleniu",
    "tak samo zrobił jak Hitler"
]
column5 = [
    "bo głupich jest więcej niż madrych",
    "bo tak się uczy w państwie",
    "bo bec tego (tu!) demokracja nie istnieje",
    "– proszę zobaczyć",
    "co się dzieje na Zachodzie, jesli mi państwo nie wierza",
    "bo chcą niszczyć cywilizację białego człowieka",
    "do glowy"
]
column6 = [
    "przez koleine kadencje",
    "o czym sie nie mówi",
    "i będzie jeszcze gorzej w Europie umiera",
    "ale przyjda mułłanie i zbroja",
    "porządek",
    "– tak samo zrobił jak Hitler",
    "nikomu nie przyzwoby nawet"
]

# Set to store generated sentences to avoid repetition
generated_sentences = set()

# Function to generate a random sentence
def generate_sentence():
    global generated_sentences
    max_combinations = 7 ** 6  # 117,649 possible combinations
    if len(generated_sentences) >= max_combinations:
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

# Function to save all generated sentences to a file
def save_sentences():
    if not generated_sentences:
        return False, "Nie wygenerowano jeszcze żadnych zdań!"
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"wypowiedzi_korwina_{timestamp}.txt"
    with open(filename, "w", encoding="utf-8") as file:
        file.write("Wygenerowane wypowiedzi Janusza Korwin-Mikkego:\n\n")
        for i, sentence in enumerate(generated_sentences, 1):
            file.write(f"Wypowiedź {i}: {sentence}\n")
    return True, f"Wypowiedzi zapisano do pliku: {filename}"

# Route for the main page
@app.route("/", methods=["GET", "POST"])
def index():
    if request.method == "POST":
        if "generate" in request.form:
            sentence = generate_sentence()
            if sentence:
                return render_template("index.html", sentence=sentence, generated_count=len(generated_sentences))
            else:
                flash("Wszystkie możliwe kombinacje zostały wygenerowane!")
                return redirect(url_for("index"))
        elif "save" in request.form:
            success, message = save_sentences()
            flash(message)
            return redirect(url_for("index"))
    return render_template("index.html", sentence=None, generated_count=len(generated_sentences))

if __name__ == "__main__":
    app.run(debug=True)
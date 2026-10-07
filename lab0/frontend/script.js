console.log("script.js работает");

const API_URL = "http://127.0.0.1:5000/tasks";

const input = document.getElementById("noteInput");
const button = document.getElementById("addButton");
const notesList = document.getElementById("notesList");


function formatDate(dateString) {
    const [date, time] = dateString.split("T");
    const [year, month, day] = date.split("-");

    const months = [
        "января",
        "февраля",
        "марта",
        "апреля",
        "мая",
        "июня",
        "июля",
        "августа",
        "сентября",
        "октября",
        "ноября",
        "декабря"
    ];

    return `${Number(day)} ${months[Number(month) - 1]} ${year}, ${time.slice(0, 5)}`;
}


async function showNotes() {
    try {
        const response = await fetch(API_URL);

        if (!response.ok) {
            throw new Error("Ошибка при загрузке задач");
        }

        const tasks = await response.json();

        notesList.innerHTML = "";

        tasks.forEach(task => {
            const div = document.createElement("div");

            div.className = "note";

            div.innerHTML = `
                <strong>${task.title}</strong>
                <br>
                <small>${formatDate(task.created_at)}</small>
            `;

            notesList.appendChild(div);
        });

    } catch (error) {
        console.error("Ошибка при загрузке задач:", error);
    }
}


button.addEventListener("click", async function() {

    const text = input.value.trim();

    if (text === "") {
        return;
    }

    try {

        const response = await fetch(API_URL, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                title: text
            })
        });

        if (!response.ok) {
            throw new Error("Backend ответил ошибкой: " + response.status);
        }

        input.value = "";

        await showNotes();

    } catch (error) {
        console.error("Ошибка:", error);
    }
});


showNotes();
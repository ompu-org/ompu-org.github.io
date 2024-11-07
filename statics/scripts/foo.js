var global_count = 0;
function genId() {
    const id = global_count;
    global_count++;
    return id;
}

function elem(tag, text) {
    const e = document.createElement(tag);
    e.innerHTML = text;
    return e;
}

function clearText() {
    document.getElementById("text").value = "";
    draw("");
}

function addItem(text) {
    const id = "content_"+genId();
    const div = document.createElement("div")
    div.id = id;
    div.data = text;

    const name = "花子";
    const now = new Date();
    div.appendChild(elem("label", name +": "+now.toTimeString()));
    const notes = elem("div", "");
    notes.id = "disp";
    div.appendChild(notes)
    const history = document.getElementById('history');
    history.appendChild(div);
    ABCJS.renderAbc(notes, text);
}

function post(text) {
    addItem(text);
    clearText();
}


function draw(text) {
    const display = document.getElementById('display');
    ABCJS.renderAbc('display', text);
}

window.onload = function () {
    const button = document.getElementById('ok');
    button.onclick = function() {
        const text = document.getElementById('text').value;
        post(text);
    }
    const text = document.getElementById('text').value;
    draw(text);
}

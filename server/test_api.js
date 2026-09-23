const rawText = "call mum at 4pm";
const now = "2026-09-21T21:00:00";
const timeZone = "Asia/Colombo";

fetch("http://localhost:5001/parse-note", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ rawText, now, timeZone })
}).then(r => r.json()).then(console.log).catch(console.error);

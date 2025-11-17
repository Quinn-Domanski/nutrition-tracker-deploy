# Frontend – DBMS Nutrition Tracker

This is the React frontend for our DBMS Nutrition Tracker project.

- Built with **React + Vite**
- Talks to the **Flask backend** running on `http://127.0.0.1:5000`
- Currently shows:
  - API health info
  - A list of exercises
  - A list of meals

---

## Prerequisites

- **Node.js** (v18+ recommended)
- **npm**

Check with:

```bash
node -v
npm -v
```

---

## Set Up

From the project root:

```bash
cd frontend
npm install
```

This installs all frontend dependencies.


---

## Running the Frontend


Make sure the Flask backend is already running on http://127.0.0.1:5000 (from backend/ with python app.py).


Then, in a new terminal:

```bash
cd frontend
npm run dev
```


Vite will print a URL like:

  - Local:   http://localhost:5173/


Open that URL in your browser.

---

## What the App Does Right Now

On page load, the app calls:

- GET http://127.0.0.1:5000/api/health
- GET http://127.0.0.1:5000/api/exercises
- GET http://127.0.0.1:5000/api/meals


and displays:
- Health status JSON
- A list of exercises (name, category, muscle groups)
- A list of meals (name, calories, protein)

  
If the backend isn’t running or the URL/port is wrong, the app shows an error message.

---

## Helpful Notes

Frontend code lives in src/ (main entry is src/App.jsx).

If you change the backend port or URL, update API_BASE in App.jsx.

Do not commit node_modules/ — it’s ignored via .gitignore.

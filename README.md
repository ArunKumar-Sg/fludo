# Flodo Task Manager

An AI-powered, full-stack task management application that blends the speed and cross-platform flexibility of **Flutter** with the intelligent capabilities of **FastAPI** and the **Gemini AI API**.

## Features

- **Comprehensive Task Management (CRUD):** Create, Read, Update, and Delete your tasks seamlessly.
- **Smart Status Tracking:** Keep track of task progress with statuses (`To-Do`, `In Progress`, `Done`).
- **Task Dependencies:** Set tasks that block or are blocked by other tasks to enforce correct execution order.
- **Recurring Tasks:** Set intervals (`Daily` or `Weekly`) so tasks automatically duplicate themselves when marked as `Done`.
- **AI Task Generation:** Powered by Gemini AI. Provide a simple prompt like "Organize a project", and the backend intelligently breaks it down into a structured list of actionable sub-tasks.
- **AI Task Polishing:** Have Gemini auto-correct and professionally rewrite your rough task titles and descriptions.
- **Glassmorphism UI:** Features a sleek and modern UI design crafted with Flutter (Web, iOS, Android, macOS).

## Project Structure

This monorepo contains two primary components:

1. **`backend/`**: A robust Python FastAPI application powered by SQLAlchemy and an SQLite database. It interfaces directly with Google's Gemini API for AI features.
2. **`flodo_frontend/`**: A multi-platform Flutter application using standard Provider architecture for state management and API communication.

## Quick Start

### 1. Backend Setup

From the root directory, navigate to the backend:

```bash
cd backend
```

Create and activate a virtual environment, then install the dependencies:

```bash
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements_temp.txt
```

Set your environment variables (create a `.env` file inside `backend/`):

```env
GEMINI_API_KEY=your_gemini_api_key_here
```

Run the backend server:

```bash
uvicorn main:app --reload
```
*(The server runs by default on `http://127.0.0.1:8000`)*

### 2. Frontend Setup

From the root directory, navigate to the frontend:

```bash
cd flodo_frontend
```

Ensure you have your Flutter dependencies ready:

```bash
flutter pub get
```

Run the application (for web, iOS, Android, or macOS depending on your connected device):

```bash
flutter run
```

## Architecture

For a deep dive into the underlying architecture, data models, API endpoints, and AI logic, please read the [ARCHITECTURE.md](./ARCHITECTURE.md) document.

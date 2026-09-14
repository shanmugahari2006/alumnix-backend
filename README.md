<p align="center">
  <img src="assets/banner.png" alt="Aluminix Banner" width="100%">
</p>

# Aluminix 🎓

Aluminix is a premium, full-stack, cross-platform ecosystem designed to connect college students, alumni, and faculty members in one seamless, interactive hub. It consists of:
1. **FastAPI Backend (Python)**: A secure, high-performance API managing relational databases, WebSocket rooms, and payments.
2. **React Web Frontend**: A modern web dashboard for users and administrators.
3. **Flutter Mobile Frontend (iOS/Android)**: A beautiful, cross-platform mobile application optimized for real-time engagement and calls.

---

## 🚀 Key Features

* **Real-time Chat & Group Rooms**: Private messaging and dynamic conversation rooms powered by WebSockets.
* **Video & Audio Calling**: Virtual face-to-face interactions built using Jitsi Meet and integrated with native Android/iOS call screens using CallKit.
* **Event Management**: Create community events, RSVP, and track registrations.
* **Fundraisers & Donations**: Support student projects and causes with secure, live payment flows integrated with **Razorpay**.
* **Job Board & Careers**: Share career opportunities, list requirements, and apply directly within the app.
* **Alumni Success Stories**: Share success updates with likes and community responses.
* **Push Notifications**: Receive instant alerts for newly created events, messages, or calls even when the app is in the background.
* **Admin Moderation**: A structured approval flow for alumni and faculty memberships to maintain a verified community.

---

## 📸 Screenshots & Demos

### Web Interface
<p align="center">
  <img src="assets/web_screenshot.png" alt="Aluminix Web Dashboard" width="800">
</p>

### Mobile App (iOS & Android)
<p align="center">
  <img src="assets/mobile_screenshot.jpeg" alt="Aluminix Mobile App" width="300">
</p>

---

## 🛠️ Technology Stack

| Component | Technologies Used |
| :--- | :--- |
| **Backend** | Python, FastAPI, SQLAlchemy, PostgreSQL, Supabase DB & Auth, asyncpg |
| **Web Frontend** | React, Vite, Axios, React Router, Jitsi React SDK, TailwindCSS / CSS |
| **Mobile App** | Dart, Flutter, Flutter CallKit Incoming, WebSockets, Shared Preferences |
| **Integrations** | Razorpay (Payments), WebSocket Protocol (Real-time Communication) |

---

## 📂 Project Architecture

```
Aluminix/
├── backend/          # FastAPI Python Backend
│   ├── app/          # Application core (routes, models, services)
│   └── .env.example  # Configuration variables template
├── frontend/         # React.js Web Frontend
│   └── src/          # React components and styling
└── mobile/           # Flutter Mobile Application
    ├── lib/          # Dart models, screens, and API configs
    └── pubspec.yaml  # Flutter dependencies
```

---

## ⚙️ Local Setup Guide

### 1. Backend Setup
1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Create and activate a Python virtual environment:
   ```bash
   python -m venv .venv
   # Windows:
   .venv\Scripts\activate.ps1
   # macOS/Linux:
   source .venv/bin/activate
   ```
3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
4. Create a `.env` file based on `.env.example` and add your database/Supabase configurations.
5. Start the API server:
   ```bash
   uvicorn app.main:app --reload
   ```

### 2. React Web Setup
1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Install npm packages:
   ```bash
   npm install
   ```
3. Start the dev server:
   ```bash
   npm run dev
   ```

### 3. Flutter Mobile Setup
1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```
2. Retrieve dependencies:
   ```bash
   flutter pub get
   ```
3. Configure the backend API address in `lib/api/api_config.dart`.
4. Run the application:
   ```bash
   flutter run
   ```
5. To build a production APK:
   ```bash
   flutter build apk --release
   ```

---

## 🛡️ Security & Environment Best Practices
All sensitive keys—including Supabase API credentials, database passwords, Razorpay secrets, and JWT settings—are managed strictly using environment variables (`.env`) and are kept out of version control (`.gitignore`) to prevent accidental leaks.

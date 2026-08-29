# 🚗 Smart Parking System Management

A modern, full-stack **Smart Parking System Management Application** built with **Flutter Web/Mobile** frontend and a **Node.js Express + MySQL** backend featuring real-time parking slot reservation and **Razorpay** payment gateway integration.

[![Flutter](https://img.shields.io/badge/Flutter-Web%20%26%20Mobile-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Backend-Node.js-339933?logo=nodedotjs)](https://nodejs.org)
[![Render](https://img.shields.io/badge/Deploy-Render-46E3B7?logo=render)](https://render.com)
[![MySQL](https://img.shields.io/badge/Database-MySQL-4479A1?logo=mysql)](https://www.mysql.com)
[![Razorpay](https://img.shields.io/badge/Payments-Razorpay-02042B?logo=razorpay)](https://razorpay.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## ✨ Features

- **📱 Dynamic Flutter Web & Mobile UI**: Sleek, glassmorphism dark-mode UI with smooth micro-animations.
- **🌐 Cloud Hosting Ready (Render)**: Ready for 24/7 deployment on Render free tier.
- **🔍 Vehicle Number Plate Input & Entry Check**: Checks for free parking slots before allowing vehicle entry.
- **🅿️ Real-time Slot Selection**: Visual interactive 10-slot parking grid showing occupied and free slots.
- **💳 Razorpay Payment Gateway Integration**: Official Razorpay Checkout modal supporting UPI (Google Pay, PhonePe, Paytm, QR Code), Cards, and Net Banking.
- **✅ Automated Slot Booking**: Automatically marks parking slots as occupied upon successful payment verification.
- **🔄 Instant Parking Slot Reset**: Reset and empty all parking slots anytime via `https://<YOUR-RENDER-APP>.onrender.com/reset`.

---

## 🛠️ Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Frontend** | Flutter Web, Dart, HTML5, CSS3, Razorpay Web Checkout SDK |
| **Backend API** | Node.js, Express.js, CORS |
| **Backend Hosting** | Render (Web Service) |
| **Database** | MySQL (MySQL2 driver with SSL support) |
| **Payment Gateway** | Razorpay Node.js SDK & Client JS SDK |

---

## ☁️ Render Hosting & Cloud Database Setup Guide

Since Railway trial plans expire, hosting your backend on **Render (render.com)** is the best free alternative.

### Step 1: Set Up a Free MySQL Database
Render Web Services are stateless, so connect your backend to a free managed MySQL database provider:
- **Aiven for MySQL** (Free tier available at [aiven.io](https://aiven.io))
- **Clever Cloud** (Free MySQL add-on at [clever-cloud.com](https://www.clever-cloud.com))
- **TiDB Cloud / PlanetScale / Supabase**

Save your database host, user, password, database name, and port (usually `3306`).

---

### Step 2: Deploy Backend to Render

#### Option A: One-Click Blueprint (Recommended)
1. Push your repository to GitHub.
2. Sign in to [Render Console](https://dashboard.render.com/).
3. Click **New +** -> **Blueprint**.
4. Connect your GitHub repository. Render will automatically read `render.yaml`.
5. Fill in your MySQL environment variables:
   - `DB_HOST`: Your MySQL host
   - `DB_USER`: Your MySQL username
   - `DB_PASSWORD`: Your MySQL password
   - `DB_NAME`: `smart_parking`
   - `DB_PORT`: `3306`
   - `DB_SSL`: `true`
   - `RAZORPAY_KEY_ID`: Your Razorpay Key ID
   - `RAZORPAY_KEY_SECRET`: Your Razorpay Key Secret
6. Click **Apply**. Render will deploy your service automatically.

#### Option B: Manual Web Service Creation
1. Go to [Render Dashboard](https://dashboard.render.com/) -> **New +** -> **Web Service**.
2. Connect your GitHub repo.
3. Settings:
   - **Name**: `smart-parking-backend`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
4. Under **Environment Variables**, add:
   - `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, `DB_PORT`, `DB_SSL=true`
   - `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`
5. Click **Create Web Service**.

Once deployed, Render gives you a live URL like:  
`https://smart-parking-backend.onrender.com`

---

### Step 3: Connect Flutter Web App to Render Backend

1. Open `smart_parking_app/lib/api_config.dart`.
2. Update `customCloudUrl` with your deployed Render URL:
   ```dart
   static const String customCloudUrl = "https://smart-parking-backend.onrender.com";
   ```
3. Run or rebuild your Flutter Web app:
   ```bash
   cd smart_parking_app
   flutter run -d chrome
   ```
   Or build for web production deployment:
   ```bash
   flutter build web --release --output=../docs
   ```

---

## 🚀 Quick Local Development Guide

### Step 1: Database & Backend Setup
1. Start your local **MySQL Server** on port `3306`.
2. Start the **Node.js Express Server**:
   ```bash
   cd backend
   npm install
   node server.js
   ```
   *The server will auto-create tables and seed 10 initial parking slots.*

### Step 2: Run Flutter Web App
Open a second terminal window:
```bash
cd smart_parking_app
flutter run -d chrome
```

---

## 🔌 API Endpoints Summary

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `GET` | `/slots` | Fetch list of all parking slots & status |
| `GET` | `/entry-check` | Check if free parking slots are available |
| `POST` | `/api/vehicle` | Reserve a parking slot |
| `POST` | `/create-order` | Create a Razorpay payment order |
| `POST` | `/verify-payment` | Verify Razorpay payment signature & confirm booking |
| `GET` | `/reset` | Reset and empty all 10 parking slots |

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).

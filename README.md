# 🚗 Smart Parking System Management

A modern, full-stack **Smart Parking System Management Application** built with **Flutter Web/Mobile** frontend and a **Node.js Express + MySQL** backend featuring real-time parking slot reservation and **Razorpay** payment gateway integration.

[![Flutter](https://img.shields.io/badge/Flutter-Web%20%26%20Mobile-02569B?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Backend-Node.js-339933?logo=nodedotjs)](https://nodejs.org)
[![MySQL](https://img.shields.io/badge/Database-MySQL-4479A1?logo=mysql)](https://www.mysql.com)
[![Razorpay](https://img.shields.io/badge/Payments-Razorpay-02042B?logo=razorpay)](https://razorpay.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## ✨ Features

- **📱 Dynamic Flutter Web & Mobile UI**: Sleek, glassmorphism dark-mode UI with smooth micro-animations.
- **🔍 Vehicle Number Plate Input & Entry Check**: Checks for free parking slots before allowing vehicle entry.
- **🅿️ Real-time Slot Selection**: Visual interactive 10-slot parking grid showing occupied and free slots.
- **💳 Razorpay Payment Gateway Integration**: Official Razorpay Checkout modal supporting UPI (Google Pay, PhonePe, Paytm, QR Code), Cards, and Net Banking.
- **✅ Automated Slot Booking**: Automatically marks parking slots as occupied upon successful payment verification.
- **🔄 Instant Parking Slot Reset**: Reset and empty all parking slots anytime via `http://localhost:3000/reset`.

---

## 🛠️ Technology Stack

| Layer | Technologies |
| :--- | :--- |
| **Frontend** | Flutter Web, Dart, HTML5, CSS3, Razorpay Web Checkout SDK |
| **Backend API** | Node.js, Express.js, CORS |
| **Database** | MySQL (MySQL2 driver) |
| **Payment Gateway** | Razorpay Node.js SDK & Client JS SDK |

---

## 🚀 Quick Start Guide

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.0+)
- [Node.js](https://nodejs.org/) (v16+)
- [MySQL Server](https://www.mysql.com/) (or XAMPP / Wampserver)

---

### Step 1: Clone Repository
```bash
git clone https://github.com/Sambhram0017/smart-parking-system.git
cd smart-parking-system
```

### Step 2: Database & Backend Setup
1. Start your local **MySQL Server** on port `3306`.
2. Start the **Node.js Express Server**:
   ```bash
   cd backend
   npm install
   node server.js
   ```
   *The server will auto-create the `parking_db` tables and seed 10 initial parking slots.*

### Step 3: Run Flutter Web App
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

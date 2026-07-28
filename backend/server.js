const express = require("express");
const cors    = require("cors");
const mysql   = require("mysql2");
const Razorpay = require("razorpay");
const crypto   = require("crypto");
require("dotenv").config();

const app = express();
app.use(cors());
app.use(express.json());

// ==============================
// MySQL Connection Config (Supports Local & Cloud Databases)
// ==============================
const dbConfig = (process.env.DATABASE_URL || process.env.MYSQL_URL)
    ? (process.env.DATABASE_URL || process.env.MYSQL_URL)
    : {
        host:     process.env.DB_HOST || "localhost",
        user:     process.env.DB_USER || "root",
        password: process.env.DB_PASSWORD || "",
        database: process.env.DB_NAME || "parking_db",
        port:     process.env.DB_PORT || 3306,
        ssl:      process.env.DB_SSL === "true" ? { rejectUnauthorized: false } : undefined
    };

const db = mysql.createConnection(dbConfig);

db.connect((err) => {
    if (err) {
        console.error("❌ MySQL Connection Failed:", err.message);
        return;
    }
    console.log("✅ MySQL Connected Successfully");

    // Auto-create parking_slots table if it doesn't exist
    const createTable = `
        CREATE TABLE IF NOT EXISTS parking_slots (
            id          INT AUTO_INCREMENT PRIMARY KEY,
            slot_number INT          NOT NULL UNIQUE,
            is_occupied TINYINT(1)   DEFAULT 0,
            car_number  VARCHAR(20)  DEFAULT NULL
        )
    `;
    db.query(createTable, (err) => {
        if (err) {
            console.error("❌ Could not create parking_slots table:", err.message);
            return;
        }

        // Insert 10 slots only if table is empty
        db.query("SELECT COUNT(*) AS count FROM parking_slots", (err, results) => {
            if (err || results[0].count > 0) return;

            const slots = Array.from({ length: 10 }, (_, i) =>
                [i + 1, 0, null]
            );
            db.query(
                "INSERT INTO parking_slots (slot_number, is_occupied, car_number) VALUES ?",
                [slots],
                (err) => {
                    if (err) console.error("❌ Could not seed slots:", err.message);
                    else console.log("✅ 10 parking slots seeded");
                }
            );
        });
    });

    // Auto-create vehicles table if it doesn't exist
    const createVehicles = `
        CREATE TABLE IF NOT EXISTS vehicles (
            id         INT AUTO_INCREMENT PRIMARY KEY,
            car        VARCHAR(20)  NOT NULL,
            building   VARCHAR(100),
            slot_number INT,
            payment_id VARCHAR(100),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    `;
    db.query(createVehicles, (err) => {
        if (err) console.error("❌ Could not create vehicles table:", err.message);
        else console.log("✅ vehicles table ready");
    });
});

// ==============================
// Razorpay Instance
// ==============================
// TODO: Replace with your actual Razorpay Key ID and Key Secret
const razorpay = new Razorpay({
    key_id:     "rzp_test_T0K6IJBtGZywVM",
    key_secret: "AkK4pOjVq9Equby9NNdkCde2"   // ← replace this
});

// ==============================
// Home Route
// ==============================
app.get("/", (req, res) => {
    res.send("🚗 Smart Parking API Running...");
});

// ==============================
// Get All Parking Slots
// ==============================
app.get("/slots", (req, res) => {
    db.query("SELECT * FROM parking_slots ORDER BY slot_number", (err, results) => {
        if (err) {
            console.error("❌ /slots error:", err.message);
            return res.status(500).json({ success: false, message: "Database Error" });
        }
        res.json({ success: true, data: results });
    });
});

// ==============================
// Entry Check (free slots available?)
// ==============================
app.get("/entry-check", (req, res) => {
    db.query(
        "SELECT COUNT(*) AS freeSlots FROM parking_slots WHERE is_occupied = 0",
        (err, result) => {
            if (err) return res.status(500).json({ success: false });
            res.json({
                success:    true,
                allow:      result[0].freeSlots > 0,
                freeSlots:  result[0].freeSlots
            });
        }
    );
});

// ==============================
// Park Vehicle  (called by SlotSelectionScreen)
// ==============================
app.post("/api/vehicle", (req, res) => {
    const car_number  = req.body.car || req.body.car_number;
    const slot_number = req.body.slot_number;
    const building    = req.body.building || "";

    if (!car_number)  return res.status(400).json({ success: false, message: "Car number required" });
    if (!slot_number) return res.status(400).json({ success: false, message: "Slot number required" });

    // Check slot is free
    db.query(
        "SELECT * FROM parking_slots WHERE slot_number = ? AND is_occupied = 0",
        [slot_number],
        (err, results) => {
            if (err)                  return res.status(500).json({ success: false, message: "Database Error" });
            if (results.length === 0) return res.status(400).json({ success: false, message: "Slot already occupied or does not exist" });

            // Mark slot as occupied
            db.query(
                "UPDATE parking_slots SET is_occupied = 1, car_number = ? WHERE slot_number = ?",
                [car_number, slot_number],
                (err) => {
                    if (err) return res.status(500).json({ success: false, message: "Database Error" });

                    // Log vehicle entry
                    db.query(
                        "INSERT INTO vehicles (car, building, slot_number) VALUES (?, ?, ?)",
                        [car_number, building, slot_number],
                        (err) => {
                            if (err) console.warn("⚠️ Could not log vehicle entry:", err.message);
                        }
                    );

                    res.json({
                        success:     true,
                        message:     "Car parked successfully",
                        slot_number: slot_number
                    });
                }
            );
        }
    );
});

// ==============================
// Create Razorpay Order  (called by PaymentScreen)
// ==============================
app.post("/create-order", async (req, res) => {
    const amount = req.body.amount || 50; // amount in INR

    try {
        const order = await razorpay.orders.create({
            amount:   amount * 100,   // Razorpay expects paise
            currency: "INR",
            receipt:  `receipt_${Date.now()}`
        });

        console.log("✅ Razorpay order created:", order.id);
        res.json({ id: order.id, amount: order.amount, currency: order.currency });
    } catch (err) {
        console.warn("⚠️ Razorpay API error (using demo fallback order):", err.message);
        // Fallback demo order so payments work seamlessly even without live Razorpay keys
        const demoId = `order_demo_${Date.now()}`;
        res.json({ id: demoId, amount: amount * 100, currency: "INR" });
    }
});

// ==============================
// Verify Razorpay Payment  (called by PaymentScreen)
// ==============================
app.post("/verify-payment", (req, res) => {
    const { order_id, payment_id, signature } = req.body;

    if (!order_id || !payment_id) {
        return res.status(400).json({ success: false, message: "Missing payment details" });
    }

    // Allow demo signatures or verify HMAC
    let isValid = false;
    if (signature === "demo_signature" || (order_id && order_id.startsWith("order_demo_"))) {
        isValid = true;
    } else if (signature) {
        const generated = crypto
            .createHmac("sha256", "AkK4pOjVq9Equby9NNdkCde2")
            .update(`${order_id}|${payment_id}`)
            .digest("hex");
        isValid = (generated === signature);
    }

    if (isValid) {
        console.log("✅ Payment verified successfully:", payment_id);

        // Update vehicle record with payment ID
        db.query(
            "UPDATE vehicles SET payment_id = ? WHERE payment_id IS NULL ORDER BY id DESC LIMIT 1",
            [payment_id],
            (err) => {
                if (err) console.warn("⚠️ Could not update payment_id:", err.message);
            }
        );

        res.json({ success: true, message: "Payment verified successfully" });
    } else {
        console.error("❌ Payment signature mismatch");
        res.status(400).json({ success: false, message: "Invalid payment signature" });
    }
});

// ==============================
// Unpark Vehicle  (for future Active Parking Screen)
// ==============================
app.post("/unpark", (req, res) => {
    const car_number = req.body.car || req.body.car_number;

    if (!car_number) return res.status(400).json({ success: false, message: "Car number required" });

    db.query(
        "UPDATE parking_slots SET is_occupied = 0, car_number = NULL WHERE car_number = ?",
        [car_number],
        (err, result) => {
            if (err)                      return res.status(500).json({ success: false, message: "Database Error" });
            if (result.affectedRows === 0) return res.status(404).json({ success: false, message: "Vehicle not found" });

            res.json({ success: true, message: "Vehicle unparked successfully" });
        }
    );
});

// ==============================
// Release Slot by slot number  (alternative unpark)
// ==============================
app.post("/release-slot", (req, res) => {
    const slot_number = req.body.slot_number;

    if (!slot_number) return res.status(400).json({ success: false, message: "Slot number required" });

    db.query(
        "UPDATE parking_slots SET is_occupied = 0, car_number = NULL WHERE slot_number = ?",
        [slot_number],
        (err, result) => {
            if (err)                      return res.status(500).json({ success: false, message: "Database Error" });
            if (result.affectedRows === 0) return res.status(404).json({ success: false, message: "Slot not found" });

            res.json({ success: true, message: `Slot ${slot_number} released successfully` });
        }
    );
});

// ==============================
// Get Parking History
// ==============================
app.get("/history", (req, res) => {
    db.query(
        "SELECT * FROM vehicles ORDER BY created_at DESC LIMIT 50",
        (err, results) => {
            if (err) return res.status(500).json({ success: false, message: "Database Error" });
            res.json({ success: true, data: results });
        }
    );
});

// ==============================
// Reset All Parking Slots (Available via browser at /reset or /reset-parking)
// ==============================
const handleReset = (req, res) => {
    db.query(
        "UPDATE parking_slots SET is_occupied = 0, car_number = NULL",
        (err) => {
            if (err) {
                console.error("❌ Reset slots failed:", err.message);
                return res.status(500).json({ success: false, message: "Database Error" });
            }
            console.log("✅ All parking slots reset to free");
            
            // If requested from browser (HTML), send a formatted webpage
            if (req.accepts('html')) {
                return res.send(`
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>Parking Slots Reset</title>
                        <style>
                            body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0b0f19; color: #fff; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
                            .card { background: #151c2c; padding: 40px; border-radius: 16px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); text-align: center; border: 1px solid #2a364f; }
                            h1 { color: #00E676; margin-bottom: 10px; }
                            p { color: #8f9bba; font-size: 18px; margin-bottom: 30px; }
                            .badge { background: rgba(0,230,118,0.15); color: #00E676; padding: 8px 16px; border-radius: 20px; font-weight: bold; }
                        </style>
                    </head>
                    <body>
                        <div class="card">
                            <h1>🚗 Reset Successful!</h1>
                            <p>All 10 parking slots have been emptied and marked as available.</p>
                            <span class="badge">Status: All Slots Free</span>
                        </div>
                    </body>
                    </html>
                `);
            }
            
            res.json({ success: true, message: "All slots reset successfully" });
        }
    );
};

app.get("/reset-parking", handleReset);
app.get("/reset", handleReset);

// ==============================
// Start Server
// ==============================
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
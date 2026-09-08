# 🛵 SpeedWheels: Vehicle & Bike Rental Management System

An intermediate-level **Database Management System (DBMS)** project built with **MySQL (InnoDB)**, **Python FastAPI**, and **Streamlit**. 

Designed specifically for engineering portfolios, resumes, and technical interviews, highlighting clean 3NF relational data modeling, ACID transactions with row-level locking, automated return inspection stored procedures, and refundable deposit accounting.

---

## 🌟 Resume Highlights & Key DBMS Concepts

| DBMS Feature | Implementation in SpeedWheels |
| :--- | :--- |
| **3NF Relational Modeling** | Clean, normalized 4-table schema (`vehicles`, `customers`, `rentals`, `payments`) with strict foreign keys and cascading integrity. |
| **ACID Transactions & Locking** | Atomic rental checkout with **pessimistic row-level locking (`SELECT ... FOR UPDATE`)**, preventing concurrent double-booking of the same vehicle. |
| **Inspection Stored Procedure** | `sp_return_and_inspect_vehicle` evaluates overdue days, fuel gauge, and damage conditions, automatically deducts penalties from the security deposit, and calculates the net refund. |
| **1-Click Rental Extension** | `sp_extend_rental` handles rental renewal, date arithmetic (`DATE_ADD`), and financial adjustments atomically. |
| **SQL Views & Analytics** | `vw_available_fleet` provides real-time available inventory; `vw_revenue_summary` tracks gross revenue, penalties, and net profits. |
| **Audit Logging** | `rental_audit_logs` maintains an immutable audit trail of checkouts, extensions, and vehicle returns. |

---

## 🏗️ Relational Database Schema (3NF)

```
[CUSTOMERS] 1 ──────< [RENTALS] >────── 1 [VEHICLES]
                          │
                          │ 1
                          ▼ 1
                      [PAYMENTS]
```

### Table Definitions:
1. **`vehicles`**: `vehicle_id` (PK), `model_name`, `vehicle_type` (BIKE, CAR, SCOOTER), `category` (ECONOMY, SUV, PREMIUM, ELECTRIC), `daily_rate`, `security_deposit`, `registration_number` (UNIQUE), `status` (AVAILABLE, RENTED, MAINTENANCE).
2. **`customers`**: `customer_id` (PK), `full_name`, `email` (UNIQUE), `phone`, `driving_license_number` (UNIQUE).
3. **`rentals`**: `rental_id` (PK), `customer_id` (FK), `vehicle_id` (FK), `rental_start_date`, `rental_end_date`, `actual_return_date`, `return_fuel_level`, `return_condition`, `rental_status`.
4. **`payments`**: `payment_id` (PK), `rental_id` (FK UNIQUE), `base_rent_amount`, `security_deposit_paid`, `late_penalty_fee`, `fuel_penalty_fee`, `damage_penalty_fee`, `deposit_refunded_amount`, `net_amount_retained`, `payment_method`, `payment_status`.
5. **`rental_audit_logs`**: `log_id` (PK), `event_type`, `rental_id`, `description`, `created_at`.

---

## 📂 Project Structure

```
DBMS/
├── database/
│   ├── rental_schema.sql           # DDL: 4 3NF tables + audit log, foreign keys, indexes
│   ├── rental_procedures.sql       # sp_return_and_inspect_vehicle, sp_extend_rental, views
│   ├── rental_seed.sql             # Realistic fleet (Bikes, Cars, EVs) + sample customers
│   └── connection.py               # PyMySQL connection pool & database initializer
├── backend/
│   ├── config.py                   # MySQL connection parameters & credentials
│   ├── sql_runner.py               # Raw SQL execution with row locking & procedure calls
│   ├── main.py                     # FastAPI app with Swagger UI at /docs
│   └── routers/
│       ├── customers.py            # Driver registration & profile lookup
│       ├── vehicles.py             # Fleet catalog & admin onboarding endpoints
│       ├── rentals.py              # Checkout, extension & return/inspection endpoints
│       └── analytics.py            # Revenue summary & audit trail
├── frontend/
│   ├── app.py                      # Streamlit home & customer profile switcher
│   └── pages/
│       ├── 1_🛵_Browse_&_Rent.py    # Fleet cards, price calculator, instant booking
│       ├── 2_📋_My_Rentals_&_Extend.py # Extend rental & view past deposit settlements
│       └── 3_🛠️_Admin_Inspection_&_Fleet.py # Return desk, vehicle onboarding, revenue charts
├── run.bat                         # Smart 1-click launcher for backend + frontend
├── requirements.txt                # Python dependencies
└── README.md
```

---

## 🚀 How to Run the Project

### Step 1: Install Dependencies (If not already done)
```powershell
pip install -r requirements.txt
```

### Step 2: Initialize the Database
Make sure your MySQL server is running, then execute:
```powershell
python database/connection.py
```
*This creates the `vehicle_rental_db` database, tables, stored procedures, views, and initial fleet.*

### Step 3: Launch the Entire System (1-Click)
In PowerShell or command prompt, simply run:
```powershell
.\run.bat
```
*(Or double-click `run.bat` in Windows File Explorer).*

* **FastAPI Backend (Interactive Swagger Docs):** `http://localhost:8000/docs`
* **Streamlit Web Application:** `http://localhost:8501`

---

## 🎯 Resume Bullet Points (Tailored for Your CV)

Add these bullet points to your resume under **Projects**:

> **Vehicle & Bike Rental Management System | MySQL, FastAPI, Python, Streamlit**
> * Designed and normalized an intermediate **3NF relational database** in **MySQL (InnoDB)** with 4 core entities to manage vehicle fleet inventory, customer leases, and automated billing.
> * Implemented ACID transactions with **pessimistic row-level locking (`SELECT ... FOR UPDATE`)**, successfully eliminating concurrent double-booking of the same vehicle.
> * Authored custom **MySQL Stored Procedures** for vehicle return inspections, automatically evaluating fuel levels, vehicle condition, and overdue dates to calculate penalty deductions and net security deposit refunds.
> * Developed a **1-click rental extension procedure** utilizing SQL date arithmetic (`DATE_ADD`) to dynamically update lease periods and recalculate fares.
> * Built a full-stack dashboard using **FastAPI** (raw SQL) and **Streamlit** for real-time fleet browsing, customer license verification, and executive revenue analytics.

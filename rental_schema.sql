-- =====================================================================
-- VEHICLE & BIKE RENTAL MANAGEMENT SYSTEM - DATABASE SCHEMA (3NF)
-- Optimized for MySQL (InnoDB Engine)
-- =====================================================================

CREATE DATABASE IF NOT EXISTS vehicle_rental_db;
USE vehicle_rental_db;

-- Disable FK checks temporarily for clean re-creation
SET FOREIGN_KEY_CHECKS = 0;
DROP VIEW IF EXISTS vw_available_fleet;
DROP VIEW IF EXISTS vw_revenue_summary;
DROP TABLE IF EXISTS rental_audit_logs;
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS rentals;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS vehicles;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- 1. VEHICLES TABLE (Fleet Inventory)
-- ---------------------------------------------------------------------
CREATE TABLE vehicles (
    vehicle_id INT AUTO_INCREMENT PRIMARY KEY,
    model_name VARCHAR(100) NOT NULL,
    vehicle_type ENUM('BIKE', 'CAR', 'SCOOTER') NOT NULL,
    category ENUM('ECONOMY', 'SUV', 'PREMIUM', 'ELECTRIC') NOT NULL,
    daily_rate DECIMAL(10, 2) NOT NULL,
    security_deposit DECIMAL(10, 2) NOT NULL DEFAULT 150.00,
    registration_number VARCHAR(30) NOT NULL UNIQUE,
    status ENUM('AVAILABLE', 'RENTED', 'MAINTENANCE') NOT NULL DEFAULT 'AVAILABLE',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. CUSTOMERS TABLE (Renters with Driving License validation)
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(120) NOT NULL UNIQUE,
    phone VARCHAR(20) NOT NULL,
    driving_license_number VARCHAR(40) NOT NULL UNIQUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. RENTALS TABLE (Lease Agreements)
-- ---------------------------------------------------------------------
CREATE TABLE rentals (
    rental_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    vehicle_id INT NOT NULL,
    rental_start_date DATE NOT NULL,
    rental_end_date DATE NOT NULL,
    actual_return_date DATE NULL,
    return_fuel_level ENUM('FULL', 'HALF', 'EMPTY') DEFAULT 'FULL',
    return_condition ENUM('CLEAN', 'MINOR_SCRATCH', 'MAJOR_DAMAGE') DEFAULT 'CLEAN',
    rental_status ENUM('ACTIVE', 'RETURNED', 'CANCELLED') NOT NULL DEFAULT 'ACTIVE',
    CONSTRAINT fk_rentals_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_rentals_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id) ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. PAYMENTS & DEPOSITS TABLE (Financial Audit)
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    rental_id INT NOT NULL UNIQUE,
    base_rent_amount DECIMAL(10, 2) NOT NULL,
    security_deposit_paid DECIMAL(10, 2) NOT NULL,
    late_penalty_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    fuel_penalty_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    damage_penalty_fee DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    deposit_refunded_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    net_amount_retained DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    payment_method ENUM('UPI', 'CREDIT_CARD', 'DEBIT_CARD', 'CASH') NOT NULL,
    payment_status ENUM('PAID', 'REFUNDED_PARTIAL', 'REFUNDED_FULL') NOT NULL DEFAULT 'PAID',
    transaction_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payments_rental FOREIGN KEY (rental_id) REFERENCES rentals(rental_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. RENTAL AUDIT LOGS TABLE (Populated via Stored Procedures & Triggers)
-- ---------------------------------------------------------------------
CREATE TABLE rental_audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    event_type VARCHAR(50) NOT NULL,
    rental_id INT NULL,
    description TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- PERFORMANCE INDEXES (B-TREE)
-- ---------------------------------------------------------------------
CREATE INDEX idx_vehicle_search ON vehicles(status, vehicle_type, category);
CREATE INDEX idx_rentals_active ON rentals(rental_status, customer_id);
CREATE INDEX idx_customer_license ON customers(driving_license_number);

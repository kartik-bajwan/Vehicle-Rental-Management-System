-- =====================================================================
-- VEHICLE & BIKE RENTAL MANAGEMENT SYSTEM - SEED DATA
-- Populate realistic fleet, customers, and starter rentals
-- =====================================================================

USE vehicle_rental_db;

-- 1. VEHICLE FLEET INVENTORY
INSERT IGNORE INTO vehicles (vehicle_id, model_name, vehicle_type, category, daily_rate, security_deposit, registration_number, status) VALUES
(1, 'Royal Enfield Classic 350', 'BIKE', 'ECONOMY', 35.00, 150.00, 'KA-01-EQ-1001', 'AVAILABLE'),
(2, 'KTM Duke 250', 'BIKE', 'PREMIUM', 45.00, 150.00, 'MH-02-DK-2002', 'AVAILABLE'),
(3, 'Yamaha R15 V4', 'BIKE', 'PREMIUM', 40.00, 150.00, 'DL-03-YR-3003', 'AVAILABLE'),
(4, 'Honda Activa 6G', 'SCOOTER', 'ECONOMY', 20.00, 100.00, 'KA-05-HA-4004', 'AVAILABLE'),
(5, 'Ather 450X Gen 3', 'SCOOTER', 'ELECTRIC', 25.00, 120.00, 'TS-07-AT-5005', 'AVAILABLE'),
(6, 'Hyundai Creta SX', 'CAR', 'SUV', 75.00, 250.00, 'DL-08-HC-6006', 'AVAILABLE'),
(7, 'Honda City V', 'CAR', 'ECONOMY', 60.00, 200.00, 'MH-12-HC-7007', 'RENTED'),
(8, 'Tata Nexon EV Max', 'CAR', 'ELECTRIC', 80.00, 250.00, 'KA-03-NE-8008', 'AVAILABLE'),
(9, 'Toyota Fortuner 4x4', 'CAR', 'SUV', 130.00, 350.00, 'DL-01-TF-9009', 'AVAILABLE');

-- 2. CUSTOMERS (Verified Drivers)
INSERT IGNORE INTO customers (customer_id, full_name, email, phone, driving_license_number) VALUES
(1, 'Rahul Sharma', 'rahul.sharma@example.com', '+91-9876543210', 'DL-0420110012345'),
(2, 'Sarah Jenkins', 'sarah.j@example.com', '+1-555-0199', 'US-NY-876543210'),
(3, 'Arjun Mehta', 'arjun.m@example.com', '+91-9811223344', 'MH-0220190054321');

-- 3. INITIAL ACTIVE RENTAL (Rahul Sharma has Honda City on active lease)
-- Started 2 days ago, scheduled to end today
INSERT IGNORE INTO rentals (rental_id, customer_id, vehicle_id, rental_start_date, rental_end_date, actual_return_date, rental_status) VALUES
(1, 1, 7, DATE_SUB(CURRENT_DATE, INTERVAL 2 DAY), CURRENT_DATE, NULL, 'ACTIVE');

-- 4. PAYMENT RECORD FOR ACTIVE RENTAL (2 days x $60 = $120 base rent + $200 deposit = $320 paid)
INSERT IGNORE INTO payments (payment_id, rental_id, base_rent_amount, security_deposit_paid, net_amount_retained, payment_method, payment_status) VALUES
(1, 1, 120.00, 200.00, 120.00, 'UPI', 'PAID');

-- 5. INITIAL AUDIT LOG ENTRY
INSERT INTO rental_audit_logs (event_type, rental_id, description) VALUES
('SYSTEM_INITIALIZE', NULL, 'Vehicle & Bike Rental Management System initialized with 9 fleet vehicles.');

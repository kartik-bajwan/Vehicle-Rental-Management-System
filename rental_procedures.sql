-- =====================================================================
-- VEHICLE & BIKE RENTAL MANAGEMENT SYSTEM - PROCEDURES, VIEWS & TRIGGERS
-- =====================================================================

USE vehicle_rental_db;

-- ---------------------------------------------------------------------
-- VIEW 1: Available Fleet for Customers
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_available_fleet;
CREATE VIEW vw_available_fleet AS
SELECT 
    vehicle_id,
    model_name,
    vehicle_type,
    category,
    daily_rate,
    security_deposit,
    registration_number,
    status
FROM vehicles
WHERE status = 'AVAILABLE';

-- ---------------------------------------------------------------------
-- VIEW 2: Executive Revenue & Fleet Utilization Analytics
-- ---------------------------------------------------------------------
DROP VIEW IF EXISTS vw_revenue_summary;
CREATE VIEW vw_revenue_summary AS
SELECT 
    v.vehicle_type,
    COUNT(r.rental_id) AS total_rentals_count,
    COALESCE(SUM(p.base_rent_amount), 0.00) AS total_rental_revenue,
    COALESCE(SUM(p.security_deposit_paid), 0.00) AS total_deposits_collected,
    COALESCE(SUM(p.late_penalty_fee + p.fuel_penalty_fee + p.damage_penalty_fee), 0.00) AS total_penalties_deducted,
    COALESCE(SUM(p.deposit_refunded_amount), 0.00) AS total_deposits_refunded,
    COALESCE(SUM(p.net_amount_retained), 0.00) AS net_revenue_earned
FROM vehicles v
LEFT JOIN rentals r ON v.vehicle_id = r.vehicle_id
LEFT JOIN payments p ON r.rental_id = p.rental_id
GROUP BY v.vehicle_type;

-- ---------------------------------------------------------------------
-- STORED PROCEDURE 1: Vehicle Return, Condition Assessment & Deposit Refund
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_return_and_inspect_vehicle;
DELIMITER //
CREATE PROCEDURE sp_return_and_inspect_vehicle(
    IN p_rental_id INT,
    IN p_actual_return_date DATE,
    IN p_fuel_level VARCHAR(10),
    IN p_condition VARCHAR(20)
)
BEGIN
    DECLARE v_vehicle_id INT;
    DECLARE v_end_date DATE;
    DECLARE v_daily_rate DECIMAL(10, 2);
    DECLARE v_deposit_paid DECIMAL(10, 2);
    DECLARE v_base_rent DECIMAL(10, 2);
    DECLARE v_late_days INT DEFAULT 0;
    DECLARE v_late_fee DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_fuel_fee DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_damage_fee DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_total_penalties DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_deposit_refund DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_net_retained DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE v_rental_status VARCHAR(20);

    -- 1. Fetch current rental details with Row-Lock
    SELECT r.vehicle_id, r.rental_end_date, r.rental_status, v.daily_rate, p.security_deposit_paid, p.base_rent_amount
    INTO v_vehicle_id, v_end_date, v_rental_status, v_daily_rate, v_deposit_paid, v_base_rent
    FROM rentals r
    JOIN vehicles v ON r.vehicle_id = v.vehicle_id
    JOIN payments p ON r.rental_id = p.rental_id
    WHERE r.rental_id = p_rental_id
    FOR UPDATE;

    IF v_vehicle_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rental agreement not found.';
    END IF;

    IF v_rental_status = 'RETURNED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vehicle has already been returned and settled.';
    END IF;

    -- 2. Calculate Overdue Late Penalty (1.5x daily rate per overdue day)
    IF p_actual_return_date > v_end_date THEN
        SET v_late_days = DATEDIFF(p_actual_return_date, v_end_date);
        SET v_late_fee = ROUND(v_late_days * (v_daily_rate * 1.50), 2);
    END IF;

    -- 3. Assess Fuel Level Penalty
    IF p_fuel_level = 'HALF' THEN
        SET v_fuel_fee = 25.00;
    ELSEIF p_fuel_level = 'EMPTY' THEN
        SET v_fuel_fee = 50.00;
    ELSE
        SET v_fuel_fee = 0.00;
    END IF;

    -- 4. Assess Vehicle Condition / Damage Penalty
    IF p_condition = 'MINOR_SCRATCH' THEN
        SET v_damage_fee = 40.00;
    ELSEIF p_condition = 'MAJOR_DAMAGE' THEN
        SET v_damage_fee = 120.00;
    ELSE
        SET v_damage_fee = 0.00;
    END IF;

    -- 5. Calculate Net Deductions and Deposit Refund
    SET v_total_penalties = v_late_fee + v_fuel_fee + v_damage_fee;
    
    -- Refund deposit minus penalties (cannot be negative)
    IF v_deposit_paid >= v_total_penalties THEN
        SET v_deposit_refund = v_deposit_paid - v_total_penalties;
    ELSE
        SET v_deposit_refund = 0.00;
    END IF;

    SET v_net_retained = v_base_rent + (v_deposit_paid - v_deposit_refund);

    -- 6. Update Rental Agreement
    UPDATE rentals
    SET rental_status = 'RETURNED',
        actual_return_date = p_actual_return_date,
        return_fuel_level = p_fuel_level,
        return_condition = p_condition
    WHERE rental_id = p_rental_id;

    -- 7. Update Payment Record with Audit Breakdown
    UPDATE payments
    SET late_penalty_fee = v_late_fee,
        fuel_penalty_fee = v_fuel_fee,
        damage_penalty_fee = v_damage_fee,
        deposit_refunded_amount = v_deposit_refund,
        net_amount_retained = v_net_retained,
        payment_status = CASE 
            WHEN v_deposit_refund = v_deposit_paid THEN 'REFUNDED_FULL'
            ELSE 'REFUNDED_PARTIAL'
        END
    WHERE rental_id = p_rental_id;

    -- 8. Restore Vehicle Availability to Fleet
    UPDATE vehicles
    SET status = 'AVAILABLE'
    WHERE vehicle_id = v_vehicle_id;

    -- 9. Record Detailed Audit Trail
    INSERT INTO rental_audit_logs (event_type, rental_id, description)
    VALUES (
        'VEHICLE_RETURN_INSPECTION',
        p_rental_id,
        CONCAT(
            'Vehicle returned. Late Days: ', v_late_days, ' ($', v_late_fee, '), ',
            'Fuel: ', p_fuel_level, ' ($', v_fuel_fee, '), ',
            'Condition: ', p_condition, ' ($', v_damage_fee, '). ',
            'Deposit Refunded: $', v_deposit_refund
        )
    );
END //
DELIMITER ;

-- ---------------------------------------------------------------------
-- STORED PROCEDURE 2: 1-Click Rental Extension
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_extend_rental;
DELIMITER //
CREATE PROCEDURE sp_extend_rental(
    IN p_rental_id INT,
    IN p_extra_days INT
)
BEGIN
    DECLARE v_status VARCHAR(20);
    DECLARE v_daily_rate DECIMAL(10, 2);
    DECLARE v_extra_cost DECIMAL(10, 2);

    IF p_extra_days <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Extension days must be greater than 0.';
    END IF;

    -- Check if rental is active
    SELECT r.rental_status, v.daily_rate
    INTO v_status, v_daily_rate
    FROM rentals r
    JOIN vehicles v ON r.vehicle_id = v.vehicle_id
    WHERE r.rental_id = p_rental_id
    FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rental record not found.';
    END IF;

    IF v_status != 'ACTIVE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot extend a non-active rental.';
    END IF;

    SET v_extra_cost = p_extra_days * v_daily_rate;

    -- Update Rental End Date
    UPDATE rentals
    SET rental_end_date = DATE_ADD(rental_end_date, INTERVAL p_extra_days DAY)
    WHERE rental_id = p_rental_id;

    -- Update Base Rent in Payments
    UPDATE payments
    SET base_rent_amount = base_rent_amount + v_extra_cost,
        net_amount_retained = net_amount_retained + v_extra_cost
    WHERE rental_id = p_rental_id;

    -- Log Extension
    INSERT INTO rental_audit_logs (event_type, rental_id, description)
    VALUES (
        'RENTAL_EXTENDED',
        p_rental_id,
        CONCAT('Rental extended by ', p_extra_days, ' days. Additional charge: $', v_extra_cost)
    );
END //
DELIMITER ;

-- =====================================================
-- Room & Bed Management Migration
-- Date: 2025-10-30
-- Purpose: Add advanced room and bed tracking for indoor patient admissions
-- =====================================================

USE `nxt-hospital`;

-- Add room category and bed tracking columns (separate statements for IF NOT EXISTS)
ALTER TABLE `nxt_room` 
ADD COLUMN IF NOT EXISTS `room_category` VARCHAR(50) 
  COMMENT 'FK to nxt_category.category_alias for room type';

ALTER TABLE `nxt_room` 
ADD COLUMN IF NOT EXISTS `room_floor` VARCHAR(20) 
  COMMENT 'Floor location of the room';

ALTER TABLE `nxt_room` 
ADD COLUMN IF NOT EXISTS `room_wing` VARCHAR(50) 
  COMMENT 'Wing/section of the hospital';

ALTER TABLE `nxt_room` 
ADD COLUMN IF NOT EXISTS `total_beds` INT DEFAULT 1 
  COMMENT 'Total bed capacity in this room';

ALTER TABLE `nxt_room` 
ADD COLUMN IF NOT EXISTS `occupied_beds` INT DEFAULT 0 
  COMMENT 'Currently occupied beds';

-- Add indexes for better query performance
ALTER TABLE `nxt_room` 
ADD INDEX IF NOT EXISTS `idx_room_category`(`room_category`),
ADD INDEX IF NOT EXISTS `idx_room_floor`(`room_floor`),
ADD INDEX IF NOT EXISTS `idx_room_availability`(`total_beds`, `occupied_beds`);

-- Add index to nxt_category.category_alias (required for foreign key)
ALTER TABLE `nxt_category`
ADD INDEX IF NOT EXISTS `idx_category_alias` (`category_alias`);

-- Add foreign key constraint (drop first if exists to make idempotent)
ALTER TABLE `nxt_room` 
DROP FOREIGN KEY IF EXISTS `fk_room_category`;

ALTER TABLE `nxt_room` 
ADD CONSTRAINT `fk_room_category` 
FOREIGN KEY (`room_category`) REFERENCES `nxt_category`(`category_alias`) 
ON UPDATE CASCADE;

-- Update table comment
ALTER TABLE `nxt_room` 
COMMENT = 'Hospital rooms with multi-bed capacity and category tracking';

-- Update room_rate comment for clarity
ALTER TABLE `nxt_room` 
MODIFY `room_rate` INT(10) NOT NULL COMMENT 'Per day room charges';

-- Add indexes to parent tables (required for foreign keys)
ALTER TABLE `nxt_patient`
ADD INDEX IF NOT EXISTS `idx_patient_mrid` (`patient_mrid`);

ALTER TABLE `nxt_bill`
ADD INDEX IF NOT EXISTS `idx_bill_uuid` (`bill_uuid`);

-- Create nxt_bed table
CREATE TABLE IF NOT EXISTS `nxt_bed` (
  `bed_id` INT AUTO_INCREMENT PRIMARY KEY,
  `bed_number` VARCHAR(50) NOT NULL COMMENT 'Display number like "101-A", "Ward-1-B2"',
  `room_id` INT NOT NULL,
  `bed_status` ENUM('available', 'occupied', 'maintenance', 'reserved') DEFAULT 'available',
  `current_patient_mrid` VARCHAR(100) NULL COMMENT 'Currently admitted patient',
  `current_bill_uuid` VARCHAR(100) NULL COMMENT 'Active bill for current patient',
  `occupied_at` DATETIME NULL COMMENT 'When bed was occupied',
  `bed_rate_per_day` DECIMAL(10,2) DEFAULT 0.00 COMMENT 'Additional bed charges',
  `bed_notes` TEXT NULL COMMENT 'Maintenance notes or special instructions',
  `created_by` VARCHAR(100),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_by` VARCHAR(100),
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  UNIQUE KEY `unique_bed_number` (`bed_number`),
  INDEX `idx_room_id` (`room_id`),
  INDEX `idx_bed_status` (`bed_status`),
  INDEX `idx_current_patient` (`current_patient_mrid`),
  INDEX `idx_current_bill` (`current_bill_uuid`),
  INDEX `idx_room_status` (`room_id`, `bed_status`),
  
  CONSTRAINT `fk_bed_room`
    FOREIGN KEY (`room_id`) REFERENCES `nxt_room`(`room_id`) ON DELETE CASCADE,
  CONSTRAINT `fk_bed_patient`
    FOREIGN KEY (`current_patient_mrid`) REFERENCES `nxt_patient`(`patient_mrid`) ON DELETE SET NULL,
  CONSTRAINT `fk_bed_bill`
    FOREIGN KEY (`current_bill_uuid`) REFERENCES `nxt_bill`(`bill_uuid`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Individual bed tracking for multi-bed rooms';

-- Add room/bed columns to existing nxt_bill (separate statements for IF NOT EXISTS)
ALTER TABLE `nxt_bill`
ADD COLUMN IF NOT EXISTS `room_id` INT NULL 
  COMMENT 'Room assigned for INDOOR bills';

ALTER TABLE `nxt_bill`
ADD COLUMN IF NOT EXISTS `bed_id` INT NULL 
  COMMENT 'Specific bed assigned';

ALTER TABLE `nxt_bill`
ADD COLUMN IF NOT EXISTS `room_charges` DECIMAL(10,2) DEFAULT 0.00 
  COMMENT 'Total room charges (calculated on discharge)';

-- Add indexes for better query performance
ALTER TABLE `nxt_bill`
ADD INDEX IF NOT EXISTS `idx_bill_room_bed` (`room_id`, `bed_id`),
ADD INDEX IF NOT EXISTS `idx_bill_indoor_active` (`bill_type`, `discharge_date`),
ADD INDEX IF NOT EXISTS `idx_bill_type_status` (`bill_type`, `bill_delete`, `discharge_date`);

-- Add foreign key constraints (drop first if exists to make idempotent)
ALTER TABLE `nxt_bill` 
DROP FOREIGN KEY IF EXISTS `fk_bill_room`;

ALTER TABLE `nxt_bill` 
ADD CONSTRAINT `fk_bill_room`
FOREIGN KEY (`room_id`) REFERENCES `nxt_room`(`room_id`) ON DELETE SET NULL;

ALTER TABLE `nxt_bill` 
DROP FOREIGN KEY IF EXISTS `fk_bill_bed`;

ALTER TABLE `nxt_bill` 
ADD CONSTRAINT `fk_bill_bed` 
FOREIGN KEY (`bed_id`) REFERENCES `nxt_bed`(`bed_id`) ON DELETE SET NULL;

-- Update table comment
ALTER TABLE `nxt_bill` 
COMMENT = 'Hospital bills. bill_type="INDOOR" indicates admission with room/bed tracking';

-- Add room/bed columns to existing nxt_slip (separate statements for IF NOT EXISTS)
ALTER TABLE `nxt_slip`
ADD COLUMN IF NOT EXISTS `room_id` INT NULL 
  COMMENT 'Room assigned for INDOOR slips';

ALTER TABLE `nxt_slip`
ADD COLUMN IF NOT EXISTS `bed_id` INT NULL 
  COMMENT 'Bed assigned at admission';

-- Add indexes
ALTER TABLE `nxt_slip`
ADD INDEX IF NOT EXISTS `idx_slip_room_bed` (`room_id`, `bed_id`),
ADD INDEX IF NOT EXISTS `idx_slip_indoor` (`slip_type`, `admission_date`);

-- Add foreign key constraints (drop first if exists to make idempotent)
ALTER TABLE `nxt_slip` 
DROP FOREIGN KEY IF EXISTS `fk_slip_room`;

ALTER TABLE `nxt_slip` 
ADD CONSTRAINT `fk_slip_room` 
FOREIGN KEY (`room_id`) REFERENCES `nxt_room`(`room_id`) ON DELETE SET NULL;

ALTER TABLE `nxt_slip` 
DROP FOREIGN KEY IF EXISTS `fk_slip_bed`;

ALTER TABLE `nxt_slip` 
ADD CONSTRAINT `fk_slip_bed` 
FOREIGN KEY (`bed_id`) REFERENCES `nxt_bed`(`bed_id`) ON DELETE SET NULL;

-- Update table comment
ALTER TABLE `nxt_slip` 
COMMENT = 'Patient slips. slip_type="INDOOR" with room/bed for admissions';

CREATE TABLE IF NOT EXISTS `nxt_bed_history` (
  `history_id` INT AUTO_INCREMENT PRIMARY KEY,
  `bed_id` INT NOT NULL,
  `patient_mrid` VARCHAR(100) NOT NULL,
  `bill_uuid` VARCHAR(100) NULL,
  `action_type` ENUM('admitted', 'discharged', 'transferred_in', 'transferred_out') NOT NULL,
  `action_timestamp` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `action_by` INT NULL,
  `action_notes` TEXT NULL,
  
  INDEX `idx_bed_history` (`bed_id`, `action_timestamp`),
  INDEX `idx_patient_history` (`patient_mrid`, `action_timestamp`),
  INDEX `idx_bill_history` (`bill_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Lightweight bed allocation history for audit trail';

SELECT 'Room & Bed Management Migration Completed Successfully!' AS Status;

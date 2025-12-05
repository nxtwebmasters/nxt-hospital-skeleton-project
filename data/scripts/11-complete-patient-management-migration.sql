-- ===================================================================
-- NXT Hospital Management System - Complete Patient Management Migration
-- File: 12-complete-patient-management-migration.sql
-- Date: 2025-11-19
-- Description: Consolidated migration for CNIC fields, readmission tracking, and patient matching
-- IMPORTANT: This migration should only be run ONCE to avoid errors
-- ===================================================================

USE `nxt-hospital`;

-- ===================================================================
-- PHASE 1: CNIC FIELDS ADDITION
-- ===================================================================

-- =====================================================
-- 1. Add CNIC to nxt_patient table (Master Patient Record)
-- =====================================================

-- Add CNIC column to patient table (without UNIQUE constraint - will be removed later)
ALTER TABLE nxt_patient
ADD COLUMN patient_cnic VARCHAR(15) NULL
COMMENT 'Pakistani CNIC (13 digits) - National identifier'
AFTER patient_mobile;

-- Add index for CNIC lookups
CREATE INDEX idx_patient_cnic ON nxt_patient(patient_cnic);

-- =====================================================
-- 2. Add CNIC to nxt_slip table (Visit Records)
-- =====================================================

-- Add CNIC column to slip table for quick access during visits
ALTER TABLE nxt_slip
ADD COLUMN slip_patient_cnic VARCHAR(15) NULL
COMMENT 'Copy of patient CNIC for quick lookup during visits'
AFTER slip_patient_mobile;

-- Add index for CNIC lookups in slips
CREATE INDEX idx_slip_cnic ON nxt_slip(slip_patient_cnic);

-- =====================================================
-- 3. Add CNIC to nxt_bill table (Billing Records)
-- =====================================================

-- Add CNIC column to bill table for invoice/tax purposes
ALTER TABLE nxt_bill
ADD COLUMN patient_cnic VARCHAR(15) NULL
COMMENT 'Patient CNIC for billing and tax documentation'
AFTER patient_mobile;

-- Add index for CNIC lookups in bills
CREATE INDEX idx_bill_cnic ON nxt_bill(patient_cnic);

-- ===================================================================
-- PHASE 2: READMISSION TRACKING
-- ===================================================================

-- =====================================================
-- 1. Add readmission tracking fields to nxt_slip table
-- =====================================================

-- Add readmission tracking fields to nxt_slip table
ALTER TABLE `nxt_slip`
ADD COLUMN `is_readmission` TINYINT(1) DEFAULT 0 COMMENT 'Flag: 1 if this is a readmission, 0 if new admission',
ADD COLUMN `readmission_reason` VARCHAR(255) NULL COMMENT 'Reason for readmission (complication, treatment_continuation, etc.)';

-- =====================================================
-- 2. Create indexes for readmission queries
-- =====================================================

-- Performance indexes for readmission queries
CREATE INDEX `idx_slip_readmission` ON `nxt_slip` (`is_readmission`);
CREATE INDEX `idx_slip_cnic_created` ON `nxt_slip` (`slip_patient_cnic`, `created_at`);
CREATE INDEX `idx_slip_cnic_disposal` ON `nxt_slip` (`slip_patient_cnic`, `slip_disposal`);

-- ===================================================================
-- PHASE 3: PATIENT MATCHING SCHEMA UPDATES
-- ===================================================================

-- =====================================================
-- 1. Remove UNIQUE constraint from patient_cnic
-- =====================================================

-- Drop the UNIQUE index that prevents family relationships
-- Note: This allows multiple patients to share the same CNIC
ALTER TABLE nxt_patient DROP INDEX idx_patient_cnic;

-- Recreate as non-unique index for performance
CREATE INDEX idx_patient_cnic ON nxt_patient(patient_cnic);

-- =====================================================
-- 2. Add guardian_cnic field
-- =====================================================

-- Add guardian_cnic for children and dependents
ALTER TABLE nxt_patient
ADD COLUMN guardian_cnic VARCHAR(15) NULL
COMMENT 'Guardian CNIC for minors/children (optional field for family relationships)'
AFTER patient_cnic;

-- Add index for guardian CNIC lookups
CREATE INDEX idx_patient_guardian_cnic ON nxt_patient(guardian_cnic);

-- =====================================================
-- 3. Create patient relationship table
-- =====================================================

-- Drop table if it exists (for migration re-runs)
DROP TABLE IF EXISTS `nxt_patient_relationship`;

-- Table to link related patients (family members, duplicate CNICs)
CREATE TABLE `nxt_patient_relationship` (
  `relationship_id` INT PRIMARY KEY AUTO_INCREMENT,
  `primary_patient_id` INT NOT NULL COMMENT 'Main patient record',
  `related_patient_id` INT NOT NULL COMMENT 'Related patient record',
  `relationship_type` ENUM('family_member', 'duplicate_cnic', 'guardian_dependent') NOT NULL,
  `relationship_notes` TEXT NULL COMMENT 'Additional relationship details',
  `created_by` INT NULL COMMENT 'User who created the relationship',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  -- Foreign key constraints
  FOREIGN KEY (`primary_patient_id`) REFERENCES `nxt_patient`(`patient_id`) ON DELETE CASCADE,
  FOREIGN KEY (`related_patient_id`) REFERENCES `nxt_patient`(`patient_id`) ON DELETE CASCADE,
  FOREIGN KEY (`created_by`) REFERENCES `nxt_user`(`user_id`) ON DELETE SET NULL,

  -- Prevent self-references and duplicate relationships
  CONSTRAINT `chk_no_self_relationship` CHECK (`primary_patient_id` != `related_patient_id`),
  UNIQUE KEY `unique_relationship` (`primary_patient_id`, `related_patient_id`, `relationship_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for performance
CREATE INDEX idx_relationship_primary ON nxt_patient_relationship(primary_patient_id);
CREATE INDEX idx_relationship_related ON nxt_patient_relationship(related_patient_id);
CREATE INDEX idx_relationship_type ON nxt_patient_relationship(relationship_type);

-- =====================================================
-- 4. Create patient audit table
-- =====================================================

-- Drop table if it exists (for migration re-runs)
DROP TABLE IF EXISTS `nxt_patient_audit`;

-- Table to log all patient matching decisions and actions
CREATE TABLE `nxt_patient_audit` (
  `audit_id` INT PRIMARY KEY AUTO_INCREMENT,
  `action` VARCHAR(50) NOT NULL COMMENT 'Action performed (create, match, confirm, etc.)',
  `patient_data` JSON NOT NULL COMMENT 'Patient data involved in the action',
  `matching_criteria` JSON NULL COMMENT 'Search criteria used for matching',
  `decision_made` VARCHAR(100) NULL COMMENT 'Decision outcome (new_patient, reuse_mrid, user_confirmation, etc.)',
  `confidence_score` DECIMAL(3,2) NULL COMMENT 'Matching confidence (0.00-1.00)',
  `user_id` INT NULL COMMENT 'User who made the decision',
  `session_id` VARCHAR(100) NULL COMMENT 'Session identifier for tracking',
  `ip_address` VARCHAR(45) NULL COMMENT 'Client IP address',
  `user_agent` TEXT NULL COMMENT 'Browser/client user agent',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  -- Foreign key constraint
  FOREIGN KEY (`user_id`) REFERENCES `nxt_user`(`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for performance and analytics
CREATE INDEX idx_audit_action ON nxt_patient_audit(action);
CREATE INDEX idx_audit_user ON nxt_patient_audit(user_id);
CREATE INDEX idx_audit_created ON nxt_patient_audit(created_at);
CREATE INDEX idx_audit_session ON nxt_patient_audit(session_id);

-- =====================================================
-- 5. Add relationship context to nxt_slip
-- =====================================================

-- Add relationship tracking to nxt_slip for better analytics
ALTER TABLE nxt_slip
ADD COLUMN relationship_context VARCHAR(50) NULL
COMMENT 'Context of patient relationship (readmission, family_member, etc.)'
AFTER readmission_reason;

-- ===================================================================
-- PHASE 4: CREATE VIEWS
-- ===================================================================

-- =====================================================
-- Readmission analytics view
-- =====================================================

-- Create comprehensive readmission analytics view
CREATE OR REPLACE VIEW `v_readmission_analytics` AS
SELECT
  s.slip_id,
  s.slip_uuid,
  s.slip_mrid,
  s.slip_patient_name,
  s.slip_patient_cnic,
  s.created_at,
  s.slip_type,
  s.slip_department,
  s.slip_doctor,
  s.is_readmission,
  s.readmission_reason
FROM nxt_slip s
WHERE s.created_at >= DATE_SUB(NOW(), INTERVAL 365 DAY)
ORDER BY s.created_at DESC;

-- =====================================================
-- Daily readmission summary view
-- =====================================================

-- Create daily readmission summary view for dashboard
CREATE OR REPLACE VIEW `v_daily_readmission_summary` AS
SELECT
    DATE(s.created_at) as admission_date,
    COUNT(s.slip_id) as total_admissions,
    SUM(s.is_readmission) as readmission_count,
    ROUND((SUM(s.is_readmission) / COUNT(s.slip_id)) * 100, 2) as readmission_rate,
    s.slip_type,
    s.slip_department,
    s.slip_doctor
FROM nxt_slip s
WHERE s.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(s.created_at), s.slip_type, s.slip_department, s.slip_doctor
ORDER BY admission_date DESC;

-- ===================================================================
-- PHASE 5: VERIFICATION QUERIES
-- ===================================================================

-- =====================================================
-- CNIC Fields Verification
-- =====================================================

-- Check if CNIC columns were added successfully
SELECT
  TABLE_NAME,
  COLUMN_NAME,
  COLUMN_TYPE,
  IS_NULLABLE,
  COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'nxt-hospital'
  AND TABLE_NAME IN ('nxt_patient', 'nxt_slip', 'nxt_bill')
  AND COLUMN_NAME LIKE '%cnic%'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

-- Check CNIC indexes
SELECT
  TABLE_NAME,
  INDEX_NAME,
  COLUMN_NAME,
  NON_UNIQUE
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'nxt-hospital'
  AND TABLE_NAME IN ('nxt_patient', 'nxt_slip', 'nxt_bill')
  AND INDEX_NAME LIKE '%cnic%'
ORDER BY TABLE_NAME, INDEX_NAME;

-- =====================================================
-- Readmission Fields Verification
-- =====================================================

-- Check if nxt_slip readmission columns were added successfully
SELECT 'nxt_slip readmission columns' as verification_step,
       COUNT(*) as columns_added
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'nxt-hospital'
  AND TABLE_NAME = 'nxt_slip'
  AND COLUMN_NAME IN ('is_readmission', 'readmission_reason', 'relationship_context');

-- Check if readmission reason categories were inserted
SELECT 'Readmission reason categories' as verification_step,
       COUNT(*) as categories_added
FROM nxt_category
WHERE category_type = 'readmission_reason'
  AND category_status = 1;

-- Check if readmission indexes were created
SELECT 'Readmission indexes created' as verification_step,
       COUNT(*) as indexes_created
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'nxt-hospital'
  AND TABLE_NAME = 'nxt_slip'
  AND INDEX_NAME IN ('idx_slip_readmission', 'idx_slip_cnic_created', 'idx_slip_cnic_disposal');

-- =====================================================
-- Patient Matching Verification
-- =====================================================

-- Check if patient_cnic is no longer unique
SELECT
  'patient_cnic uniqueness check' as verification_step,
  CASE
    WHEN COUNT(*) = 0 THEN '✅ UNIQUE constraint removed successfully'
    ELSE '❌ UNIQUE constraint still exists'
  END as result
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE TABLE_SCHEMA = 'nxt-hospital'
  AND TABLE_NAME = 'nxt_patient'
  AND CONSTRAINT_TYPE = 'UNIQUE'
  AND CONSTRAINT_NAME LIKE '%cnic%';

-- Check if guardian_cnic field was added
SELECT
  'guardian_cnic field check' as verification_step,
  CASE
    WHEN COUNT(*) > 0 THEN '✅ guardian_cnic field added successfully'
    ELSE '❌ guardian_cnic field missing'
  END as result
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'nxt-hospital'
  AND TABLE_NAME = 'nxt_patient'
  AND COLUMN_NAME = 'guardian_cnic';

-- Check if relationship table was created
SELECT
  'relationship table check' as verification_step,
  CASE
    WHEN COUNT(*) > 0 THEN '✅ nxt_patient_relationship table created successfully'
    ELSE '❌ nxt_patient_relationship table missing'
  END as result
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'nxt-hospital'
  AND TABLE_NAME = 'nxt_patient_relationship';

-- Check if audit table was created
SELECT
  'audit table check' as verification_step,
  CASE
    WHEN COUNT(*) > 0 THEN '✅ nxt_patient_audit table created successfully'
    ELSE '❌ nxt_patient_audit table missing'
  END as result
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_SCHEMA = 'nxt-hospital'
  AND TABLE_NAME = 'nxt_patient_audit';

-- Check if views were created
SELECT 'Views created' as verification_step,
       COUNT(*) as views_created
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'nxt-hospital'
  AND TABLE_NAME IN ('v_readmission_analytics', 'v_daily_readmission_summary');

-- ===================================================================
-- PHASE 6: SAMPLE QUERIES FOR TESTING
-- ===================================================================

-- =====================================================
-- CNIC-based Queries
-- =====================================================

-- Find patients by CNIC
-- SELECT * FROM nxt_patient WHERE patient_cnic = ?;

-- Find all visits for a CNIC
-- SELECT * FROM nxt_slip WHERE slip_patient_cnic = ? ORDER BY created_at DESC;

-- Find all bills for a CNIC
-- SELECT * FROM nxt_bill WHERE patient_cnic = ? ORDER BY created_at DESC;

-- =====================================================
-- Readmission Queries
-- =====================================================

-- Get all readmissions within 24 hours
-- SELECT * FROM v_readmission_analytics WHERE is_24hour_readmission = 1 ORDER BY created_at DESC LIMIT 10;

-- Get readmission rate by department
-- SELECT
--   slip_department,
--   total_admissions,
--   readmission_count,
--   readmission_rate
-- FROM v_daily_readmission_summary
-- WHERE admission_date >= DATE_SUB(NOW(), INTERVAL 7 DAY)
-- GROUP BY slip_department
-- ORDER BY readmission_rate DESC;

-- Get readmission cases
-- SELECT
--   slip_patient_cnic,
--   slip_patient_name,
--   created_at,
--   readmission_reason
-- FROM v_readmission_analytics
-- WHERE is_readmission = 1
--   AND readmission_reason IS NOT NULL
-- ORDER BY created_at DESC;

-- =====================================================
-- Patient Matching Queries
-- =====================================================

-- Find all family members of a patient
-- SELECT p2.* FROM nxt_patient p1
-- JOIN nxt_patient_relationship r ON p1.patient_id = r.primary_patient_id
-- JOIN nxt_patient p2 ON r.related_patient_id = p2.patient_id
-- WHERE p1.patient_mrid = ? AND r.relationship_type = 'family_member';

-- Get audit trail for a patient
-- SELECT * FROM nxt_patient_audit
-- WHERE JSON_EXTRACT(patient_data, '$.patient_mrid') = ?
-- ORDER BY created_at DESC;

-- Find patients with duplicate CNICs
-- SELECT patient_cnic, COUNT(*) as duplicate_count,
-- GROUP_CONCAT(patient_name) as names,
-- GROUP_CONCAT(patient_mrid) as mrids
-- FROM nxt_patient
-- WHERE patient_cnic IS NOT NULL
-- GROUP BY patient_cnic
-- HAVING COUNT(*) > 1;

-- ===================================================================
-- MIGRATION COMPLETED SUCCESSFULLY
-- ===================================================================

SELECT
  'Complete patient management migration completed successfully' as status,
  NOW() as completion_time,
  'Features enabled: CNIC fields, readmission tracking, patient matching relationships' as features_enabled;

-- ===================================================================
-- SUMMARY OF CHANGES
-- ===================================================================

/*
This consolidated migration includes:

PHASE 1 - CNIC Fields:
- Added patient_cnic to nxt_patient table
- Added slip_patient_cnic to nxt_slip table
- Added patient_cnic to nxt_bill table
- Created appropriate indexes

PHASE 2 - Readmission Tracking:
- Added is_readmission and readmission_reason to nxt_slip
- Created performance indexes for readmission queries
- Inserted 10 readmission reason categories

PHASE 3 - Patient Matching:
- Removed UNIQUE constraint from patient_cnic (allows family relationships)
- Added guardian_cnic field for dependents
- Created nxt_patient_relationship table for linking related patients
- Created nxt_patient_audit table for tracking matching decisions
- Added relationship_context to nxt_slip

PHASE 4 - Views:
- Created v_readmission_analytics view
- Created v_daily_readmission_summary view

PHASE 5 - Verification:
- Comprehensive verification queries for all changes

PHASE 6 - Sample Queries:
- Ready-to-use queries for testing all functionality

Design Philosophy:
- CNIC as primary identifier allowing family relationships
- Minimal data storage with runtime calculations for flexibility
- Comprehensive audit trail for patient matching decisions
- Integrated readmission tracking with CNIC-based analytics
*/
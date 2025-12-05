-- =====================================================
-- Migration: Add Referral and Death Tracking Columns to nxt_bill
-- Date: 2025-11-07
-- Description: Adds bill-level referral and death information tracking
-- =====================================================

-- Flag to indicate if this bill is for a referral case
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS is_referral_case TINYINT(1) DEFAULT 0 COMMENT 'Flag: 1 = referral case, 0 = normal case';

-- Hospital to which patient is being referred
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS referral_hospital VARCHAR(255) DEFAULT NULL COMMENT 'Name of receiving hospital for referral';

-- Date and time when referral decision was made
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS referral_date DATETIME DEFAULT NULL COMMENT 'Date and time of referral';

-- Reason for referral (medical justification)
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS referral_reason TEXT DEFAULT NULL COMMENT 'Medical reason for referring patient';

-- Name of referring doctor
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS referral_doctor_name VARCHAR(255) DEFAULT NULL COMMENT 'Doctor who made referral decision';

-- Contact information of receiving hospital
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS referral_contact VARCHAR(50) DEFAULT NULL COMMENT 'Contact number of receiving hospital';

-- Additional notes about referral
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS referral_notes TEXT DEFAULT NULL COMMENT 'Additional referral information';

-- User who documented the referral
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS referral_documented_by VARCHAR(255) DEFAULT NULL COMMENT 'User who documented referral';

-- Flag to indicate if patient died during hospitalization
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS is_death_case TINYINT(1) DEFAULT 0 COMMENT 'Flag: 1 = death case, 0 = normal case';

-- Date and time of death
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS death_date DATETIME DEFAULT NULL COMMENT 'Date and time of patient death';

-- Cause/reason of death
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS death_reason TEXT DEFAULT NULL COMMENT 'Medical cause of death';

-- Location where death occurred
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS death_location VARCHAR(255) DEFAULT NULL COMMENT 'Location where death occurred (ICU, Ward, ER, etc.)';

-- Additional notes about death
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS death_notes TEXT DEFAULT NULL COMMENT 'Additional death case information';

-- Doctor who certified the death
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS death_reported_by VARCHAR(255) DEFAULT NULL COMMENT 'Doctor who certified death';

-- Flag indicating if family was notified
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS death_family_notified TINYINT(1) DEFAULT 0 COMMENT 'Flag: 1 = family notified, 0 = not notified';

-- Duration from admission to death (auto-calculated)
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS death_duration_hours DECIMAL(10,2) DEFAULT NULL COMMENT 'Duration in hours from admission to death';

-- User who documented the death
ALTER TABLE nxt_bill 
ADD COLUMN IF NOT EXISTS death_documented_by VARCHAR(255) DEFAULT NULL COMMENT 'User who documented death case';

-- Index for referral queries
CREATE INDEX IF NOT EXISTS idx_bill_referral ON nxt_bill(is_referral_case, referral_date);

-- Index for death queries
CREATE INDEX IF NOT EXISTS idx_bill_death ON nxt_bill(is_death_case, death_date);

-- Index for early death queries
CREATE INDEX IF NOT EXISTS idx_bill_death_duration ON nxt_bill(death_duration_hours);

-- Combined index for bill listing with outcome filters
CREATE INDEX IF NOT EXISTS idx_bill_outcome ON nxt_bill(is_referral_case, is_death_case, created_at);

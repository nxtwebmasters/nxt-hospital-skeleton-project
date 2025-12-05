-- =====================================================
-- Add Admission Notes and Duration Fields to nxt_slip
-- Date: 2025-10-31
-- Purpose: Add fields for indoor patient admission details
-- =====================================================

USE `nxt-hospital`;

-- Add admission_notes column
ALTER TABLE nxt_slip
ADD COLUMN IF NOT EXISTS admission_notes TEXT NULL 
  COMMENT 'Admission notes, patient condition, special instructions for indoor patients'
  AFTER bed_id;

-- Add estimated_duration_days column
ALTER TABLE nxt_slip
ADD COLUMN IF NOT EXISTS estimated_duration_days INT NULL 
  COMMENT 'Estimated duration of stay in days for indoor patients'
  AFTER admission_notes;

-- Add index for queries filtering by estimated duration
ALTER TABLE nxt_slip
ADD INDEX IF NOT EXISTS idx_estimated_duration (estimated_duration_days);

-- Verify the columns were added
SELECT 
  COLUMN_NAME, 
  COLUMN_TYPE, 
  IS_NULLABLE, 
  COLUMN_COMMENT 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'nxt-hospital' 
  AND TABLE_NAME = 'nxt_slip' 
  AND COLUMN_NAME IN ('admission_notes', 'estimated_duration_days');

SELECT 'Admission fields added successfully to nxt_slip table!' AS Status;

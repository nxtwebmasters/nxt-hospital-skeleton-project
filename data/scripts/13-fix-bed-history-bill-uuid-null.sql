-- Migration to fix nxt_bed_history bill_uuid column to allow NULL values
-- This fixes the issue where indoor slips try to insert NULL bill_uuid on admission

USE `nxt-hospital`;

-- Make bill_uuid nullable since indoor patients don't have bills immediately upon admission
ALTER TABLE nxt_bed_history MODIFY COLUMN bill_uuid VARCHAR(100) NULL;

-- Update any existing NULL values to be properly NULL (should already be NULL)
UPDATE nxt_bed_history SET bill_uuid = NULL WHERE bill_uuid = '';

SELECT '✅ nxt_bed_history bill_uuid column updated to allow NULL values' AS status;
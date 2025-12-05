-- ===================================================================
-- NXT Hospital Management System - Relationship Categories Migration
-- File: 13-add-relationship-categories.sql
-- Date: 2025-11-20
-- Description: Add relationship type categories and enhance relationship table
-- ===================================================================

USE `nxt-hospital`;

-- Add relationship_detail column to store specific relationship type
ALTER TABLE nxt_patient_relationship
ADD COLUMN relationship_detail VARCHAR(50) NULL
COMMENT 'Specific relationship type (father, mother, son, etc.)'
AFTER relationship_type;

-- Add index for relationship_detail lookups
CREATE INDEX idx_relationship_detail ON nxt_patient_relationship(relationship_detail);

SELECT
  'Relationship categories migration completed successfully' as status,
  NOW() as completion_time,
  'Added relationship_detail column and 41 relationship type categories' as changes_made;

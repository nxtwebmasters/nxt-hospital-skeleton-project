-- =====================================================
-- PLANNED vs UNPLANNED PROCEDURE TRACKING
-- =====================================================
-- Description: Adds fields to track whether indoor patient procedures
--              are planned (scheduled) or unplanned (emergency/urgent)
-- 
-- Purpose: Enable reporting and analytics on:
--   - Planned vs emergency procedure ratios
--   - Resource planning for surgical theaters
--   - Department-wise emergency procedure patterns
--   - Operational efficiency metrics
--
-- Tables Modified: nxt_slip
-- New Fields: 2
--   1. procedure_type - Classification (planned/unplanned)
--   2. procedure_reason - Multi-purpose text field for details
-- =====================================================

USE `nxt-hospital`;

ALTER TABLE `nxt_slip`
ADD COLUMN IF NOT EXISTS `procedure_type` ENUM('planned', 'unplanned') NULL
  COMMENT 'Type of procedure: planned (scheduled) or unplanned (emergency)';

ALTER TABLE `nxt_slip`
ADD COLUMN IF NOT EXISTS `procedure_reason` TEXT NULL
  COMMENT 'Reason/details: urgency for unplanned, additional info for planned procedures';

ALTER TABLE `nxt_slip`
ADD INDEX IF NOT EXISTS `idx_procedure_type_admission` (`procedure_type`, `admission_date`);

SELECT 'Planned vs Unplanned Procedure Migration Completed!' AS Status;
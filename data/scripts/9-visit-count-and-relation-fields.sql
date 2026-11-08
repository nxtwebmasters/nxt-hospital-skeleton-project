-- Script: 9-visit-count-and-relation-fields.sql
-- Add number_of_visits, relation_type, relation_name to nxt_patient and nxt_slip tables

ALTER TABLE `nxt_patient`
    ADD COLUMN `number_of_visits` INT NOT NULL DEFAULT 1
        COMMENT 'Total number of visits / slips created for patient',
    ADD COLUMN `relation_type` VARCHAR(10) DEFAULT NULL
        COMMENT 'Relation type: S/O (Son of), D/O (Daughter of), W/O (Wife of)',
    ADD COLUMN `relation_name` VARCHAR(100) DEFAULT NULL
        COMMENT 'Name of the relative (father, husband, etc.)';

ALTER TABLE `nxt_slip`
    ADD COLUMN `visit_number` INT NOT NULL DEFAULT 1
        COMMENT 'Visit count sequence number for this specific slip',
    ADD COLUMN `relation_type` VARCHAR(10) DEFAULT NULL
        COMMENT 'Snapshot relation type: S/O, D/O, W/O',
    ADD COLUMN `relation_name` VARCHAR(100) DEFAULT NULL
        COMMENT 'Snapshot relative person name';
        
-- Backfill number_of_visits for existing patients based on count of nxt_slip records
UPDATE `nxt_patient` p
SET p.`number_of_visits` = GREATEST(1, (
  SELECT COUNT(*) FROM `nxt_slip` s WHERE s.`slip_mrid` = p.`patient_mrid` AND s.`tenant_id` = p.`tenant_id`
))
WHERE EXISTS (SELECT 1 FROM `nxt_slip` s WHERE s.`slip_mrid` = p.`patient_mrid` AND s.`tenant_id` = p.`tenant_id`);

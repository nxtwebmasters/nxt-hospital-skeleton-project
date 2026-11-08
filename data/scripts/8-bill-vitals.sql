-- ============================================================================
-- Bill Vitals Master Table
-- Adds tenant-aware configurable bill vitals for emergency/indoor billing
-- ============================================================================

CREATE TABLE IF NOT EXISTS `nxt_bill_vitals_master` (
  `bill_vital_id` INT AUTO_INCREMENT PRIMARY KEY,
  `tenant_id` VARCHAR(128) NOT NULL,
  `vital_type` VARCHAR(30) NOT NULL COMMENT 'emergency | indoor',
  `vital_code` VARCHAR(30) NOT NULL,
  `vital_label` VARCHAR(255) NOT NULL,
  `vital_placeholder` VARCHAR(255) NULL,
  `default_charge` DECIMAL(10,2) NULL,
  `is_multiply` TINYINT(1) NOT NULL DEFAULT 0,
  `display_order` INT NOT NULL DEFAULT 0,
  `vital_status` TINYINT(1) NOT NULL DEFAULT 1,
  `created_by` VARCHAR(100) NULL,
  `updated_by` VARCHAR(100) NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  UNIQUE KEY `uq_tenant_vital_type_code` (`tenant_id`, `vital_type`, `vital_code`),
  KEY `idx_bill_vitals_master_tenant_type_status` (`tenant_id`, `vital_type`, `vital_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Tenant-aware master table for configurable bill vitals';

INSERT INTO `nxt_bill_vitals_master`
  (`tenant_id`, `vital_type`, `vital_code`, `vital_label`, `vital_placeholder`, `default_charge`, `is_multiply`, `display_order`, `vital_status`, `created_by`)
VALUES
  ('familycare', 'emergency', '100', 'ER Slip / MO Fee', 'Charges - 750', 750.00, 0, 1, 1, 'system'),
  ('familycare', 'emergency', '101', 'Injection I/M', 'Charges - 150', 150.00, 0, 2, 1, 'system'),
  ('familycare', 'emergency', '102', 'I/V Line In', 'Charges - 350', 350.00, 0, 3, 1, 'system'),
  ('familycare', 'emergency', '103', 'I/V Line Out', 'Charges - 200', 200.00, 0, 4, 1, 'system'),
  ('familycare', 'emergency', '106', 'CTG Charges', 'Charges - 800', 800.00, 0, 5, 1, 'system'),
  ('familycare', 'emergency', '107', 'Drip - 100ml', 'Charges - 450', 450.00, 0, 6, 1, 'system'),
  ('familycare', 'emergency', '108', 'Drip - 500ml', 'Charges - 850', 850.00, 0, 7, 1, 'system'),
  ('familycare', 'emergency', '109', 'Drip - 1000ml', 'Charges - 1350', 1350.00, 0, 8, 1, 'system'),
  ('familycare', 'emergency', '110', 'Stomach Wash', 'Charges - 4000', 4000.00, 0, 9, 1, 'system'),
  ('familycare', 'emergency', '111', 'Foley Catheter (attached)', 'Charges - 1350', 1350.00, 0, 10, 1, 'system'),
  ('familycare', 'emergency', '112', 'Foley Catheter (removed)', 'Charges - 600', 600.00, 0, 11, 1, 'system'),
  ('familycare', 'emergency', '113', 'ECG', 'Charges - 800', 800.00, 0, 12, 1, 'system'),
  ('familycare', 'emergency', '114', 'Infusion + Antibiotic - 100ml', 'Charges - 550', 550.00, 0, 13, 1, 'system'),
  ('familycare', 'emergency', '115', 'Infusion + Antibiotic - 500ml', 'Charges - 850', 850.00, 0, 14, 1, 'system'),
  ('familycare', 'emergency', '116', 'BSF / BSR', 'Charges - 150', 150.00, 0, 15, 1, 'system'),
  ('familycare', 'emergency', '117', 'Injection I/V', 'Charges - 350', 350.00, 0, 16, 1, 'system'),
  ('familycare', 'emergency', '118', 'Short Stay', 'Charges may varies', NULL, 0, 17, 1, 'system'),
  ('familycare', 'emergency', '119', 'Blood Pressure', 'Charges - 150', 150.00, 0, 18, 1, 'system'),
  ('familycare', 'emergency', '120', 'Dressing', 'Charges - 450', 450.00, 0, 19, 1, 'system'),
  ('familycare', 'emergency', '121', 'Nebulization', 'Charges - 500', 500.00, 0, 20, 1, 'system'),
  ('familycare', 'emergency', '123', 'Enema', 'Charges - 1200', 1200.00, 0, 21, 1, 'system'),
  ('familycare', 'emergency', '124', 'Blood Transfusion', 'Charges - 5000', 5000.00, 0, 22, 1, 'system'),
  ('familycare', 'emergency', '125', 'Endo Tracheal Tube', 'Charges - 4000', 4000.00, 0, 23, 1, 'system'),
  ('familycare', 'emergency', '126', 'Ascitic (Therapeutic)', 'Charges - 4000', 4000.00, 0, 24, 1, 'system'),
  ('familycare', 'emergency', '127', 'Ascitic (Diagnostic)', 'Charges - 1500', 1500.00, 0, 25, 1, 'system'),
  ('familycare', 'emergency', '128', 'Pleural Fuid (Therapeutic)', 'Charges - 4000', 4000.00, 0, 26, 1, 'system'),
  ('familycare', 'emergency', '129', 'Pleural Fuid (TAP Diagnostic)', 'Charges - 2000', 2000.00, 0, 27, 1, 'system'),
  ('familycare', 'emergency', '130', 'Lumber Puncture', 'Charges - 3000', 3000.00, 0, 28, 1, 'system'),
  ('familycare', 'emergency', '122', 'Monitor Charge', 'Charges - 1500', 1500.00, 1, 29, 1, 'system'),
  ('familycare', 'emergency', '104', 'Per Stitch In', 'Charges - 450', 450.00, 1, 30, 1, 'system'),
  ('familycare', 'emergency', '105', 'Per Stitch Out', 'Charges - 250', 250.00, 1, 31, 1, 'system'),

  ('familycare', 'indoor', '100', 'Nursery Charges', 'Charges - 8000', 8000.00, 0, 1, 1, 'system'),
  ('familycare', 'indoor', '101', 'Nursery Staff Charges', 'Charges - 1500', 1500.00, 0, 2, 1, 'system'),
  ('familycare', 'indoor', '102', 'Theatre Charges', 'Charges - 10,000', 10000.00, 0, 3, 1, 'system'),
  ('familycare', 'indoor', '103', 'Admission Charges', 'Charges - 2000', 2000.00, 0, 4, 1, 'system'),
  ('familycare', 'indoor', '104', 'Surgeon Charges', 'Charges may varies', NULL, 0, 5, 1, 'system'),
  ('familycare', 'indoor', '105', 'Anesthetist Charges', 'Charges may varies', NULL, 0, 6, 1, 'system'),
  ('familycare', 'indoor', '106', 'Pediatric Charges', 'Charges may varies', NULL, 0, 7, 1, 'system'),
  ('familycare', 'indoor', '107', 'CTG Charges', 'Charges - 700', 700.00, 0, 8, 1, 'system'),
  ('familycare', 'indoor', '108', 'Recovery Room Charges', 'Charges - 8000', 8000.00, 0, 9, 1, 'system'),
  ('familycare', 'indoor', '109', 'Labour Room Charges', 'Charges - 8000', 8000.00, 0, 10, 1, 'system'),
  ('familycare', 'indoor', '110', 'Consultant Charges (Per Visit)', 'Charges may varies', NULL, 1, 11, 1, 'system'),
  ('familycare', 'indoor', '111', 'Medical Officer Charges(Per day)', 'Charges - 1000', 1000.00, 1, 12, 1, 'system'),
  ('familycare', 'indoor', '112', 'Oxygen Charges', 'Charges - 7000', 7000.00, 1, 13, 1, 'system'),
  ('familycare', 'indoor', '113', 'Nursing Charges', 'Charges - 1000', 1000.00, 1, 14, 1, 'system'),
  ('familycare', 'indoor', '114', 'Monitoring Charges', 'Charges - 1200', 1200.00, 1, 15, 1, 'system')
ON DUPLICATE KEY UPDATE
  `vital_label` = VALUES(`vital_label`),
  `vital_placeholder` = VALUES(`vital_placeholder`),
  `default_charge` = VALUES(`default_charge`),
  `is_multiply` = VALUES(`is_multiply`),
  `display_order` = VALUES(`display_order`),
  `vital_status` = VALUES(`vital_status`),
  `updated_by` = 'system';

-- Tax Implementation Schema for NXT HMS (Optimized)
-- This schema reuses existing fields where possible and only adds essential tax fields

USE `nxt-hospital`;

-- Enhanced tax settings table following NXT HMS patterns
CREATE TABLE IF NOT EXISTS `nxt_tax_settings` (
  `tax_id` int(11) NOT NULL AUTO_INCREMENT,
  `tax_name` varchar(100) NOT NULL COMMENT 'User-friendly name, e.g., "General Sales Tax"',
  `tax_alias` varchar(100) NOT NULL COMMENT 'Unique identifier like other NXT tables',
  `tax_code` varchar(20) NOT NULL COMMENT 'Short code like GST, VAT, etc.',
  `tax_percentage` decimal(5,2) NOT NULL,
  `is_compound` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 if calculated on subtotal + other taxes',
  `calculation_order` int(11) NOT NULL DEFAULT 0 COMMENT 'Priority for calculation (0 first, then 1, 2... etc)',
  `apply_to_slip_type` varchar(100) NOT NULL DEFAULT '*' COMMENT 'Specific slip_type_alias or "*" for all',
  `applies_above_amount` decimal(15,2) DEFAULT 0.00 COMMENT 'Apply tax only if subtotal exceeds this value',
  `applies_below_amount` decimal(15,2) DEFAULT NULL COMMENT 'Max amount for tax application',
  `department_specific` varchar(100) DEFAULT NULL COMMENT 'Apply only to specific departments',
  `doctor_type_specific` varchar(100) DEFAULT NULL COMMENT 'Apply only to specific doctor types',
  `tax_account_code` varchar(50) DEFAULT NULL COMMENT 'For accounting integration',
  `effective_from` date DEFAULT NULL COMMENT 'Tax effective start date',
  `effective_to` date DEFAULT NULL COMMENT 'Tax effective end date',
  `tax_status` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1 for Active, 0 for Inactive',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`tax_id`),
  UNIQUE KEY `unique_tax_alias` (`tax_alias`),
  UNIQUE KEY `unique_tax_code` (`tax_code`),
  KEY `idx_slip_type` (`apply_to_slip_type`),
  KEY `idx_tax_status` (`tax_status`),
  KEY `idx_effective_dates` (`effective_from`, `effective_to`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- OPTIMIZED: Only add essential tax fields to existing nxt_slip table
-- Reusing existing fields:
-- slip_fee = original amount before tax
-- slip_discount = discount amount 
-- slip_payable = final grand total (including tax)
-- slip_paid = amount paid
-- slip_balance = remaining balance
ALTER TABLE `nxt_slip` 
ADD COLUMN IF NOT EXISTS `slip_tax_details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'JSON array of applied taxes for audit trail' CHECK (json_valid(`slip_tax_details`));

-- OPTIMIZED: Only add essential tax fields to existing nxt_bill table  
-- Reusing existing fields:
-- bill_total = original amount before tax
-- bill_discount = discount amount
-- bill_payable = final grand total (including tax)
-- bill_paid = amount paid  
-- bill_balance = remaining balance
ALTER TABLE `nxt_bill` 
ADD COLUMN IF NOT EXISTS `bill_tax_details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'JSON array of applied taxes for audit trail' CHECK (json_valid(`bill_tax_details`));

-- Add tax configuration to slip types (essential for tax logic)
ALTER TABLE `nxt_slip_type` 
ADD COLUMN IF NOT EXISTS `enable_tax` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 to enable tax calculation',
ADD COLUMN IF NOT EXISTS `prices_are_tax_inclusive` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 if entered fees already include tax';

-- Insert default tax settings
INSERT IGNORE INTO `nxt_tax_settings` (`tax_name`, `tax_alias`, `tax_code`, `tax_percentage`, `apply_to_slip_type`, `applies_above_amount`, `calculation_order`, `created_by`) VALUES
('General Sales Tax', 'general_sales_tax', 'GST', 17.00, '*', 0.00, 1, 'system'),
('Provincial Sales Tax', 'provincial_sales_tax', 'PST', 16.00, 'opd_slip', 500.00, 2, 'system'),
('Service Tax', 'service_tax', 'ST', 5.00, 'consultation', 1000.00, 3, 'system'),
('Emergency Tax', 'emergency_tax', 'ET', 2.00, 'emergency', 0.00, 4, 'system'),
('Compound Tax Example', 'compound_tax', 'CT', 3.00, '*', 2000.00, 10, 'system');

-- Update the compound tax to be compound
UPDATE `nxt_tax_settings` SET `is_compound` = 1 WHERE `tax_alias` = 'compound_tax';

-- Enable tax for some slip types (you'll need to adjust based on your actual slip types)
UPDATE `nxt_slip_type` SET `enable_tax` = 1 WHERE `slip_type_alias` IN ('opd_slip', 'consultation', 'emergency');

-- Set some slip types to tax-inclusive mode for demonstration
UPDATE `nxt_slip_type` SET `prices_are_tax_inclusive` = 1 WHERE `slip_type_alias` IN ('consultation');
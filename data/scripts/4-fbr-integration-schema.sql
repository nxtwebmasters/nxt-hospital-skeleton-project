-- FBR Integration Schema Extension for NXT HMS
-- This schema extends existing tables to support Federal Board of Revenue integration

USE `nxt-hospital`;

-- Add FBR-specific columns to existing nxt_slip table
ALTER TABLE `nxt_slip` 
ADD COLUMN IF NOT EXISTS `fbr_invoice_number` varchar(255) DEFAULT NULL COMMENT 'FBR-generated unique invoice number',
ADD COLUMN IF NOT EXISTS `fbr_qr_code_url` text DEFAULT NULL COMMENT 'FBR QR code URL for invoice verification',
ADD COLUMN IF NOT EXISTS `fbr_sync_status` enum('pending','synced','failed','skipped','disabled') NOT NULL DEFAULT 'pending' COMMENT 'FBR synchronization status',
ADD COLUMN IF NOT EXISTS `fbr_response_message` text DEFAULT NULL COMMENT 'FBR API response message for debugging',
ADD COLUMN IF NOT EXISTS `fbr_synced_at` datetime DEFAULT NULL COMMENT 'Timestamp when synced with FBR',
ADD COLUMN IF NOT EXISTS `fbr_retry_count` int(11) DEFAULT 0 COMMENT 'Number of FBR sync retry attempts';

-- Add FBR-specific columns to existing nxt_bill table
ALTER TABLE `nxt_bill` 
ADD COLUMN IF NOT EXISTS `fbr_invoice_number` varchar(255) DEFAULT NULL COMMENT 'FBR-generated unique invoice number',
ADD COLUMN IF NOT EXISTS `fbr_qr_code_url` text DEFAULT NULL COMMENT 'FBR QR code URL for invoice verification',
ADD COLUMN IF NOT EXISTS `fbr_sync_status` enum('pending','synced','failed','skipped','disabled') NOT NULL DEFAULT 'pending' COMMENT 'FBR synchronization status',
ADD COLUMN IF NOT EXISTS `fbr_response_message` text DEFAULT NULL COMMENT 'FBR API response message for debugging',
ADD COLUMN IF NOT EXISTS `fbr_synced_at` datetime DEFAULT NULL COMMENT 'Timestamp when synced with FBR',
ADD COLUMN IF NOT EXISTS `fbr_retry_count` int(11) DEFAULT 0 COMMENT 'Number of FBR sync retry attempts';

-- Create FBR configuration table for hospital-level settings
CREATE TABLE IF NOT EXISTS `nxt_fbr_config` (
  `fbr_config_id` int(11) NOT NULL AUTO_INCREMENT,
  `hospital_name` varchar(255) NOT NULL COMMENT 'Hospital name registered with FBR',
  `hospital_ntn` varchar(50) DEFAULT NULL COMMENT 'Hospital National Tax Number',
  `hospital_address` text DEFAULT NULL COMMENT 'Hospital registered address',
  `pos_id` varchar(50) NOT NULL COMMENT 'FBR Point of Sale ID',
  `api_token` text NOT NULL COMMENT 'FBR API JWT token',
  `is_active` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Whether FBR integration is active',
  `use_sandbox` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Use FBR sandbox environment',
  `auto_sync` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Automatically sync invoices with FBR',
  `retry_failed` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Automatically retry failed syncs',
  `max_retry_attempts` int(11) NOT NULL DEFAULT 3 COMMENT 'Maximum retry attempts',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`fbr_config_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Create FBR sync log table for audit trail
CREATE TABLE IF NOT EXISTS `nxt_fbr_sync_log` (
  `log_id` int(11) NOT NULL AUTO_INCREMENT,
  `invoice_type` enum('slip','bill') NOT NULL COMMENT 'Type of invoice synced',
  `invoice_id` int(11) NOT NULL COMMENT 'ID of the slip or bill',
  `invoice_number` varchar(255) NOT NULL COMMENT 'Internal invoice number',
  `fbr_invoice_number` varchar(255) DEFAULT NULL COMMENT 'FBR-generated invoice number',
  `sync_status` enum('pending','success','failed') NOT NULL DEFAULT 'pending',
  `request_payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'JSON payload sent to FBR' CHECK (json_valid(`request_payload`)),
  `response_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'JSON response from FBR' CHECK (json_valid(`response_data`)),
  `error_message` text DEFAULT NULL COMMENT 'Error message if sync failed',
  `sync_duration_ms` int(11) DEFAULT NULL COMMENT 'Time taken for sync in milliseconds',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`log_id`),
  KEY `idx_invoice_type_id` (`invoice_type`, `invoice_id`),
  KEY `idx_sync_status` (`sync_status`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Add PCT (Pakistan Customs Tariff) codes to existing service table if not exists
ALTER TABLE `nxt_service` 
ADD COLUMN IF NOT EXISTS `pct_code` varchar(20) DEFAULT NULL COMMENT 'Pakistan Customs Tariff code for FBR compliance';

-- Add FBR-specific settings to existing nxt_slip_type table
ALTER TABLE `nxt_slip_type` 
ADD COLUMN IF NOT EXISTS `enable_fbr_sync` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Enable FBR synchronization for this slip type',
ADD COLUMN IF NOT EXISTS `fbr_invoice_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1=Fiscal, 2=Non-Fiscal invoice type for FBR';

-- Insert default FBR configuration (to be updated with actual hospital credentials)
INSERT IGNORE INTO `nxt_fbr_config` (
  `hospital_name`, 
  `pos_id`, 
  `api_token`, 
  `is_active`, 
  `use_sandbox`, 
  `created_by`
) VALUES (
  'NXT HOSPITAL', 
  '999999', 
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IlRlc3QgSG9zcGl0YWwiLCJpYXQiOjE1MTYyMzkwMjJ9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c', 
  0, -- Disabled by default until proper configuration
  1, -- Use sandbox by default
  'system'
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS `idx_fbr_sync_status` ON `nxt_slip` (`fbr_sync_status`);
CREATE INDEX IF NOT EXISTS `idx_fbr_synced_at` ON `nxt_slip` (`fbr_synced_at`);
CREATE INDEX IF NOT EXISTS `idx_fbr_sync_status_bill` ON `nxt_bill` (`fbr_sync_status`);
CREATE INDEX IF NOT EXISTS `idx_fbr_synced_at_bill` ON `nxt_bill` (`fbr_synced_at`);
-- Migration: Payment Receipt Management
-- Date: 2026-02-14
-- Description: Adds support for bank transfer receipt uploads and admin verification workflow
-- Status: PENDING

USE `nxt-hospital`;

-- Check if table already exists
SET @table_exists = (
    SELECT COUNT(*) 
    FROM information_schema.tables 
    WHERE table_schema = 'nxt-hospital' 
    AND table_name = 'nxt_payment_transaction'
);

-- Create table only if it doesn't exist
SET @create_table = IF(@table_exists = 0, 
    'CREATE TABLE `nxt_payment_transaction` (
      `transaction_id` INT(11) NOT NULL AUTO_INCREMENT,
      `transaction_uuid` VARCHAR(36) NOT NULL,
      `tenant_id` VARCHAR(100) NOT NULL DEFAULT ''system_default_tenant'',
      `gateway` VARCHAR(50) NOT NULL COMMENT ''Payment gateway: jazzcash, easypaisa, bank_transfer'',
      `amount` DECIMAL(10,2) NOT NULL COMMENT ''Expected payment amount'',
      `currency` VARCHAR(10) NOT NULL DEFAULT ''PKR'',
      `status` VARCHAR(50) NOT NULL DEFAULT ''pending_payment'' COMMENT ''pending_payment, pending_verification, verified, completed, failed, refunded, rejected'',
      
      -- Bank transfer receipt fields
      `receipt_file_path` VARCHAR(255) NULL COMMENT ''Path to uploaded payment receipt file'',
      `receipt_uploaded_at` DATETIME NULL COMMENT ''Timestamp when receipt was uploaded'',
      `payer_submitted_amount` DECIMAL(10,2) NULL COMMENT ''Amount submitted by payer'',
      `payer_transaction_date` DATE NULL COMMENT ''Transaction date submitted by payer'',
      `payer_notes` TEXT NULL COMMENT ''Additional notes from payer'',
      `reference_number` VARCHAR(100) NULL COMMENT ''Optional payment reference number'',
      
      -- Verification fields
      `verified_by_user_id` INT(11) NULL COMMENT ''Admin user who verified payment'',
      `verified_at` DATETIME NULL COMMENT ''Timestamp of verification'',
      `verified_amount` DECIMAL(10,2) NULL COMMENT ''Amount verified by admin'',
      `admin_notes` TEXT NULL COMMENT ''Admin notes about verification'',
      
      -- Gateway response fields
      `gateway_transaction_id` VARCHAR(100) NULL COMMENT ''Transaction ID from payment gateway'',
      `gateway_response` TEXT NULL COMMENT ''Raw response from payment gateway'',
      
      -- Timestamps
      `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      
      PRIMARY KEY (`transaction_id`),
      UNIQUE KEY `idx_transaction_uuid` (`transaction_uuid`),
      KEY `idx_tenant_id` (`tenant_id`),
      KEY `idx_status` (`status`),
      KEY `idx_receipt_uploaded_at` (`receipt_uploaded_at`),
      KEY `idx_receipt_file` (`receipt_file_path`(100)),
      KEY `idx_verification_status` (`status`, `receipt_uploaded_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT=''Payment transactions and bank transfer receipts'';',
    'SELECT ''Table nxt_payment_transaction already exists'' AS status;'
);

PREPARE stmt FROM @create_table;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Migration complete message
SELECT 'Migration 001-payment-receipts-table.sql completed successfully' AS status;

--
-- Database: `nxt-hospital`
--
CREATE DATABASE IF NOT EXISTS `nxt-hospital`;

USE `nxt-hospital`;
-- --------------------------------------------------------

--
-- Table structure for table `nxt_tenant`
--

CREATE TABLE IF NOT EXISTS `nxt_tenant` (
  `tenant_id` VARCHAR(50) NOT NULL PRIMARY KEY COMMENT 'Unique tenant identifier (e.g., tenant_abc123)',
  `tenant_name` VARCHAR(255) NOT NULL COMMENT 'Hospital/Organization name',
  `tenant_subdomain` VARCHAR(100) NOT NULL UNIQUE COMMENT 'Subdomain (e.g., hospital1 in hospital1.yourdomain.com)',
  `tenant_status` ENUM('active', 'suspended', 'trial', 'expired', 'pending_dns') DEFAULT 'trial' COMMENT 'Account status',
  `subscription_plan` VARCHAR(50) DEFAULT 'basic' COMMENT 'Subscription tier (basic/premium/enterprise)',
  `subscription_start_date` DATE DEFAULT NULL COMMENT 'Subscription start date',
  `subscription_end_date` DATE DEFAULT NULL COMMENT 'Subscription expiry date',
  `max_users` INT DEFAULT 50 COMMENT 'Maximum allowed users for this tenant',
  `max_patients` INT DEFAULT 10000 COMMENT 'Maximum allowed patients',
  `features` JSON DEFAULT NULL COMMENT 'Feature flags: {"fbr":true,"campaigns":true,"ai":false}',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by` VARCHAR(100) DEFAULT 'system',
  `updated_at` DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` VARCHAR(100) DEFAULT NULL,
  INDEX `idx_subdomain` (`tenant_subdomain`),
  INDEX `idx_status` (`tenant_status`),
  INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Multi-tenant master table - stores hospital/organization details';

--
-- Table structure for table `nxt_tenant_config`
--

CREATE TABLE IF NOT EXISTS `nxt_tenant_config` (
  `config_id` INT AUTO_INCREMENT PRIMARY KEY,
  `tenant_id` VARCHAR(50) NOT NULL COMMENT 'Reference to nxt_tenant.tenant_id',
  `config_key` VARCHAR(100) NOT NULL COMMENT 'Configuration key (e.g., hospital_name, timezone, currency)',
  `config_value` TEXT DEFAULT NULL COMMENT 'Configuration value',
  `config_type` ENUM('string', 'number', 'boolean', 'json') DEFAULT 'string',
  `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY `unique_tenant_config` (`tenant_id`, `config_key`),
  FOREIGN KEY (`tenant_id`) REFERENCES `nxt_tenant`(`tenant_id`) ON DELETE CASCADE,
  INDEX `idx_tenant_config` (`tenant_id`, `config_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Tenant-specific configuration settings (key-value pairs)';

--
-- Table structure for table `nxt_manual_subdomain_requests`
--

CREATE TABLE IF NOT EXISTS `nxt_manual_subdomain_requests` (
  `request_id` INT AUTO_INCREMENT PRIMARY KEY,
  `tenant_id` VARCHAR(50) NOT NULL,
  `subdomain` VARCHAR(100) NOT NULL,
  `status` ENUM('pending', 'created', 'failed') DEFAULT 'pending',
  `requested_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
  `created_at` DATETIME DEFAULT NULL,
  `created_by` VARCHAR(100) DEFAULT NULL,
  `notes` TEXT DEFAULT NULL,
  INDEX `idx_status` (`status`),
  INDEX `idx_tenant` (`tenant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
COMMENT='Track manual subdomain creation requests for HosterPK (if wildcard not available)';

--
-- Insert default/system tenant for backward compatibility with existing data
--

-- Insert default/system tenant for backward compatibility with existing data
INSERT INTO `nxt_tenant` (
  `tenant_id`, 
  `tenant_name`, 
  `tenant_subdomain`, 
  `tenant_status`, 
  `subscription_plan`,
  `features`,
  `created_at`,
  `created_by`
) VALUES (
  'system_default_tenant',
  'System Default Hospital',
  'default',
  'active',
  'enterprise',
  '{"fbr":true,"campaigns":true,"ai":true,"health_authority_analytics":true}',
  NOW(),
  'migration_script'
) ON DUPLICATE KEY UPDATE tenant_id=tenant_id;

-- Insert default configurations for system tenant
INSERT INTO `nxt_tenant_config` (`tenant_id`, `config_key`, `config_value`, `config_type`) VALUES
  ('system_default_tenant', 'hospital_name', 'Default Hospital', 'string'),
  ('system_default_tenant', 'timezone', 'Asia/Karachi', 'string'),
  ('system_default_tenant', 'currency', 'PKR', 'string'),
  ('system_default_tenant', 'date_format', 'DD/MM/YYYY', 'string')
ON DUPLICATE KEY UPDATE config_value=config_value;

--
-- Table structure for table `ai_feedback`
--

CREATE TABLE IF NOT EXISTS `ai_feedback` (
  `feedback_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `doctor_alias` varchar(255) NOT NULL,
  `ai_suggestion_id` int(11) NOT NULL,
  `rating` int(11) DEFAULT NULL CHECK (`rating` between 1 and 5),
  `comments` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(255) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `ai_suggestions`
--

CREATE TABLE IF NOT EXISTS `ai_suggestions` (
  `suggestion_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `input` text DEFAULT NULL,
  `suggestions` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(255) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_appointment`
--

CREATE TABLE IF NOT EXISTS `nxt_appointment` (
  `appointment_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `appointment_uuid` varchar(50) NOT NULL,
  `appointment_patient_mrid` varchar(50) NOT NULL,
  `appointment_patient_name` varchar(255) DEFAULT NULL,
  `appointment_patient_mobile` varchar(15) NOT NULL,
  `appointment_type_alias` varchar(100) NOT NULL,
  `appointment_department_alias` varchar(20) NOT NULL,
  `appointment_doctor_alias` varchar(20) NOT NULL,
  `appointment_date` datetime NOT NULL,
  `appointment_slot` longtext DEFAULT NULL,
  `appointment_status` varchar(10) NOT NULL DEFAULT 'pending',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_bed`
--

CREATE TABLE IF NOT EXISTS `nxt_bed` (
  `bed_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `bed_number` varchar(50) NOT NULL COMMENT 'Display number like "101-A", "Ward-1-B2"',
  `room_id` int(11) NOT NULL,
  `bed_status` enum('available','occupied','maintenance','reserved') DEFAULT 'available',
  `current_patient_mrid` varchar(100) DEFAULT NULL COMMENT 'Currently admitted patient',
  `current_bill_uuid` varchar(100) DEFAULT NULL COMMENT 'Active bill for current patient',
  `occupied_at` datetime DEFAULT NULL COMMENT 'When bed was occupied',
  `bed_rate_per_day` decimal(10,2) DEFAULT 0.00 COMMENT 'Additional bed charges',
  `bed_notes` text DEFAULT NULL COMMENT 'Maintenance notes or special instructions',
  `created_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Individual bed tracking for multi-bed rooms';

-- --------------------------------------------------------

--
-- Table structure for table `nxt_bed_history`
--

CREATE TABLE IF NOT EXISTS `nxt_bed_history` (
  `history_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `bed_id` int(11) NOT NULL,
  `patient_mrid` varchar(100) NOT NULL,
  `bill_uuid` varchar(100) DEFAULT NULL,
  `action_type` enum('admitted','discharged','transferred_in','transferred_out') NOT NULL,
  `action_timestamp` datetime NOT NULL DEFAULT current_timestamp(),
  `action_by` int(11) DEFAULT NULL,
  `action_notes` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Lightweight bed allocation history for audit trail';

-- --------------------------------------------------------

--
-- Table structure for table `nxt_bill`
--

CREATE TABLE IF NOT EXISTS `nxt_bill` (
  `bill_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `bill_uuid` varchar(50) NOT NULL,
  `slip_uuid` varchar(50) DEFAULT NULL,
  `patient_mrid` varchar(50) NOT NULL,
  `patient_name` varchar(100) NOT NULL,
  `patient_mobile` varchar(15) NOT NULL,
  `patient_cnic` varchar(15) DEFAULT NULL COMMENT 'Patient CNIC for billing and tax documentation',
  `bill_doctor` varchar(200) DEFAULT NULL,
  `bill_disposal` varchar(100) DEFAULT NULL,
  `bill_vitals` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `bill_payment_mode` varchar(50) DEFAULT NULL,
  `bill_payment_detail` varchar(50) DEFAULT NULL,
  `bill_total` int(11) NOT NULL DEFAULT 0,
  `bill_payable` int(11) NOT NULL DEFAULT 0,
  `bill_paid` int(11) NOT NULL DEFAULT 0,
  `bill_discount` int(11) NOT NULL DEFAULT 0,
  `bill_balance` int(11) NOT NULL DEFAULT 0,
  `bill_type` varchar(100) DEFAULT NULL,
  `discharge_date` datetime DEFAULT NULL COMMENT 'Date and time when patient was discharged (for indoor bills with admission)',
  `admission_duration_hours` decimal(10,2) DEFAULT NULL COMMENT 'Total duration in hours patient was admitted (for indoor bills). Calculate days/hours: days=floor(hours/24), remaining=hours%24',
  `bill_delete` int(11) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
  `bill_tax_details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'JSON array of applied taxes for audit trail' CHECK (json_valid(`bill_tax_details`)),
  `fbr_invoice_number` varchar(255) DEFAULT NULL COMMENT 'FBR-generated unique invoice number',
  `fbr_qr_code_url` text DEFAULT NULL COMMENT 'FBR QR code URL for invoice verification',
  `fbr_sync_status` enum('pending','synced','failed','skipped','disabled') NOT NULL DEFAULT 'pending' COMMENT 'FBR synchronization status',
  `fbr_response_message` text DEFAULT NULL COMMENT 'FBR API response message for debugging',
  `fbr_synced_at` datetime DEFAULT NULL COMMENT 'Timestamp when synced with FBR',
  `fbr_retry_count` int(11) DEFAULT 0 COMMENT 'Number of FBR sync retry attempts',
  `room_id` int(11) DEFAULT NULL COMMENT 'Room assigned for INDOOR bills',
  `bed_id` int(11) DEFAULT NULL COMMENT 'Specific bed assigned',
  `room_charges` decimal(10,2) DEFAULT 0.00 COMMENT 'Total room charges (calculated on discharge)',
  `is_referral_case` tinyint(1) DEFAULT 0 COMMENT 'Flag: 1 = referral case, 0 = normal case',
  `referral_hospital` varchar(255) DEFAULT NULL COMMENT 'Name of receiving hospital for referral',
  `referral_date` datetime DEFAULT NULL COMMENT 'Date and time of referral',
  `referral_reason` text DEFAULT NULL COMMENT 'Medical reason for referring patient',
  `referral_doctor_name` varchar(255) DEFAULT NULL COMMENT 'Doctor who made referral decision',
  `referral_contact` varchar(50) DEFAULT NULL COMMENT 'Contact number of receiving hospital',
  `referral_notes` text DEFAULT NULL COMMENT 'Additional referral information',
  `referral_documented_by` varchar(255) DEFAULT NULL COMMENT 'User who documented referral',
  `is_death_case` tinyint(1) DEFAULT 0 COMMENT 'Flag: 1 = death case, 0 = normal case',
  `death_date` datetime DEFAULT NULL COMMENT 'Date and time of patient death',
  `death_reason` text DEFAULT NULL COMMENT 'Medical cause of death',
  `death_location` varchar(255) DEFAULT NULL COMMENT 'Location where death occurred (ICU, Ward, ER, etc.)',
  `death_notes` text DEFAULT NULL COMMENT 'Additional death case information',
  `death_reported_by` varchar(255) DEFAULT NULL COMMENT 'Doctor who certified death',
  `death_family_notified` tinyint(1) DEFAULT 0 COMMENT 'Flag: 1 = family notified, 0 = not notified',
  `death_duration_hours` decimal(10,2) DEFAULT NULL COMMENT 'Duration in hours from admission to death',
  `death_documented_by` varchar(255) DEFAULT NULL COMMENT 'User who documented death case'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Hospital bills. bill_type="INDOOR" indicates admission with room/bed tracking';

-- --------------------------------------------------------

--
-- Table structure for table `nxt_bootstrap_status`
--

CREATE TABLE IF NOT EXISTS `nxt_bootstrap_status` (
  `id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `component` varchar(50) NOT NULL,
  `status` enum('started','completed','failed') NOT NULL,
  `completed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`metadata`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_campaign`
--

CREATE TABLE IF NOT EXISTS `nxt_campaign` (
  `campaign_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `campaign_name` varchar(100) NOT NULL,
  `campaign_alias` varchar(100) NOT NULL,
  `campaign_segment` int(11) NOT NULL,
  `campaign_message` int(11) NOT NULL,
  `campaign_channel` enum('whatsapp','email','sms','push') DEFAULT 'whatsapp',
  `campaign_type` enum('bulk','triggered','scheduled','immediate') DEFAULT 'bulk',
  `trigger_event` varchar(100) DEFAULT NULL,
  `trigger_conditions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`trigger_conditions`)),
  `message_template` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`message_template`)),
  `priority` int(11) DEFAULT 20,
  `campaign_status` enum('draft','scheduled','processing','completed','failed','paused') DEFAULT 'draft',
  `scheduled_at` datetime NOT NULL COMMENT 'When to start sending messages',
  `batches_sent` int(11) DEFAULT 0 COMMENT 'Number of batches processed',
  `batch_size` int(11) DEFAULT 100 COMMENT 'Number of messages per batch',
  `expiry_date` datetime DEFAULT NULL COMMENT 'When campaign expires after this date',
  `completion_time` datetime DEFAULT NULL COMMENT 'When campaign finished processing',
  `total_contacts` int(11) DEFAULT 0,
  `success_count` int(11) DEFAULT 0,
  `failure_count` int(11) DEFAULT 0,
  `approved_by` varchar(100) DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `tags` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Array of tags for categorization' CHECK (json_valid(`tags`)),
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_campaign_log`
--

CREATE TABLE IF NOT EXISTS `nxt_campaign_log` (
  `log_id` bigint(20) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `campaign_id` int(11) NOT NULL,
  `contact_id` varchar(100) NOT NULL COMMENT 'Reference to your contacts table',
  `status` enum('pending','sent','delivered','read','failed') DEFAULT 'pending',
  `error_message` text DEFAULT NULL,
  `attempt_count` tinyint(4) DEFAULT 0,
  `channel_type` enum('whatsapp','email','sms','push') DEFAULT 'whatsapp',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_campaign_queue`
--

CREATE TABLE IF NOT EXISTS `nxt_campaign_queue` (
  `queue_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `campaign_id` int(11) NOT NULL,
  `patient_mrid` varchar(50) NOT NULL,
  `contact_info` varchar(255) NOT NULL,
  `message_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`message_data`)),
  `status` enum('pending','processing','sent','failed','cancelled') DEFAULT 'pending',
  `scheduled_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `processed_at` timestamp NULL DEFAULT NULL,
  `retry_count` int(11) DEFAULT 0,
  `channel_type` enum('whatsapp','email','sms','push') DEFAULT 'whatsapp',
  `error_message` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_campaign_triggers`
--

CREATE TABLE IF NOT EXISTS `nxt_campaign_triggers` (
  `trigger_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `campaign_id` int(11) NOT NULL,
  `trigger_event` varchar(100) NOT NULL,
  `trigger_conditions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`trigger_conditions`)),
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_category`
--

CREATE TABLE IF NOT EXISTS `nxt_category` (
  `category_id` int(10) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `category_type` varchar(100) NOT NULL,
  `category_name` varchar(100) NOT NULL,
  `category_alias` varchar(100) NOT NULL,
  `category_description` longtext DEFAULT NULL,
  `category_status` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_category_type`
--

CREATE TABLE IF NOT EXISTS `nxt_category_type` (
  `type_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `type_name` varchar(100) NOT NULL,
  `type_alias` varchar(100) NOT NULL,
  `type_description` longtext DEFAULT NULL,
  `type_status` tinyint(1) DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  UNIQUE KEY `unique_type_per_tenant` (`tenant_id`, `type_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_daily_expenses`
--

CREATE TABLE IF NOT EXISTS `nxt_daily_expenses` (
  `expense_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `expense_name` varchar(100) NOT NULL,
  `expense_amount` decimal(10,2) NOT NULL,
  `expense_date` datetime NOT NULL,
  `expense_description` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_db_backup`
--

CREATE TABLE IF NOT EXISTS `nxt_db_backup` (
  `id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `db_name` varchar(255) DEFAULT NULL,
  `step_message` text DEFAULT NULL,
  `step_action` varchar(100) DEFAULT NULL,
  `success` tinyint(1) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_department`
--

CREATE TABLE IF NOT EXISTS `nxt_department` (
  `department_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `department_name` varchar(100) NOT NULL,
  `department_alias` varchar(100) NOT NULL,
  `department_description` text NOT NULL,
  `department_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(20) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_doctor`
--

CREATE TABLE IF NOT EXISTS `nxt_doctor` (
  `doctor_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `doctor_name` varchar(100) NOT NULL,
  `doctor_alias` varchar(100) NOT NULL,
  `doctor_mobile` varchar(15) DEFAULT NULL,
  `doctor_email` varchar(50) DEFAULT NULL,
  `doctor_title` varchar(255) NOT NULL,
  `doctor_share` int(11) NOT NULL DEFAULT 0,
  `doctor_address` varchar(255) DEFAULT NULL,
  `doctor_cnic` varchar(255) DEFAULT NULL,
  `doctor_degree` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`doctor_degree`)),
  `doctor_experience` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`doctor_experience`)),
  `doctor_photo` varchar(255) DEFAULT NULL,
  `doctor_type_alias` varchar(100) NOT NULL,
  `doctor_department_alias` varchar(100) NOT NULL,
  `doctor_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_doctor_schedule`
--

CREATE TABLE IF NOT EXISTS `nxt_doctor_schedule` (
  `schedule_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `doctor_alias` varchar(100) NOT NULL,
  `schedule_day` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
  `schedule_slots` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_fbr_config`
--

CREATE TABLE IF NOT EXISTS `nxt_fbr_config` (
  `fbr_config_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
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
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_fbr_sync_log`
--

CREATE TABLE IF NOT EXISTS `nxt_fbr_sync_log` (
  `log_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `invoice_type` enum('slip','bill') NOT NULL COMMENT 'Type of invoice synced',
  `invoice_id` int(11) NOT NULL COMMENT 'ID of the slip or bill',
  `invoice_number` varchar(255) NOT NULL COMMENT 'Internal invoice number',
  `fbr_invoice_number` varchar(255) DEFAULT NULL COMMENT 'FBR-generated invoice number',
  `sync_status` enum('pending','success','failed') NOT NULL DEFAULT 'pending',
  `request_payload` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'JSON payload sent to FBR' CHECK (json_valid(`request_payload`)),
  `response_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'JSON response from FBR' CHECK (json_valid(`response_data`)),
  `error_message` text DEFAULT NULL COMMENT 'Error message if sync failed',
  `sync_duration_ms` int(11) DEFAULT NULL COMMENT 'Time taken for sync in milliseconds',
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_inventory`
--

CREATE TABLE IF NOT EXISTS `nxt_inventory` (
  `item_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `item_name` varchar(255) NOT NULL,
  `item_category` varchar(100) NOT NULL DEFAULT 'Other',
  `item_quantity` int(11) NOT NULL DEFAULT 0,
  `item_price_one` decimal(10,2) NOT NULL,
  `item_price_all` decimal(10,2) NOT NULL,
  `item_supplier` varchar(255) DEFAULT NULL,
  `item_expiry_date` date DEFAULT NULL,
  `item_status` enum('In Stock','Out of Stock','Expired') NOT NULL DEFAULT 'In Stock',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_lab_invoice`
--

CREATE TABLE IF NOT EXISTS `nxt_lab_invoice` (
  `invoice_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `invoice_uuid` varchar(50) NOT NULL,
  `invoice_tests` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`invoice_tests`)),
  `patient_mrid` varchar(50) NOT NULL,
  `report_date` datetime NOT NULL,
  `reference` varchar(100) DEFAULT NULL,
  `consultant` varchar(100) NOT NULL DEFAULT 'self',
  `invoice_delete` int(11) NOT NULL DEFAULT 0,
  `report_status` enum('PENDING','CREATED') NOT NULL DEFAULT 'PENDING',
  `total` int(11) NOT NULL DEFAULT 0,
  `paid` int(11) NOT NULL DEFAULT 0,
  `discount` int(11) NOT NULL DEFAULT 0,
  `payable` int(11) NOT NULL DEFAULT 0,
  `balance` int(11) NOT NULL DEFAULT 0,
  `created_by` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_lab_invoice_tests`
--

CREATE TABLE IF NOT EXISTS `nxt_lab_invoice_tests` (
  `id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `invoice_uuid` varchar(50) NOT NULL,
  `test_description` varchar(255) NOT NULL,
  `report_datetime` datetime NOT NULL,
  `price` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_lab_report`
--

CREATE TABLE IF NOT EXISTS `nxt_lab_report` (
  `report_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `report_uuid` varchar(50) NOT NULL,
  `invoice_uuid` varchar(50) NOT NULL,
  `patient_mrid` varchar(50) NOT NULL,
  `patient_name` varchar(255) NOT NULL,
  `patient_mobile` varchar(15) NOT NULL,
  `test_results` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `remarks` text DEFAULT NULL,
  `report_delete` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_lab_test`
--

CREATE TABLE IF NOT EXISTS `nxt_lab_test` (
  `test_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `test_name` varchar(100) NOT NULL,
  `test_code` varchar(20) NOT NULL,
  `test_description` text DEFAULT NULL,
  `test_charges` decimal(10,2) NOT NULL,
  `sample_require` varchar(255) DEFAULT NULL,
  `report_completion` varchar(50) DEFAULT NULL,
  `category` varchar(100) NOT NULL,
  `performed_days` varchar(50) DEFAULT NULL,
  `report_title` varchar(255) DEFAULT NULL,
  `clinical_interpretation` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`clinical_interpretation`)),
  `status` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` varchar(100) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `note` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`note`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_medicine`
--

CREATE TABLE IF NOT EXISTS `nxt_medicine` (
  `id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `medicine_name` varchar(255) NOT NULL,
  UNIQUE KEY `unique_medicine_per_tenant` (`tenant_id`, `medicine_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_notification`
--

CREATE TABLE IF NOT EXISTS `nxt_notification` (
  `id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `type` varchar(100) NOT NULL,
  `description` text NOT NULL,
  `affected_table` varchar(255) DEFAULT NULL,
  `affected_id` varchar(255) NOT NULL,
  `user_id` varchar(255) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `meta_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_patient`
--

CREATE TABLE IF NOT EXISTS `nxt_patient` (
  `patient_id` int(10) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `patient_mrid` varchar(50) NOT NULL,
  `patient_name` varchar(100) NOT NULL,
  `patient_mobile` varchar(15) NOT NULL,
  `patient_cnic` varchar(15) DEFAULT NULL COMMENT 'Pakistani CNIC (13 digits) - National identifier',
  `guardian_cnic` varchar(15) DEFAULT NULL COMMENT 'Guardian CNIC for minors/children (optional field for family relationships)',
  `patient_password` varchar(100) NOT NULL DEFAULT '12345',
  `patient_email` varchar(100) DEFAULT NULL,
  `patient_gender` varchar(20) NOT NULL,
  `patient_dob` date DEFAULT NULL,
  `patient_age` varchar(255) NOT NULL,
  `patient_blood_group` varchar(10) DEFAULT NULL,
  `patient_address` varchar(255) DEFAULT NULL,
  `patient_delete` int(10) NOT NULL DEFAULT 0,
  `patient_last_login` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_patient_audit`
--

CREATE TABLE IF NOT EXISTS `nxt_patient_audit` (
  `audit_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `action` varchar(50) NOT NULL COMMENT 'Action performed (create, match, confirm, etc.)',
  `patient_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL COMMENT 'Patient data involved in the action' CHECK (json_valid(`patient_data`)),
  `matching_criteria` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Search criteria used for matching' CHECK (json_valid(`matching_criteria`)),
  `decision_made` varchar(100) DEFAULT NULL COMMENT 'Decision outcome (new_patient, reuse_mrid, user_confirmation, etc.)',
  `confidence_score` decimal(3,2) DEFAULT NULL COMMENT 'Matching confidence (0.00-1.00)',
  `user_id` int(11) DEFAULT NULL COMMENT 'User who made the decision',
  `session_id` varchar(100) DEFAULT NULL COMMENT 'Session identifier for tracking',
  `ip_address` varchar(45) DEFAULT NULL COMMENT 'Client IP address',
  `user_agent` text DEFAULT NULL COMMENT 'Browser/client user agent',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_patient_relationship`
--

CREATE TABLE IF NOT EXISTS `nxt_patient_relationship` (
  `relationship_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `primary_patient_id` int(11) NOT NULL COMMENT 'Main patient record',
  `related_patient_id` int(11) NOT NULL COMMENT 'Related patient record',
  `relationship_type` enum('family_member','duplicate_cnic','guardian_dependent') DEFAULT NULL,
  `relationship_detail` varchar(50) DEFAULT NULL COMMENT 'Specific relationship type (father, mother, son, etc.)',
  `relationship_notes` text DEFAULT NULL COMMENT 'Additional relationship details',
  `created_by` int(11) DEFAULT NULL COMMENT 'User who created the relationship',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ;

-- --------------------------------------------------------

-- 
--  Table structure for table `nxt_patient_match_audit`
-- 

CREATE TABLE IF NOT EXISTS `nxt_patient_match_audit` (
  `audit_id` INT NOT NULL AUTO_INCREMENT,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `session_id` VARCHAR(255) NULL,
  `user_id` INT NULL,
  `input_data` JSON NULL COMMENT 'Input patient data used for matching',
  `decision` ENUM('new_patient', 'exact_match', 'family_member', 'readmission', 'ambiguous') NOT NULL,
  `confidence_score` DECIMAL(3,2) NULL COMMENT 'Confidence score 0.00 to 1.00',
  `matched_patient_id` INT NULL COMMENT 'ID of matched patient if found',
  `match_reason` VARCHAR(255) NULL COMMENT 'Why this match was identified',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`audit_id`),
  INDEX `idx_tenant_session` (`tenant_id`, `session_id`),
  INDEX `idx_user_created` (`user_id`, `created_at`),
  INDEX `idx_matched_patient` (`matched_patient_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci 
COMMENT='Audit log for patient matching decisions';

-- ---------------------------------------------------------

--
-- Table structure for table `nxt_permission`
--

CREATE TABLE IF NOT EXISTS `nxt_permission` (
  `permission_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `permission_name` varchar(100) NOT NULL,
  `permission_alias` varchar(100) NOT NULL,
  `permission_description` text NOT NULL,
  `component_access` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `read_permission` tinyint(1) NOT NULL DEFAULT 0,
  `write_permission` tinyint(1) NOT NULL DEFAULT 0,
  `delete_permission` tinyint(1) NOT NULL DEFAULT 0,
  `permission_status` int(11) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  UNIQUE KEY `unique_permission_per_tenant` (`tenant_id`, `permission_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_prescriptions`
--

CREATE TABLE IF NOT EXISTS `nxt_prescriptions` (
  `prescription_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `slip_uuid` varchar(50) DEFAULT NULL,
  `patient_mrid` varchar(50) NOT NULL,
  `patient_mobile` varchar(100) NOT NULL,
  `patient_name` varchar(255) NOT NULL,
  `department_alias` varchar(255) DEFAULT NULL,
  `doctor_alias` varchar(255) NOT NULL,
  `status` enum('PENDING','CREATED') NOT NULL DEFAULT 'PENDING',
  `symptoms` text DEFAULT NULL,
  `diagnosis` text DEFAULT NULL,
  `ai_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `created_by` varchar(255) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_print_design`
--

CREATE TABLE IF NOT EXISTS `nxt_print_design` (
  `id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `identifier` varchar(100) NOT NULL,
  `header_logo` longtext DEFAULT NULL,
  `header_title` varchar(255) NOT NULL,
  `header_description` varchar(255) DEFAULT NULL,
  `address` varchar(255) NOT NULL,
  `phone` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `email` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `website` varchar(100) DEFAULT NULL,
  `footer_title` varchar(255) DEFAULT NULL,
  `footer_description` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_report_footer`
--

CREATE TABLE IF NOT EXISTS `nxt_report_footer` (
  `footer_id` int(10) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `footer_title` varchar(255) DEFAULT NULL,
  `footer_details` text DEFAULT NULL,
  `footer_no` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_room`
--

CREATE TABLE IF NOT EXISTS `nxt_room` (
  `room_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `room_name` varchar(100) NOT NULL,
  `room_alias` varchar(100) NOT NULL,
  `room_description` text DEFAULT NULL,
  `room_rate` int(10) NOT NULL COMMENT 'Per day room charges',
  `room_status` int(10) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  `room_category` varchar(50) DEFAULT NULL COMMENT 'FK to nxt_category.category_alias for room type',
  `room_floor` varchar(20) DEFAULT NULL COMMENT 'Floor location of the room',
  `room_wing` varchar(50) DEFAULT NULL COMMENT 'Wing/section of the hospital',
  `total_beds` int(11) DEFAULT 1 COMMENT 'Total bed capacity in this room',
  `occupied_beds` int(11) DEFAULT 0 COMMENT 'Currently occupied beds'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Hospital rooms with multi-bed capacity and category tracking';

-- --------------------------------------------------------

--
-- Table structure for table `nxt_segment`
--

CREATE TABLE IF NOT EXISTS `nxt_segment` (
  `segment_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `segment_name` varchar(100) NOT NULL,
  `segment_alias` varchar(100) NOT NULL,
  `segment_filter` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `segment_description` text DEFAULT NULL,
  `contact_count` int(11) DEFAULT 0,
  `segment_status` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_service`
--

CREATE TABLE IF NOT EXISTS `nxt_service` (
  `service_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `service_name` varchar(100) NOT NULL,
  `service_alias` varchar(100) NOT NULL,
  `service_description` text DEFAULT NULL,
  `service_rate` int(10) NOT NULL,
  `service_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  `pct_code` varchar(20) DEFAULT NULL COMMENT 'Pakistan Customs Tariff code for FBR compliance',
  UNIQUE KEY `unique_service_per_tenant` (`tenant_id`, `service_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_slip`
--

CREATE TABLE IF NOT EXISTS `nxt_slip` (
  `slip_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `slip_uuid` varchar(50) NOT NULL,
  `slip_mrid` varchar(50) NOT NULL,
  `slip_patient_name` varchar(100) NOT NULL,
  `slip_patient_mobile` varchar(15) NOT NULL,
  `slip_patient_cnic` varchar(15) DEFAULT NULL COMMENT 'Copy of patient CNIC for quick lookup during visits',
  `slip_disposal` varchar(50) NOT NULL,
  `slip_department` varchar(50) DEFAULT NULL,
  `slip_doctor` varchar(50) NOT NULL,
  `slip_appointment` varchar(20) DEFAULT 'walk_in',
  `slip_payment_mode` varchar(50) DEFAULT NULL,
  `slip_payment_detail` varchar(50) DEFAULT NULL,
  `slip_fee` int(10) DEFAULT NULL,
  `slip_discount` int(10) DEFAULT NULL,
  `slip_payable` int(10) DEFAULT NULL,
  `slip_paid` int(10) DEFAULT NULL,
  `slip_balance` int(10) DEFAULT NULL,
  `slip_procedure` varchar(255) DEFAULT NULL,
  `slip_service` longtext DEFAULT NULL,
  `slip_type` varchar(100) NOT NULL,
  `admission_date` datetime DEFAULT NULL COMMENT 'Date and time when patient was admitted (for indoor/admission slip types)',
  `slip_delete` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  `slip_tax_details` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'JSON array of applied taxes for audit trail' CHECK (json_valid(`slip_tax_details`)),
  `fbr_invoice_number` varchar(255) DEFAULT NULL COMMENT 'FBR-generated unique invoice number',
  `fbr_qr_code_url` text DEFAULT NULL COMMENT 'FBR QR code URL for invoice verification',
  `fbr_sync_status` enum('pending','synced','failed','skipped','disabled') NOT NULL DEFAULT 'pending' COMMENT 'FBR synchronization status',
  `fbr_response_message` text DEFAULT NULL COMMENT 'FBR API response message for debugging',
  `fbr_synced_at` datetime DEFAULT NULL COMMENT 'Timestamp when synced with FBR',
  `fbr_retry_count` int(11) DEFAULT 0 COMMENT 'Number of FBR sync retry attempts',
  `room_id` int(11) DEFAULT NULL COMMENT 'Room assigned for INDOOR slips',
  `bed_id` int(11) DEFAULT NULL COMMENT 'Bed assigned at admission',
  `admission_notes` text DEFAULT NULL COMMENT 'Admission notes, patient condition, special instructions for indoor patients',
  `estimated_duration_days` int(11) DEFAULT NULL COMMENT 'Estimated duration of stay in days for indoor patients',
  `procedure_type` enum('planned','unplanned') DEFAULT NULL COMMENT 'Type of procedure: planned (scheduled) or unplanned (emergency)',
  `procedure_reason` text DEFAULT NULL COMMENT 'Reason/details: urgency for unplanned, additional info for planned procedures',
  `is_readmission` tinyint(1) DEFAULT 0 COMMENT 'Flag: 1 if this is a readmission, 0 if new admission',
  `readmission_reason` varchar(255) DEFAULT NULL COMMENT 'Reason for readmission (complication, treatment_continuation, etc.)',
  `relationship_context` varchar(50) DEFAULT NULL COMMENT 'Context of patient relationship (readmission, family_member, etc.)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci COMMENT='Patient slips. slip_type="INDOOR" with room/bed for admissions';

-- --------------------------------------------------------

--
-- Table structure for table `nxt_slip_type`
--

CREATE TABLE IF NOT EXISTS `nxt_slip_type` (
  `slip_type_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `slip_type_name` varchar(100) NOT NULL,
  `slip_type_alias` varchar(100) NOT NULL,
  `fields` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`fields`)),
  `isBill` tinyint(1) NOT NULL,
  `slip_type_status` int(10) NOT NULL DEFAULT 1,
  `slip_type_description` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  `enable_tax` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 to enable tax calculation',
  `prices_are_tax_inclusive` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 if entered fees already include tax',
  `print_layout` ENUM('thermal', 'a4') NOT NULL DEFAULT 'thermal' COMMENT 'Slip print layout: thermal (80mm) or a4 (210mm)',
  `bill_print_layout` ENUM('thermal', 'a4') NULL DEFAULT NULL COMMENT 'Bill print layout: thermal (80mm) or a4 (210mm) - only for slip types with isBill=1',
  `enable_fbr_sync` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'Enable FBR synchronization for this slip type',
  `fbr_invoice_type` tinyint(1) NOT NULL DEFAULT 1 COMMENT '1=Fiscal, 2=Non-Fiscal invoice type for FBR',
  `enable_prescription` tinyint(1) NOT NULL DEFAULT 0 COMMENT '1 to enable prescription records auto-creation',
  UNIQUE KEY `unique_slip_type_per_tenant` (`tenant_id`, `slip_type_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_supplier`
--

CREATE TABLE IF NOT EXISTS `nxt_supplier` (
  `supplier_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `supplier_name` varchar(255) NOT NULL,
  `supplier_alias` varchar(255) NOT NULL,
  `supplier_contact` varchar(50) DEFAULT NULL,
  `supplier_email` varchar(100) DEFAULT NULL,
  `supplier_address` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_tax_settings`
--

CREATE TABLE IF NOT EXISTS `nxt_tax_settings` (
  `tax_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
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
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_test_component`
--

CREATE TABLE IF NOT EXISTS `nxt_test_component` (
  `component_id` int(10) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `component_title` varchar(100) DEFAULT NULL,
  `component_ranges` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`component_ranges`)),
  `test_code` varchar(100) NOT NULL,
  `created_by` varchar(50) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_text_message`
--

CREATE TABLE IF NOT EXISTS `nxt_text_message` (
  `message_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `message_name` varchar(100) NOT NULL,
  `message_alias` varchar(100) NOT NULL,
  `message_text` text NOT NULL,
  `media_url` varchar(255) DEFAULT NULL COMMENT 'URL of attached image/media',
  `media_type` enum('image','video','document','none') DEFAULT 'none',
  `variables` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Available variables in message_text' CHECK (json_valid(`variables`)),
  `message_status` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_user`
--

CREATE TABLE IF NOT EXISTS `nxt_user` (
  `user_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `user_name` varchar(100) NOT NULL,
  `user_email` varchar(50) DEFAULT NULL,
  `user_mobile` varchar(15) DEFAULT NULL,
  `user_username` varchar(50) NOT NULL,
  `user_password` varchar(100) NOT NULL,
  `user_status` int(10) NOT NULL DEFAULT 1,
  `user_permission` varchar(100) NOT NULL,
  `user_photo` varchar(255) DEFAULT NULL,
  `user_address` varchar(255) DEFAULT NULL,
  `user_cnic` varchar(255) DEFAULT NULL,
  `user_degree` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`user_degree`)),
  `user_experience` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`user_experience`)),
  `user_cnic_front` varchar(255) DEFAULT NULL,
  `user_cnic_back` varchar(255) DEFAULT NULL,
  `user_salary` decimal(10,2) DEFAULT NULL,
  `user_last_login` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(20) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_users`
--

CREATE TABLE IF NOT EXISTS `nxt_users` (
  `user_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `user_name` varchar(100) NOT NULL,
  `user_alias` varchar(100) DEFAULT NULL,
  `user_email` varchar(50) DEFAULT NULL,
  `user_mobile` varchar(15) DEFAULT NULL,
  `user_photo` varchar(255) DEFAULT NULL,
  `user_address` varchar(255) DEFAULT NULL,
  `user_cnic` varchar(255) DEFAULT NULL,
  `reports_to` varchar(100) DEFAULT NULL,
  `direct_reports` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`direct_reports`)),
  `user_password` varchar(100) NOT NULL,
  `user_status` int(10) NOT NULL DEFAULT 1,
  `user_permission` varchar(100) NOT NULL,
  `user_title` varchar(255) DEFAULT NULL,
  `user_department_alias` varchar(100) DEFAULT NULL,
  `user_type_alias` varchar(100) DEFAULT NULL,
  `user_degree` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`user_degree`)),
  `user_experience` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`user_experience`)),
  `user_cnic_front` varchar(255) DEFAULT NULL,
  `user_cnic_back` varchar(255) DEFAULT NULL,
  `user_salary` decimal(10,2) DEFAULT NULL,
  `user_share` decimal(10,2) DEFAULT NULL,
  `user_last_login` datetime DEFAULT NULL,
  `is_deleted` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_user_available_leaves`
--

CREATE TABLE IF NOT EXISTS `nxt_user_available_leaves` (
  `available_leave_id` int(10) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `user_id` int(10) NOT NULL,
  `leave_alias` varchar(100) NOT NULL,
  `available_balance` int(10) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_user_leave`
--

CREATE TABLE IF NOT EXISTS `nxt_user_leave` (
  `leave_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `user_id` int(11) NOT NULL,
  `leave_type` enum('earn','sick','annual','compensation') NOT NULL DEFAULT 'earn',
  `leave_start_date` date NOT NULL,
  `leave_end_date` date NOT NULL,
  `leave_count` decimal(10,2) NOT NULL,
  `leave_comment` text DEFAULT NULL,
  `leave_remarks` text DEFAULT NULL,
  `leave_status` enum('approved','pending','rejected') NOT NULL DEFAULT 'pending',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `nxt_user_test`
--

CREATE TABLE IF NOT EXISTS `nxt_user_test` (
  `user_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `user_type` enum('doctor','nurse','staff','admin') NOT NULL,
  `user_name` varchar(100) NOT NULL,
  `user_alias` varchar(100) DEFAULT NULL,
  `user_username` varchar(50) NOT NULL,
  `user_email` varchar(50) DEFAULT NULL,
  `user_mobile` varchar(15) DEFAULT NULL,
  `user_photo` varchar(255) DEFAULT NULL,
  `user_address` varchar(255) DEFAULT NULL,
  `user_cnic` varchar(255) DEFAULT NULL,
  `reports_to` int(11) DEFAULT NULL,
  `direct_reports_to` int(11) DEFAULT NULL,
  `user_password` varchar(100) NOT NULL,
  `user_status` int(10) NOT NULL DEFAULT 1,
  `user_permission` varchar(100) NOT NULL,
  `user_title` varchar(255) DEFAULT NULL,
  `user_department_alias` varchar(100) DEFAULT NULL,
  `user_type_alias` varchar(100) DEFAULT NULL,
  `user_degree` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`user_degree`)),
  `user_experience` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`user_experience`)),
  `user_cnic_front` varchar(255) DEFAULT NULL,
  `user_cnic_back` varchar(255) DEFAULT NULL,
  `user_salary` decimal(10,2) DEFAULT NULL,
  `user_share` decimal(10,2) DEFAULT NULL,
  `user_last_login` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `prescription_items`
--

CREATE TABLE IF NOT EXISTS `prescription_items` (
  `item_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `prescription_id` int(11) NOT NULL,
  `medicine_name` varchar(255) DEFAULT NULL,
  `dosage` text DEFAULT NULL,
  `frequency` varchar(50) DEFAULT NULL,
  `duration` varchar(100) DEFAULT NULL,
  `special_instructions` text DEFAULT NULL,
  `category` varchar(50) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `interaction_warnings` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(255) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `prescription_other`
--

CREATE TABLE IF NOT EXISTS `prescription_other` (
  `id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `prescription_id` int(11) NOT NULL,
  `referral_consultant` varchar(100) DEFAULT NULL,
  `referral_note` text DEFAULT NULL,
  `disposal` varchar(50) DEFAULT NULL,
  `disposal_note` text DEFAULT NULL,
  `followup_date` datetime DEFAULT NULL,
  `followup_note` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(255) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `prescription_vitals`
--

CREATE TABLE IF NOT EXISTS `prescription_vitals` (
  `vital_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `prescription_id` int(11) NOT NULL,
  `pulse` varchar(50) DEFAULT NULL,
  `blood_pressure` varchar(50) DEFAULT NULL,
  `temperature` varchar(50) DEFAULT NULL,
  `respiratory_rate` varchar(50) DEFAULT NULL,
  `height` varchar(50) DEFAULT NULL,
  `weight` varchar(50) DEFAULT NULL,
  `bmi` varchar(100) DEFAULT NULL,
  `ofc` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(255) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `recentactivity`
--

CREATE TABLE IF NOT EXISTS `recentactivity` (
  `activity_id` int(11) NOT NULL,
  `tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
  `admin_user` varchar(100) DEFAULT NULL,
  `action_title` varchar(50) NOT NULL,
  `action_description` text DEFAULT NULL,
  `table_affected` varchar(255) DEFAULT NULL,
  `affected_id` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_campaign_analytics`
-- (See below for the actual view)
--
CREATE TABLE IF NOT EXISTS `vw_campaign_analytics` (
`campaign_id` int(11),
`tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
`campaign_name` varchar(100),
`campaign_type` enum('bulk','triggered','scheduled','immediate'),
`campaign_channel` enum('whatsapp','email','sms','push'),
`campaign_status` enum('draft','scheduled','processing','completed','failed','paused'),
`total_triggered` bigint(21),
`successful_sends` decimal(22,0),
`failed_sends` decimal(22,0),
`pending_sends` decimal(22,0),
`success_rate` decimal(28,2),
`first_trigger` timestamp,
`last_trigger` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_daily_readmission_summary`
-- (See below for the actual view)
--
CREATE TABLE IF NOT EXISTS `v_daily_readmission_summary` (
`admission_date` date,
`tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
`total_admissions` bigint(21),
`readmission_count` decimal(25,0),
`readmission_rate` decimal(31,2),
`slip_type` varchar(100),
`slip_department` varchar(20),
`slip_doctor` varchar(20)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `v_readmission_analytics`
-- (See below for the actual view)
--
CREATE TABLE IF NOT EXISTS `v_readmission_analytics` (
`slip_id` int(11),
`tenant_id` VARCHAR(50) NOT NULL DEFAULT 'system_default_tenant',
`slip_uuid` varchar(50),
`slip_mrid` varchar(50),
`slip_patient_name` varchar(100),
`slip_patient_cnic` varchar(15),
`created_at` datetime,
`slip_type` varchar(100),
`slip_department` varchar(20),
`slip_doctor` varchar(20),
`is_readmission` tinyint(1),
`readmission_reason` varchar(255)
);

-- --------------------------------------------------------

--
-- Structure for view `vw_campaign_analytics`
--
DROP TABLE IF EXISTS `vw_campaign_analytics`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_campaign_analytics`  AS SELECT `c`.`campaign_id` AS `campaign_id`, `c`.`campaign_name` AS `campaign_name`, `c`.`campaign_type` AS `campaign_type`, `c`.`campaign_channel` AS `campaign_channel`, `c`.`campaign_status` AS `campaign_status`, count(`cq`.`queue_id`) AS `total_triggered`, sum(case when `cq`.`status` = 'sent' then 1 else 0 end) AS `successful_sends`, sum(case when `cq`.`status` = 'failed' then 1 else 0 end) AS `failed_sends`, sum(case when `cq`.`status` = 'pending' then 1 else 0 end) AS `pending_sends`, round(sum(case when `cq`.`status` = 'sent' then 1 else 0 end) / nullif(count(`cq`.`queue_id`),0) * 100,2) AS `success_rate`, min(`cq`.`created_at`) AS `first_trigger`, max(`cq`.`created_at`) AS `last_trigger` FROM (`nxt_campaign` `c` left join `nxt_campaign_queue` `cq` on(`c`.`campaign_id` = `cq`.`campaign_id`)) WHERE `c`.`campaign_type` = 'triggered' GROUP BY `c`.`campaign_id`, `c`.`campaign_name`, `c`.`campaign_type`, `c`.`campaign_channel`, `c`.`campaign_status` ;

-- --------------------------------------------------------

--
-- Structure for view `v_daily_readmission_summary`
--
DROP TABLE IF EXISTS `v_daily_readmission_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_daily_readmission_summary`  AS SELECT cast(`s`.`created_at` as date) AS `admission_date`, count(`s`.`slip_id`) AS `total_admissions`, sum(`s`.`is_readmission`) AS `readmission_count`, round(sum(`s`.`is_readmission`) / count(`s`.`slip_id`) * 100,2) AS `readmission_rate`, `s`.`slip_type` AS `slip_type`, `s`.`slip_department` AS `slip_department`, `s`.`slip_doctor` AS `slip_doctor` FROM `nxt_slip` AS `s` WHERE `s`.`created_at` >= current_timestamp() - interval 30 day GROUP BY cast(`s`.`created_at` as date), `s`.`slip_type`, `s`.`slip_department`, `s`.`slip_doctor` ORDER BY cast(`s`.`created_at` as date) DESC ;

-- --------------------------------------------------------

--
-- Structure for view `v_readmission_analytics`
--
DROP TABLE IF EXISTS `v_readmission_analytics`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_readmission_analytics`  AS SELECT `s`.`slip_id` AS `slip_id`, `s`.`slip_uuid` AS `slip_uuid`, `s`.`slip_mrid` AS `slip_mrid`, `s`.`slip_patient_name` AS `slip_patient_name`, `s`.`slip_patient_cnic` AS `slip_patient_cnic`, `s`.`created_at` AS `created_at`, `s`.`slip_type` AS `slip_type`, `s`.`slip_department` AS `slip_department`, `s`.`slip_doctor` AS `slip_doctor`, `s`.`is_readmission` AS `is_readmission`, `s`.`readmission_reason` AS `readmission_reason` FROM `nxt_slip` AS `s` WHERE `s`.`created_at` >= current_timestamp() - interval 365 day ORDER BY `s`.`created_at` DESC ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `ai_feedback`
--
ALTER TABLE `ai_feedback`
  ADD PRIMARY KEY (`feedback_id`);

--
-- Indexes for table `ai_suggestions`
--
ALTER TABLE `ai_suggestions`
  ADD PRIMARY KEY (`suggestion_id`);

--
-- Indexes for table `nxt_appointment`
--
ALTER TABLE `nxt_appointment`
  ADD PRIMARY KEY (`appointment_id`),
  ADD UNIQUE KEY `appointment_uuid` (`appointment_uuid`),
  ADD KEY `fk_appointment_patient_mrid` (`appointment_patient_mrid`),
  ADD KEY `fk_appointment_type_uuid` (`appointment_type_alias`),
  ADD KEY `fk_appointment_department_uuid` (`appointment_department_alias`),
  ADD KEY `fk_appointment_doctor_uuid` (`appointment_doctor_alias`);

ALTER TABLE `nxt_appointment` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_date` (`tenant_id`, `appointment_date`),
  ADD INDEX `idx_tenant_status` (`tenant_id`, `appointment_status`);

--
-- Indexes for table `nxt_bed`
--
ALTER TABLE `nxt_bed`
  ADD PRIMARY KEY (`bed_id`),
  ADD UNIQUE KEY `unique_bed_number` (`bed_number`),
  ADD KEY `idx_room_id` (`room_id`),
  ADD KEY `idx_bed_status` (`bed_status`),
  ADD KEY `idx_current_patient` (`current_patient_mrid`),
  ADD KEY `idx_current_bill` (`current_bill_uuid`),
  ADD KEY `idx_room_status` (`room_id`,`bed_status`);

ALTER TABLE `nxt_bed` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_status` (`tenant_id`, `bed_status`);

--
-- Indexes for table `nxt_bed_history`
--
ALTER TABLE `nxt_bed_history`
  ADD PRIMARY KEY (`history_id`),
  ADD KEY `idx_bed_history` (`bed_id`,`action_timestamp`),
  ADD KEY `idx_patient_history` (`patient_mrid`,`action_timestamp`),
  ADD KEY `idx_bill_history` (`bill_uuid`);

ALTER TABLE `nxt_bed_history` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

--
-- Indexes for table `nxt_bill`
--
ALTER TABLE `nxt_bill`
  ADD PRIMARY KEY (`bill_id`),
  ADD UNIQUE KEY `unique_bill_uuid` (`bill_uuid`),
  ADD KEY `idx_admission_duration_hours` (`admission_duration_hours`),
  ADD KEY `idx_discharge_date` (`discharge_date`),
  ADD KEY `idx_fbr_sync_status_bill` (`fbr_sync_status`),
  ADD KEY `idx_fbr_synced_at_bill` (`fbr_synced_at`),
  ADD KEY `idx_bill_room_bed` (`room_id`,`bed_id`),
  ADD KEY `idx_bill_indoor_active` (`bill_type`,`discharge_date`),
  ADD KEY `idx_bill_type_status` (`bill_type`,`bill_delete`,`discharge_date`),
  ADD KEY `fk_bill_bed` (`bed_id`),
  ADD KEY `idx_bill_referral` (`is_referral_case`,`referral_date`),
  ADD KEY `idx_bill_death` (`is_death_case`,`death_date`),
  ADD KEY `idx_bill_death_duration` (`death_duration_hours`),
  ADD KEY `idx_bill_outcome` (`is_referral_case`,`is_death_case`,`created_at`),
  ADD KEY `idx_bill_cnic` (`patient_cnic`);

ALTER TABLE `nxt_bill` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_uuid` (`tenant_id`, `bill_uuid`);

--
-- Indexes for table `nxt_bootstrap_status`
--
ALTER TABLE `nxt_bootstrap_status`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_component_status` (`component`,`status`);

--
-- Indexes for table `nxt_campaign`
--
ALTER TABLE `nxt_campaign`
  ADD PRIMARY KEY (`campaign_id`),
  ADD UNIQUE KEY `unique_campaign_per_tenant` (`tenant_id`, `campaign_alias`),
  ADD KEY `campaign_segment` (`campaign_segment`),
  ADD KEY `campaign_message` (`campaign_message`),
  ADD KEY `idx_campaign_status` (`campaign_status`),
  ADD KEY `idx_scheduled_at` (`scheduled_at`),
  ADD KEY `idx_campaign_channel` (`campaign_channel`),
  ADD KEY `idx_campaign_type` (`campaign_type`),
  ADD KEY `idx_campaign_status_type` (`campaign_status`,`campaign_type`),
  ADD KEY `idx_campaign_type_status` (`campaign_type`,`campaign_status`),
  ADD KEY `idx_trigger_event` (`trigger_event`);

--
-- Indexes for table `nxt_campaign_log`
--
ALTER TABLE `nxt_campaign_log`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_campaign_contact` (`campaign_id`,`contact_id`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `nxt_campaign_queue`
--
ALTER TABLE `nxt_campaign_queue`
  ADD PRIMARY KEY (`queue_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_scheduled` (`scheduled_at`),
  ADD KEY `idx_campaign_queue` (`campaign_id`,`status`),
  ADD KEY `idx_contact_channel` (`contact_info`,`channel_type`);

--
-- Indexes for table `nxt_campaign_triggers`
--
ALTER TABLE `nxt_campaign_triggers`
  ADD PRIMARY KEY (`trigger_id`),
  ADD KEY `idx_trigger_event` (`trigger_event`),
  ADD KEY `idx_campaign_trigger` (`campaign_id`,`trigger_event`);

--
-- Indexes for table `nxt_category`
--
ALTER TABLE `nxt_category`
  ADD PRIMARY KEY (`category_id`),
  ADD UNIQUE KEY `unique_category_per_tenant` (`tenant_id`, `category_alias`);

--
-- Indexes for table `nxt_category_type`
--
ALTER TABLE `nxt_category_type`
  ADD PRIMARY KEY (`type_id`);

--
-- Indexes for table `nxt_daily_expenses`
--
ALTER TABLE `nxt_daily_expenses`
  ADD PRIMARY KEY (`expense_id`);

--
-- Indexes for table `nxt_db_backup`
--
ALTER TABLE `nxt_db_backup`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `nxt_department`
--
ALTER TABLE `nxt_department`
  ADD PRIMARY KEY (`department_id`),
  ADD UNIQUE KEY `unique_department_name_per_tenant` (`tenant_id`, `department_name`),
  ADD UNIQUE KEY `unique_department_per_tenant` (`tenant_id`, `department_alias`);

ALTER TABLE `nxt_department` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_alias` (`tenant_id`, `department_alias`);

--
-- Indexes for table `nxt_doctor`
--
ALTER TABLE `nxt_doctor`
  ADD PRIMARY KEY (`doctor_id`),
  ADD UNIQUE KEY `doctor_alias` (`doctor_alias`),
  ADD KEY `fk_doctor_department_uuid` (`doctor_department_alias`),
  ADD KEY `fk_doctor_type_uuid` (`doctor_type_alias`);

ALTER TABLE `nxt_doctor` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_alias` (`tenant_id`, `doctor_alias`);

--
-- Indexes for table `nxt_doctor_schedule`
--
ALTER TABLE `nxt_doctor_schedule`
  ADD PRIMARY KEY (`schedule_id`);

ALTER TABLE `nxt_doctor_schedule` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_doctor_day` (`tenant_id`, `doctor_alias`, `schedule_day`);

--
-- Indexes for table `nxt_fbr_config`
--
ALTER TABLE `nxt_fbr_config`
  ADD PRIMARY KEY (`fbr_config_id`);

--
-- Indexes for table `nxt_fbr_sync_log`
--
ALTER TABLE `nxt_fbr_sync_log`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_invoice_type_id` (`invoice_type`,`invoice_id`),
  ADD KEY `idx_sync_status` (`sync_status`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `nxt_inventory`
--
ALTER TABLE `nxt_inventory`
  ADD PRIMARY KEY (`item_id`);

--
-- Indexes for table `nxt_lab_invoice`
--
ALTER TABLE `nxt_lab_invoice`
  ADD PRIMARY KEY (`invoice_id`);

--
-- Indexes for table `nxt_lab_invoice_tests`
--
ALTER TABLE `nxt_lab_invoice_tests`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `nxt_lab_report`
--
ALTER TABLE `nxt_lab_report`
  ADD PRIMARY KEY (`report_id`);

--
-- Indexes for table `nxt_lab_test`
--
ALTER TABLE `nxt_lab_test`
  ADD PRIMARY KEY (`test_id`),
  ADD UNIQUE KEY `unique_test_per_tenant` (`tenant_id`, `test_code`);

--
-- Indexes for table `nxt_medicine`
--
ALTER TABLE `nxt_medicine`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `nxt_notification`
--
ALTER TABLE `nxt_notification`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `nxt_patient`
--
ALTER TABLE `nxt_patient`
  ADD PRIMARY KEY (`patient_id`),
  ADD UNIQUE KEY `patient_mrid` (`patient_mrid`),
  ADD KEY `idx_patient_mrid` (`patient_mrid`),
  ADD KEY `idx_patient_cnic` (`patient_cnic`),
  ADD KEY `idx_patient_guardian_cnic` (`guardian_cnic`);

ALTER TABLE `nxt_patient`
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_mrid` (`tenant_id`, `patient_mrid`),
  ADD INDEX `idx_tenant_mobile` (`tenant_id`, `patient_mobile`);

--
-- Indexes for table `nxt_patient_audit`
--
ALTER TABLE `nxt_patient_audit`
  ADD PRIMARY KEY (`audit_id`),
  ADD KEY `idx_audit_action` (`action`),
  ADD KEY `idx_audit_user` (`user_id`),
  ADD KEY `idx_audit_created` (`created_at`),
  ADD KEY `idx_audit_session` (`session_id`);

--
-- Indexes for table `nxt_patient_relationship`
--
ALTER TABLE `nxt_patient_relationship`
  ADD PRIMARY KEY (`relationship_id`),
  ADD UNIQUE KEY `unique_relationship` (`primary_patient_id`,`related_patient_id`,`relationship_type`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `idx_relationship_primary` (`primary_patient_id`),
  ADD KEY `idx_relationship_related` (`related_patient_id`),
  ADD KEY `idx_relationship_type` (`relationship_type`),
  ADD KEY `idx_relationship_detail` (`relationship_detail`);

--
-- Indexes for table `nxt_permission`
--
ALTER TABLE `nxt_permission`
  ADD PRIMARY KEY (`permission_id`);

--
-- Indexes for table `nxt_prescriptions`
--
ALTER TABLE `nxt_prescriptions`
  ADD PRIMARY KEY (`prescription_id`);

ALTER TABLE `nxt_prescriptions` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_slip` (`tenant_id`, `slip_uuid`);

--
-- Indexes for table `nxt_print_design`
--
ALTER TABLE `nxt_print_design`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `nxt_report_footer`
--
ALTER TABLE `nxt_report_footer`
  ADD PRIMARY KEY (`footer_id`);

--
-- Indexes for table `nxt_room`
--
ALTER TABLE `nxt_room`
  ADD PRIMARY KEY (`room_id`),
  ADD KEY `idx_room_category` (`room_category`),
  ADD KEY `idx_room_floor` (`room_floor`),
  ADD KEY `idx_room_availability` (`total_beds`,`occupied_beds`);

ALTER TABLE `nxt_room` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

--
-- Indexes for table `nxt_segment`
--
ALTER TABLE `nxt_segment`
  ADD PRIMARY KEY (`segment_id`),
  ADD UNIQUE KEY `unique_segment_per_tenant` (`tenant_id`, `segment_alias`),
  ADD KEY `idx_segment_status` (`segment_status`);

--
-- Indexes for table `nxt_service`
--
ALTER TABLE `nxt_service`
  ADD PRIMARY KEY (`service_id`);

--
-- Indexes for table `nxt_slip`
--
ALTER TABLE `nxt_slip`
  ADD PRIMARY KEY (`slip_id`),
  ADD KEY `idx_fbr_sync_status` (`fbr_sync_status`),
  ADD KEY `idx_fbr_synced_at` (`fbr_synced_at`),
  ADD KEY `idx_slip_room_bed` (`room_id`,`bed_id`),
  ADD KEY `idx_slip_indoor` (`slip_type`,`admission_date`),
  ADD KEY `fk_slip_bed` (`bed_id`),
  ADD KEY `idx_estimated_duration` (`estimated_duration_days`),
  ADD KEY `idx_procedure_type_admission` (`procedure_type`,`admission_date`),
  ADD KEY `idx_slip_cnic` (`slip_patient_cnic`),
  ADD KEY `idx_slip_readmission` (`is_readmission`),
  ADD KEY `idx_slip_cnic_created` (`slip_patient_cnic`,`created_at`),
  ADD KEY `idx_slip_cnic_disposal` (`slip_patient_cnic`,`slip_disposal`);

ALTER TABLE `nxt_slip` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_uuid` (`tenant_id`, `slip_uuid`),
  ADD INDEX `idx_tenant_mrid` (`tenant_id`, `slip_mrid`),
  ADD INDEX `idx_tenant_date` (`tenant_id`, `created_at`);

--
-- Indexes for table `nxt_slip_type`
--
ALTER TABLE `nxt_slip_type`
  ADD PRIMARY KEY (`slip_type_id`);

--
-- Indexes for table `nxt_supplier`
--
ALTER TABLE `nxt_supplier`
  ADD PRIMARY KEY (`supplier_id`);

--
-- Indexes for table `nxt_tax_settings`
--
ALTER TABLE `nxt_tax_settings`
  ADD PRIMARY KEY (`tax_id`),
  ADD UNIQUE KEY `unique_tax_per_tenant` (`tenant_id`, `tax_alias`),
  ADD UNIQUE KEY `unique_tax_code_per_tenant` (`tenant_id`, `tax_code`),
  ADD KEY `idx_slip_type` (`apply_to_slip_type`),
  ADD KEY `idx_tax_status` (`tax_status`),
  ADD KEY `idx_effective_dates` (`effective_from`,`effective_to`);

--
-- Indexes for table `nxt_test_component`
--
ALTER TABLE `nxt_test_component`
  ADD PRIMARY KEY (`component_id`),
  ADD KEY `idx_test_component_test_code` (`test_code`);

--
-- Indexes for table `nxt_text_message`
--
ALTER TABLE `nxt_text_message`
  ADD PRIMARY KEY (`message_id`),
  ADD UNIQUE KEY `unique_message_per_tenant` (`tenant_id`, `message_alias`);

--
-- Indexes for table `nxt_user`
--
ALTER TABLE `nxt_user`
  ADD PRIMARY KEY (`user_id`);

ALTER TABLE `nxt_user` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_username` (`tenant_id`, `user_username`),
  ADD INDEX `idx_tenant_email` (`tenant_id`, `user_email`);

--
-- Indexes for table `nxt_users`
--
ALTER TABLE `nxt_users`
  ADD PRIMARY KEY (`user_id`);

--
-- Indexes for table `nxt_user_available_leaves`
--
ALTER TABLE `nxt_user_available_leaves`
  ADD PRIMARY KEY (`available_leave_id`);

--
-- Indexes for table `nxt_user_leave`
--
ALTER TABLE `nxt_user_leave`
  ADD PRIMARY KEY (`leave_id`);

--
-- Indexes for table `nxt_user_test`
--
ALTER TABLE `nxt_user_test`
  ADD PRIMARY KEY (`user_id`);

--
-- Indexes for table `prescription_items`
--
ALTER TABLE `prescription_items`
  ADD PRIMARY KEY (`item_id`);

ALTER TABLE `prescription_items` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_prescription` (`tenant_id`, `prescription_id`);

--
-- Indexes for table `prescription_other`
--
ALTER TABLE `prescription_other`
  ADD PRIMARY KEY (`id`);

ALTER TABLE `prescription_other` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_prescription` (`tenant_id`, `prescription_id`);

--
-- Indexes for table `prescription_vitals`
--
ALTER TABLE `prescription_vitals`
  ADD PRIMARY KEY (`vital_id`);

ALTER TABLE `prescription_vitals` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_prescription` (`tenant_id`, `prescription_id`);

--
-- Indexes for table `recentactivity`
--
ALTER TABLE `recentactivity`
  ADD PRIMARY KEY (`activity_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `ai_feedback`
--
ALTER TABLE `ai_feedback`
  MODIFY `feedback_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `ai_suggestions`
--
ALTER TABLE `ai_suggestions`
  MODIFY `suggestion_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_appointment`
--
ALTER TABLE `nxt_appointment`
  MODIFY `appointment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_bed`
--
ALTER TABLE `nxt_bed`
  MODIFY `bed_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_bed_history`
--
ALTER TABLE `nxt_bed_history`
  MODIFY `history_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_bill`
--
ALTER TABLE `nxt_bill`
  MODIFY `bill_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_bootstrap_status`
--
ALTER TABLE `nxt_bootstrap_status`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_campaign`
--
ALTER TABLE `nxt_campaign`
  MODIFY `campaign_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_campaign_log`
--
ALTER TABLE `nxt_campaign_log`
  MODIFY `log_id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_campaign_queue`
--
ALTER TABLE `nxt_campaign_queue`
  MODIFY `queue_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_campaign_triggers`
--
ALTER TABLE `nxt_campaign_triggers`
  MODIFY `trigger_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_category`
--
ALTER TABLE `nxt_category`
  MODIFY `category_id` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_category_type`
--
ALTER TABLE `nxt_category_type`
  MODIFY `type_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_daily_expenses`
--
ALTER TABLE `nxt_daily_expenses`
  MODIFY `expense_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_db_backup`
--
ALTER TABLE `nxt_db_backup`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_department`
--
ALTER TABLE `nxt_department`
  MODIFY `department_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_doctor`
--
ALTER TABLE `nxt_doctor`
  MODIFY `doctor_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_doctor_schedule`
--
ALTER TABLE `nxt_doctor_schedule`
  MODIFY `schedule_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_fbr_config`
--
ALTER TABLE `nxt_fbr_config`
  MODIFY `fbr_config_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_fbr_sync_log`
--
ALTER TABLE `nxt_fbr_sync_log`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_inventory`
--
ALTER TABLE `nxt_inventory`
  MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_lab_invoice`
--
ALTER TABLE `nxt_lab_invoice`
  MODIFY `invoice_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_lab_invoice_tests`
--
ALTER TABLE `nxt_lab_invoice_tests`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_lab_report`
--
ALTER TABLE `nxt_lab_report`
  MODIFY `report_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_lab_test`
--
ALTER TABLE `nxt_lab_test`
  MODIFY `test_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_medicine`
--
ALTER TABLE `nxt_medicine`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_notification`
--
ALTER TABLE `nxt_notification`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_patient`
--
ALTER TABLE `nxt_patient`
  MODIFY `patient_id` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_patient_audit`
--
ALTER TABLE `nxt_patient_audit`
  MODIFY `audit_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_patient_relationship`
--
ALTER TABLE `nxt_patient_relationship`
  MODIFY `relationship_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_permission`
--
ALTER TABLE `nxt_permission`
  MODIFY `permission_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_prescriptions`
--
ALTER TABLE `nxt_prescriptions`
  MODIFY `prescription_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_print_design`
--
ALTER TABLE `nxt_print_design`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_report_footer`
--
ALTER TABLE `nxt_report_footer`
  MODIFY `footer_id` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_room`
--
ALTER TABLE `nxt_room`
  MODIFY `room_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_segment`
--
ALTER TABLE `nxt_segment`
  MODIFY `segment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_service`
--
ALTER TABLE `nxt_service`
  MODIFY `service_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_slip`
--
ALTER TABLE `nxt_slip`
  MODIFY `slip_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_slip_type`
--
ALTER TABLE `nxt_slip_type`
  MODIFY `slip_type_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_supplier`
--
ALTER TABLE `nxt_supplier`
  MODIFY `supplier_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_tax_settings`
--
ALTER TABLE `nxt_tax_settings`
  MODIFY `tax_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_test_component`
--
ALTER TABLE `nxt_test_component`
  MODIFY `component_id` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_text_message`
--
ALTER TABLE `nxt_text_message`
  MODIFY `message_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_user`
--
ALTER TABLE `nxt_user`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_users`
--
ALTER TABLE `nxt_users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_user_available_leaves`
--
ALTER TABLE `nxt_user_available_leaves`
  MODIFY `available_leave_id` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_user_leave`
--
ALTER TABLE `nxt_user_leave`
  MODIFY `leave_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `nxt_user_test`
--
ALTER TABLE `nxt_user_test`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `prescription_items`
--
ALTER TABLE `prescription_items`
  MODIFY `item_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `prescription_other`
--
ALTER TABLE `prescription_other`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `prescription_vitals`
--
ALTER TABLE `prescription_vitals`
  MODIFY `vital_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `recentactivity`
--
ALTER TABLE `recentactivity`
  MODIFY `activity_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for table `nxt_bed`
--
ALTER TABLE `nxt_bed`
  -- Note: composite FK including `tenant_id` with ON DELETE SET NULL is invalid when
  -- `tenant_id` is NOT NULL. Change to reference only the nullable UUID/mrid columns
  -- so ON DELETE SET NULL can operate correctly without changing tenant_id nullability.
  ADD CONSTRAINT `fk_bed_bill` FOREIGN KEY (`current_bill_uuid`) REFERENCES `nxt_bill` (`bill_uuid`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_bed_patient` FOREIGN KEY (`current_patient_mrid`) REFERENCES `nxt_patient` (`patient_mrid`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_bed_room` FOREIGN KEY (`room_id`) REFERENCES `nxt_room` (`room_id`) ON DELETE CASCADE;

--
-- Constraints for table `nxt_bill`
--
ALTER TABLE `nxt_bill`
  ADD CONSTRAINT `fk_bill_bed` FOREIGN KEY (`bed_id`) REFERENCES `nxt_bed` (`bed_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_bill_room` FOREIGN KEY (`room_id`) REFERENCES `nxt_room` (`room_id`) ON DELETE SET NULL;

--
-- Constraints for table `nxt_campaign`
--
ALTER TABLE `nxt_campaign`
  ADD CONSTRAINT `nxt_campaign_ibfk_1` FOREIGN KEY (`campaign_segment`) REFERENCES `nxt_segment` (`segment_id`),
  ADD CONSTRAINT `nxt_campaign_ibfk_2` FOREIGN KEY (`campaign_message`) REFERENCES `nxt_text_message` (`message_id`);

--
-- Constraints for table `nxt_campaign_log`
--
ALTER TABLE `nxt_campaign_log`
  ADD CONSTRAINT `nxt_campaign_log_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `nxt_campaign` (`campaign_id`);

--
-- Constraints for table `nxt_campaign_queue`
--
ALTER TABLE `nxt_campaign_queue`
  ADD CONSTRAINT `nxt_campaign_queue_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `nxt_campaign` (`campaign_id`) ON DELETE CASCADE;

--
-- Constraints for table `nxt_campaign_triggers`
--
ALTER TABLE `nxt_campaign_triggers`
  ADD CONSTRAINT `nxt_campaign_triggers_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `nxt_campaign` (`campaign_id`) ON DELETE CASCADE;

--
-- Constraints for table `nxt_patient_audit`
--
ALTER TABLE `nxt_patient_audit`
  ADD CONSTRAINT `nxt_patient_audit_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `nxt_user` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `nxt_patient_relationship`
--
ALTER TABLE `nxt_patient_relationship`
  ADD CONSTRAINT `nxt_patient_relationship_ibfk_1` FOREIGN KEY (`primary_patient_id`) REFERENCES `nxt_patient` (`patient_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `nxt_patient_relationship_ibfk_2` FOREIGN KEY (`related_patient_id`) REFERENCES `nxt_patient` (`patient_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `nxt_patient_relationship_ibfk_3` FOREIGN KEY (`created_by`) REFERENCES `nxt_user` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `nxt_room`
--
ALTER TABLE `nxt_room`
  ADD CONSTRAINT `fk_room_category` FOREIGN KEY (`tenant_id`, `room_category`) REFERENCES `nxt_category` (`tenant_id`, `category_alias`) ON UPDATE CASCADE;

--
-- Constraints for table `nxt_slip`
--
ALTER TABLE `nxt_slip`
  ADD CONSTRAINT `fk_slip_bed` FOREIGN KEY (`bed_id`) REFERENCES `nxt_bed` (`bed_id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_slip_room` FOREIGN KEY (`room_id`) REFERENCES `nxt_room` (`room_id`) ON DELETE SET NULL;

--
-- Constraints for table `nxt_test_component`
--
ALTER TABLE `nxt_test_component`
  ADD CONSTRAINT `fk_test_code_from_lab_test` FOREIGN KEY (`tenant_id`, `test_code`) REFERENCES `nxt_lab_test` (`tenant_id`, `test_code`);
COMMIT;

-- INDEXES FOR MULTI-TENANCY SUPPORT

-- ====================
-- LABORATORY
-- ====================

ALTER TABLE `nxt_lab_test` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_alias` (`tenant_id`, `test_code`);

ALTER TABLE `nxt_test_component` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_test` (`tenant_id`, `test_code`);

ALTER TABLE `nxt_lab_report` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_invoice` (`tenant_id`, `invoice_uuid`);

ALTER TABLE `nxt_lab_invoice` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_uuid` (`tenant_id`, `invoice_uuid`),
  ADD INDEX `idx_tenant_patient` (`tenant_id`, `patient_mrid`);

ALTER TABLE `nxt_lab_invoice_tests` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_invoice` (`tenant_id`, `invoice_uuid`);

-- ====================
-- INVENTORY & MEDICINE
-- ====================

ALTER TABLE `nxt_medicine` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_name` (`tenant_id`, `medicine_name`);

ALTER TABLE `nxt_inventory` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_medicine` (`tenant_id`, `item_id`);

ALTER TABLE `nxt_supplier` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_name` (`tenant_id`, `supplier_name`);

-- ====================
-- CATEGORIES & SERVICES
-- ====================

ALTER TABLE `nxt_category` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_type` (`tenant_id`, `category_type`);

ALTER TABLE `nxt_category_type` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_alias` (`tenant_id`, `type_alias`);

ALTER TABLE `nxt_service` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_category` (`tenant_id`, `service_alias`);

ALTER TABLE `nxt_slip_type` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_alias` (`tenant_id`, `slip_type_alias`);

-- ====================
-- CAMPAIGN SYSTEM
-- ====================

ALTER TABLE `nxt_campaign` 
  ADD INDEX `idx_tenant_status` (`tenant_id`, `campaign_status`);

ALTER TABLE `nxt_campaign_log` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_campaign` (`tenant_id`, `campaign_id`),
  ADD INDEX `idx_tenant_status` (`tenant_id`, `status`);

ALTER TABLE `nxt_campaign_queue` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_status` (`tenant_id`, `status`);

ALTER TABLE `nxt_campaign_triggers` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_event` (`tenant_id`, `trigger_event`);

ALTER TABLE `nxt_segment` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_name` (`tenant_id`, `segment_name`);

ALTER TABLE `nxt_text_message` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_recipient` (`tenant_id`, `message_alias`);

-- ====================
-- FBR INTEGRATION (Pakistan Tax)
-- ====================

ALTER TABLE `nxt_fbr_config` 
  ADD UNIQUE INDEX `idx_unique_tenant_fbr` (`tenant_id`);

ALTER TABLE `nxt_fbr_sync_log` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

-- ====================
-- TAX MANAGEMENT
-- ====================

ALTER TABLE `nxt_tax_settings` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

-- ====================
-- FINANCIAL
-- ====================

ALTER TABLE `nxt_daily_expenses` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

-- ====================
-- CONFIGURATION & SETTINGS
-- ====================

ALTER TABLE `nxt_print_design` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD UNIQUE INDEX `idx_tenant_identifier` (`tenant_id`, `identifier`);

ALTER TABLE `nxt_patient_relationship` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

-- ====================
-- AI FEATURES
-- ====================

ALTER TABLE `ai_suggestions` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

ALTER TABLE `ai_feedback` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

ALTER TABLE `nxt_db_backup` 
  ADD INDEX `idx_tenant_date` (`tenant_id`, `created_at`);

ALTER TABLE `recentactivity` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_user` (`tenant_id`, `admin_user`);

ALTER TABLE `nxt_notification` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_user` (`tenant_id`, `user_id`);


-- ====================
-- PERMISSIONS (Shared or tenant-specific)
-- ====================

ALTER TABLE `nxt_permission` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

-- ====================
-- BOOTSTRAP STATUS (Per-tenant tracking)
-- ====================

ALTER TABLE `nxt_bootstrap_status` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

-- ====================
-- ALTUSER MANAGEMENT ADDITIONAL TABLES
-- ====================

ALTER TABLE `nxt_users` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_username` (`tenant_id`, `user_name`);

ALTER TABLE `nxt_user_available_leaves` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_user` (`tenant_id`, `user_id`);

ALTER TABLE `nxt_user_leave` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_user` (`tenant_id`, `user_id`),
  ADD INDEX `idx_tenant_status` (`tenant_id`, `leave_status`);

ALTER TABLE `nxt_user_test` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

-- ====================
-- PATIENT AUDIT & TRACKING
-- ====================

ALTER TABLE `nxt_patient_audit` 
  ADD INDEX `idx_tenant_id` (`tenant_id`),
  ADD INDEX `idx_tenant_user` (`tenant_id`, `user_id`),
  ADD INDEX `idx_tenant_date` (`tenant_id`, `created_at`);

-- ====================
-- REPORTING
-- ====================

ALTER TABLE `nxt_report_footer` 
  ADD INDEX `idx_tenant_id` (`tenant_id`);

-- Deferred foreign keys: add constraints after all tables created
ALTER TABLE `nxt_patient_match_audit`
  ADD CONSTRAINT `fk_patient_match_audit_tenant`
    FOREIGN KEY (`tenant_id`) REFERENCES `nxt_tenant`(`tenant_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_patient_match_audit_user`
    FOREIGN KEY (`user_id`) REFERENCES `nxt_user`(`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_patient_match_audit_patient`
    FOREIGN KEY (`matched_patient_id`) REFERENCES `nxt_patient`(`patient_id`) ON DELETE SET NULL ON UPDATE CASCADE;

COMMIT;

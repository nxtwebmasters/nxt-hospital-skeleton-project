-- Database: `nxt-hospital`
CREATE DATABASE IF NOT EXISTS `nxt-hospital`;

USE `nxt-hospital`;

-- Table structure for table `ai_feedback`
CREATE TABLE IF NOT EXISTS `ai_feedback` (
  `feedback_id` int(11) NOT NULL AUTO_INCREMENT,
  `doctor_alias` varchar(255) NOT NULL,
  `ai_suggestion_id` int(11) NOT NULL,
  `rating` int(11) DEFAULT NULL CHECK (`rating` between 1 and 5),
  `comments` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(255) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`feedback_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `ai_suggestions`
CREATE TABLE IF NOT EXISTS `ai_suggestions` (
  `suggestion_id` int(11) NOT NULL AUTO_INCREMENT,
  `input` text DEFAULT NULL,
  `suggestions` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(255) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`suggestion_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_appointment`
CREATE TABLE IF NOT EXISTS `nxt_appointment` (
  `appointment_id` int(11) NOT NULL AUTO_INCREMENT,
  `appointment_uuid` varchar(20) NOT NULL,
  `appointment_patient_mrid` varchar(20) NOT NULL,
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
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`appointment_id`),
  UNIQUE KEY `appointment_uuid` (`appointment_uuid`),
  KEY `fk_appointment_patient_mrid` (`appointment_patient_mrid`),
  KEY `fk_appointment_type_uuid` (`appointment_type_alias`),
  KEY `fk_appointment_department_uuid` (`appointment_department_alias`),
  KEY `fk_appointment_doctor_uuid` (`appointment_doctor_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_bill`
CREATE TABLE IF NOT EXISTS `nxt_bill` (
  `bill_id` int(11) NOT NULL AUTO_INCREMENT,
  `bill_uuid` varchar(50) NOT NULL,
  `slip_uuid` varchar(50) DEFAULT NULL,
  `patient_mrid` varchar(50) NOT NULL,
  `patient_name` varchar(100) NOT NULL,
  `patient_mobile` varchar(15) NOT NULL,
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
  `bill_type` varchar(20) DEFAULT NULL,
  `bill_delete` int(11) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`bill_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_campaign`
CREATE TABLE IF NOT EXISTS `nxt_campaign` (
  `campaign_id` int(11) NOT NULL AUTO_INCREMENT,
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
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`campaign_id`),
  UNIQUE KEY `campaign_alias` (`campaign_alias`),
  KEY `campaign_segment` (`campaign_segment`),
  KEY `campaign_message` (`campaign_message`),
  KEY `idx_campaign_status` (`campaign_status`),
  KEY `idx_scheduled_at` (`scheduled_at`),
  KEY `idx_campaign_channel` (`campaign_channel`),
  KEY `idx_campaign_type` (`campaign_type`),
  KEY `idx_campaign_status_type` (`campaign_status`,`campaign_type`),
  CONSTRAINT `nxt_campaign_ibfk_1` FOREIGN KEY (`campaign_segment`) REFERENCES `nxt_segment` (`segment_id`),
  CONSTRAINT `nxt_campaign_ibfk_2` FOREIGN KEY (`campaign_message`) REFERENCES `nxt_text_message` (`message_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_campaign_log`
CREATE TABLE IF NOT EXISTS `nxt_campaign_log` (
  `log_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `campaign_id` int(11) NOT NULL,
  `contact_id` varchar(100) NOT NULL COMMENT 'Reference to your contacts table',
  `status` enum('pending','sent','delivered','read','failed') DEFAULT 'pending',
  `error_message` text DEFAULT NULL,
  `attempt_count` tinyint(4) DEFAULT 0,
  `channel_type` enum('whatsapp','email','sms','push') DEFAULT 'whatsapp',
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`log_id`),
  KEY `idx_campaign_contact` (`campaign_id`,`contact_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `nxt_campaign_log_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `nxt_campaign` (`campaign_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_campaign_queue`
CREATE TABLE IF NOT EXISTS `nxt_campaign_queue` (
  `queue_id` int(11) NOT NULL AUTO_INCREMENT,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`queue_id`),
  KEY `idx_status` (`status`),
  KEY `idx_scheduled` (`scheduled_at`),
  KEY `idx_campaign_queue` (`campaign_id`,`status`),
  KEY `idx_contact_channel` (`contact_info`,`channel_type`),
  CONSTRAINT `nxt_campaign_queue_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `nxt_campaign` (`campaign_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_campaign_triggers`
CREATE TABLE IF NOT EXISTS `nxt_campaign_triggers` (
  `trigger_id` int(11) NOT NULL AUTO_INCREMENT,
  `campaign_id` int(11) NOT NULL,
  `trigger_event` varchar(100) NOT NULL,
  `trigger_conditions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`trigger_conditions`)),
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`trigger_id`),
  KEY `idx_trigger_event` (`trigger_event`),
  KEY `idx_campaign_trigger` (`campaign_id`,`trigger_event`),
  CONSTRAINT `nxt_campaign_triggers_ibfk_1` FOREIGN KEY (`campaign_id`) REFERENCES `nxt_campaign` (`campaign_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_category`
CREATE TABLE IF NOT EXISTS `nxt_category` (
  `category_id` int(10) NOT NULL,
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
-- Table structure for table `nxt_category_type`
CREATE TABLE IF NOT EXISTS `nxt_category_type` (
  `type_id` int(11) NOT NULL,
  `type_name` varchar(100) NOT NULL,
  `type_alias` varchar(100) NOT NULL,
  `type_description` longtext DEFAULT NULL,
  `type_status` tinyint(1) DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_daily_expenses`
CREATE TABLE IF NOT EXISTS `nxt_daily_expenses` (
  `expense_id` int(11) NOT NULL,
  `expense_name` varchar(100) NOT NULL,
  `expense_amount` decimal(10,2) NOT NULL,
  `expense_date` datetime NOT NULL,
  `expense_description` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_db_backup`
CREATE TABLE IF NOT EXISTS `nxt_db_backup` (
  `id` int(11) NOT NULL,
  `db_name` varchar(255) DEFAULT NULL,
  `step_message` text DEFAULT NULL,
  `step_action` varchar(100) DEFAULT NULL,
  `success` tinyint(1) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_department`
CREATE TABLE IF NOT EXISTS `nxt_department` (
  `department_id` int(11) NOT NULL AUTO_INCREMENT,
  `department_name` varchar(100) NOT NULL,
  `department_alias` varchar(100) NOT NULL,
  `department_description` text NOT NULL,
  `department_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(20) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`department_id`),
  UNIQUE KEY `department_name` (`department_name`),
  UNIQUE KEY `department_alias` (`department_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_doctor`
CREATE TABLE IF NOT EXISTS `nxt_doctor` (
  `doctor_id` int(11) NOT NULL AUTO_INCREMENT,
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
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`doctor_id`),
  UNIQUE KEY `doctor_alias` (`doctor_alias`),
  KEY `fk_doctor_department_uuid` (`doctor_department_alias`),
  KEY `fk_doctor_type_uuid` (`doctor_type_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_doctor_schedule`
CREATE TABLE IF NOT EXISTS `nxt_doctor_schedule` (
  `schedule_id` int(11) NOT NULL,
  `doctor_alias` varchar(100) NOT NULL,
  `schedule_day` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
  `schedule_slots` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_inventory`
CREATE TABLE IF NOT EXISTS `nxt_inventory` (
  `item_id` int(11) NOT NULL,
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
-- Table structure for table `nxt_lab_invoice`
CREATE TABLE IF NOT EXISTS `nxt_lab_invoice` (
  `invoice_id` int(11) NOT NULL,
  `invoice_uuid` varchar(25) NOT NULL,
  `invoice_tests` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`invoice_tests`)),
  `patient_mrid` varchar(25) NOT NULL,
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
-- Table structure for table `nxt_lab_invoice_tests`
CREATE TABLE IF NOT EXISTS `nxt_lab_invoice_tests` (
  `id` int(11) NOT NULL,
  `test_description` varchar(255) NOT NULL,
  `report_datetime` datetime NOT NULL,
  `price` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_lab_report`
CREATE TABLE IF NOT EXISTS `nxt_lab_report` (
  `report_id` int(11) NOT NULL,
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
-- Table structure for table `nxt_lab_test`
CREATE TABLE IF NOT EXISTS `nxt_lab_test` (
  `test_id` int(11) NOT NULL,
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
-- Table structure for table `nxt_medicine`
CREATE TABLE IF NOT EXISTS `nxt_medicine` (
  `id` int(11) NOT NULL,
  `medicine_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_notification`
CREATE TABLE IF NOT EXISTS `nxt_notification` (
  `id` int(11) NOT NULL,
  `type` varchar(100) NOT NULL,
  `description` text NOT NULL,
  `affected_table` varchar(255) DEFAULT NULL,
  `affected_id` varchar(255) NOT NULL,
  `user_id` varchar(255) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `meta_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_patient`
CREATE TABLE IF NOT EXISTS `nxt_patient` (
  `patient_id` int(10) NOT NULL AUTO_INCREMENT,
  `patient_mrid` varchar(20) NOT NULL,
  `patient_name` varchar(100) NOT NULL,
  `patient_mobile` varchar(15) NOT NULL,
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
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`patient_id`),
  UNIQUE KEY `patient_mrid` (`patient_mrid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_permission`
CREATE TABLE IF NOT EXISTS `nxt_permission` (
  `permission_id` int(11) NOT NULL,
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
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_prescriptions`
CREATE TABLE IF NOT EXISTS `nxt_prescriptions` (
  `prescription_id` int(11) NOT NULL,
  `slip_uuid` varchar(100) DEFAULT NULL,
  `patient_mrid` varchar(100) NOT NULL,
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
-- Table structure for table `nxt_print_design`
CREATE TABLE IF NOT EXISTS `nxt_print_design` (
  `id` int(11) NOT NULL,
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
  `updated_by` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_report_footer`
CREATE TABLE IF NOT EXISTS `nxt_report_footer` (
  `footer_id` int(10) NOT NULL,
  `footer_title` varchar(255) DEFAULT NULL,
  `footer_details` text DEFAULT NULL,
  `footer_no` int(10) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_room`
CREATE TABLE IF NOT EXISTS `nxt_room` (
  `room_id` int(11) NOT NULL,
  `room_name` varchar(100) NOT NULL,
  `room_alias` varchar(100) NOT NULL,
  `room_description` text DEFAULT NULL,
  `room_rate` int(10) NOT NULL,
  `room_status` int(10) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_segment`
CREATE TABLE IF NOT EXISTS `nxt_segment` (
  `segment_id` int(11) NOT NULL AUTO_INCREMENT,
  `segment_name` varchar(100) NOT NULL,
  `segment_alias` varchar(100) NOT NULL,
  `segment_filter` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `segment_description` text DEFAULT NULL,
  `contact_count` int(11) DEFAULT 0,
  `segment_status` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`segment_id`),
  UNIQUE KEY `segment_alias` (`segment_alias`),
  KEY `idx_segment_status` (`segment_status`)
) ;
-- Table structure for table `nxt_service`
CREATE TABLE IF NOT EXISTS `nxt_service` (
  `service_id` int(11) NOT NULL,
  `service_name` varchar(100) NOT NULL,
  `service_alias` varchar(100) NOT NULL,
  `service_description` text DEFAULT NULL,
  `service_rate` int(10) NOT NULL,
  `service_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_slip`
CREATE TABLE IF NOT EXISTS `nxt_slip` (
  `slip_id` int(11) NOT NULL,
  `slip_uuid` varchar(20) NOT NULL,
  `slip_mrid` varchar(20) NOT NULL,
  `slip_patient_name` varchar(100) NOT NULL,
  `slip_patient_mobile` varchar(15) NOT NULL,
  `slip_disposal` varchar(50) NOT NULL,
  `slip_department` varchar(20) DEFAULT NULL,
  `slip_doctor` varchar(20) NOT NULL,
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
  `slip_type` varchar(20) NOT NULL,
  `slip_delete` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_slip_type`
CREATE TABLE IF NOT EXISTS `nxt_slip_type` (
  `slip_type_id` int(11) NOT NULL,
  `slip_type_name` varchar(100) NOT NULL,
  `slip_type_alias` varchar(100) NOT NULL,
  `fields` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`fields`)),
  `isBill` tinyint(1) NOT NULL,
  `slip_type_status` int(10) NOT NULL DEFAULT 1,
  `slip_type_description` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_supplier`
CREATE TABLE IF NOT EXISTS `nxt_supplier` (
  `supplier_id` int(11) NOT NULL,
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
-- Table structure for table `nxt_test_component`
CREATE TABLE IF NOT EXISTS `nxt_test_component` (
  `component_id` int(10) NOT NULL AUTO_INCREMENT,
  `component_title` varchar(100) DEFAULT NULL,
  `component_ranges` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`component_ranges`)),
  `test_code` varchar(100) NOT NULL,
  `created_by` varchar(50) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`component_id`),
  KEY `fk_test_code_from_lab_test` (`test_code`),
  CONSTRAINT `fk_test_code_from_lab_test` FOREIGN KEY (`test_code`) REFERENCES `nxt_lab_test` (`test_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
-- Table structure for table `nxt_text_message`
CREATE TABLE IF NOT EXISTS `nxt_text_message` (
  `message_id` int(11) NOT NULL AUTO_INCREMENT,
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
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`message_id`),
  UNIQUE KEY `message_alias` (`message_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_user`
CREATE TABLE IF NOT EXISTS `nxt_user` (
  `user_id` int(11) NOT NULL,
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
-- Table structure for table `nxt_users`
CREATE TABLE IF NOT EXISTS `nxt_users` (
  `user_id` int(11) NOT NULL,
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
-- Table structure for table `nxt_user_available_leaves`
CREATE TABLE IF NOT EXISTS `nxt_user_available_leaves` (
  `available_leave_id` int(10) NOT NULL,
  `user_id` int(10) NOT NULL,
  `leave_alias` varchar(100) NOT NULL,
  `available_balance` int(10) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `nxt_user_leave`
CREATE TABLE IF NOT EXISTS `nxt_user_leave` (
  `leave_id` int(11) NOT NULL,
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
-- Table structure for table `nxt_user_test`
CREATE TABLE IF NOT EXISTS `nxt_user_test` (
  `user_id` int(11) NOT NULL,
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
) ;
-- Table structure for table `prescription_items`
CREATE TABLE IF NOT EXISTS `prescription_items` (
  `item_id` int(11) NOT NULL AUTO_INCREMENT,
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
  `updated_by` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `prescription_other`
CREATE TABLE IF NOT EXISTS `prescription_other` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
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
  `updated_by` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `prescription_vitals`
CREATE TABLE IF NOT EXISTS `prescription_vitals` (
  `vital_id` int(11) NOT NULL AUTO_INCREMENT,
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
  `updated_by` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`vital_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
-- Table structure for table `recentactivity`
CREATE TABLE IF NOT EXISTS `recentactivity` (
  `activity_id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_user` varchar(100) DEFAULT NULL,
  `action_title` varchar(50) NOT NULL,
  `action_description` text DEFAULT NULL,
  `table_affected` varchar(255) DEFAULT NULL,
  `affected_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`activity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
CREATE DATABASE IF NOT EXISTS `nxt-hospital`;

USE `nxt-hospital`;

CREATE TABLE IF NOT EXISTS `nxt_appointment` (
  `appointment_id` int(11) NOT NULL AUTO_INCREMENT,
  `appointment_uuid` varchar(20) NOT NULL,
  `appointment_patient_mrid` varchar(20) NOT NULL,
  `appointment_patient_name` varchar(255) NOT NULL,
  `appointment_patient_mobile` varchar(15) NOT NULL,
  `appointment_type_alias` varchar(100) NOT NULL,
  `appointment_department_alias` varchar(20) NOT NULL,
  `appointment_doctor_alias` varchar(20) NOT NULL,
  `appointment_date` date NOT NULL,
  `appointment_time` time DEFAULT NULL,
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


CREATE TABLE IF NOT EXISTS `nxt_appointment_type` (
  `appointment_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `appointment_type_name` varchar(100) NOT NULL,
  `appointment_type_alias` varchar(100) NOT NULL,
  `appointment_type_description` text DEFAULT NULL,
  `appointment_type_status` tinyint(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`appointment_type_id`),
  UNIQUE KEY `appointment_type_alias` (`appointment_type_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_bill` (
  `bill_id` int(11) NOT NULL AUTO_INCREMENT,
  `bill_uuid` varchar(50) NOT NULL,
  `slip_uuid` varchar(50) DEFAULT NULL,
  `patient_mrid` varchar(50) NOT NULL,
  `patient_name` varchar(50) NOT NULL,
  `patient_mobile` varchar(50) NOT NULL,
  `bill_vitals` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `slip_payment_mode` varchar(50) DEFAULT NULL,
  `slip_payment_detail` varchar(50) DEFAULT NULL,
  `bill_total` int(11) NOT NULL DEFAULT 0,
  `bill_payable` int(11) NOT NULL DEFAULT 0,
  `bill_paid` int(11) NOT NULL DEFAULT 0,
  `bill_discount` int(11) NOT NULL DEFAULT 0,
  `bill_balance` int(11) NOT NULL DEFAULT 0,
  `bill_delete` int(11) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
  `bill_type` varchar(100) NOT NULL,
  `bill_doctor` varchar(200) NOT NULL,
  `bill_disposal` varchar(100) NOT NULL,
  PRIMARY KEY (`bill_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_category` (
  `category_id` int(10) NOT NULL AUTO_INCREMENT,
  `category_name` varchar(100) NOT NULL,
  `category_alias` varchar(100) NOT NULL,
  `category_description` longtext DEFAULT NULL,
  `category_status` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `category_alias` (`category_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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


CREATE TABLE IF NOT EXISTS `nxt_doctor` (
  `doctor_id` int(11) NOT NULL AUTO_INCREMENT,
  `doctor_name` varchar(100) NOT NULL,
  `doctor_alias` varchar(100) NOT NULL,
  `doctor_mobile` varchar(15) DEFAULT NULL,
  `doctor_email` varchar(50) DEFAULT NULL,
  `doctor_title` varchar(255) NOT NULL,
  `doctor_share` int(11) NOT NULL DEFAULT 0,
  `doctor_address` varchar(255) DEFAULT NULL,
  `doctor_cnic` varchar(50) DEFAULT NULL,
  `doctor_degree` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `doctor_experience` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
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


CREATE TABLE IF NOT EXISTS `nxt_doctor_type` (
  `doctor_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `doctor_type_name` varchar(100) NOT NULL,
  `doctor_type_alias` varchar(100) NOT NULL,
  `doctor_type_description` text DEFAULT NULL,
  `doctor_type_status` int(10) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`doctor_type_id`),
  UNIQUE KEY `doctor_type_alias` (`doctor_type_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


CREATE TABLE IF NOT EXISTS `nxt_followup_slip` (
  `slip_id` int(11) NOT NULL AUTO_INCREMENT,
  `slip_uuid` varchar(50) NOT NULL,
  `slip_ref_uuid` varchar(50) NOT NULL,
  `slip_ref_mrid` varchar(50) NOT NULL,
  `slip_fee` int(11) NOT NULL DEFAULT 0,
  `slip_discount` int(11) NOT NULL DEFAULT 0,
  `slip_paid` int(11) NOT NULL DEFAULT 0,
  `slip_balance` int(11) NOT NULL DEFAULT 0,
  `slip_delete` int(11) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`slip_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_lab_invoice` (
  `invoice_id` int(11) NOT NULL AUTO_INCREMENT,
  `invoice_uuid` varchar(25) NOT NULL,
  `invoice_tests` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`invoice_tests`)),
  `patient_mrid` varchar(25) NOT NULL,
  `report_date` datetime NOT NULL,
  `reference` varchar(100) DEFAULT NULL,
  `consultant` varchar(100) NOT NULL DEFAULT 'self',
  `invoice_delete` int(11) NOT NULL DEFAULT 1,
  `total` int(11) NOT NULL DEFAULT 0,
  `paid` int(11) NOT NULL DEFAULT 0,
  `discount` int(11) NOT NULL DEFAULT 0,
  `payable` int(11) NOT NULL DEFAULT 0,
  `balance` int(11) NOT NULL DEFAULT 0,
  `created_by` varchar(50) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`invoice_id`),
  UNIQUE KEY `lab_invoice_uuid` (`invoice_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_lab_invoice_tests` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `test_description` varchar(255) NOT NULL,
  `report_datetime` datetime NOT NULL,
  `price` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_lab_report` (
  `report_id` int(11) NOT NULL AUTO_INCREMENT,
  `report_uuid` varchar(50) NOT NULL,
  `invoice_uuid` varchar(50) NOT NULL,
  `patient_mrid` varchar(50) NOT NULL,
  `patient_name` varchar(255) NOT NULL,
  `patient_mobile` varchar(15) NOT NULL,
  `test_results` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `report_delete` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_lab_test` (
  `test_id` int(11) NOT NULL AUTO_INCREMENT,
  `test_name` varchar(100) NOT NULL,
  `test_code` varchar(20) NOT NULL,
  `test_description` text DEFAULT NULL,
  `test_charges` decimal(10,2) NOT NULL,
  `sample_require` varchar(255) DEFAULT NULL,
  `report_completion` varchar(50) DEFAULT NULL,
  `category` enum('SPECIAL','ROUTINE') NOT NULL,
  `performed_days` varchar(50) DEFAULT NULL,
  `report_title` varchar(255) DEFAULT NULL,
  `clinical_interpretation` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `note` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `status` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` varchar(100) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`test_id`),
  UNIQUE KEY `test_code` (`test_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nxt_patient` (
  `patient_id` int(10) NOT NULL AUTO_INCREMENT,
  `patient_mrid` varchar(20) NOT NULL,
  `patient_name` varchar(100) NOT NULL,
  `patient_mobile` varchar(15) NOT NULL,
  `patient_email` varchar(100) DEFAULT NULL,
  `patient_gender` varchar(20) NOT NULL,
  `patient_dob` date DEFAULT NULL,
  `patient_age` varchar(255) NOT NULL,
  `patient_blood_group` varchar(10) DEFAULT NULL,
  `patient_address` varchar(255) DEFAULT NULL,
  `patient_delete` int(10) NOT NULL DEFAULT 0,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`patient_id`),
  UNIQUE KEY `patient_mrid` (`patient_mrid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_room` (
  `room_id` int(11) NOT NULL AUTO_INCREMENT,
  `room_name` varchar(100) NOT NULL,
  `room_alias` varchar(100) NOT NULL,
  `room_description` text DEFAULT NULL,
  `room_rate` int(10) NOT NULL,
  `room_status` int(10) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`room_id`),
  UNIQUE KEY `room_alias` (`room_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_service` (
  `service_id` int(11) NOT NULL AUTO_INCREMENT,
  `service_name` varchar(100) NOT NULL,
  `service_alias` varchar(100) NOT NULL,
  `service_description` text DEFAULT NULL,
  `service_rate` int(10) NOT NULL,
  `service_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`service_id`),
  UNIQUE KEY `service_alias` (`service_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_service_slip` (
  `slip_id` int(11) NOT NULL AUTO_INCREMENT,
  `slip_uuid` varchar(50) NOT NULL,
  `slip_ref_slip` varchar(50) NOT NULL,
  `slip_name` varchar(252) NOT NULL,
  `slip_rate` int(11) NOT NULL DEFAULT 0,
  `slip_discount` int(11) NOT NULL DEFAULT 0,
  `slip_paid` int(11) NOT NULL DEFAULT 0,
  `slip_balance` int(11) NOT NULL DEFAULT 0,
  `slip_delete` int(11) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`slip_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_slip` (
  `slip_id` int(11) NOT NULL AUTO_INCREMENT,
  `slip_uuid` varchar(20) NOT NULL,
  `slip_mrid` varchar(20) NOT NULL,
  `slip_patient_name` varchar(100) NOT NULL,
  `slip_patient_mobile` varchar(15) NOT NULL,
  `slip_disposal` varchar(50) NOT NULL,
  `slip_department` varchar(100) DEFAULT NULL,
  `slip_doctor` varchar(100) NOT NULL,
  `slip_appointment` varchar(100) DEFAULT 'walk_in',
  `slip_payment_mode` varchar(50) DEFAULT NULL,
  `slip_payment_detail` varchar(50) DEFAULT NULL,
  `slip_fee` int(10) DEFAULT NULL,
  `slip_discount` int(10) DEFAULT NULL,
  `slip_payable` int(10) DEFAULT NULL,
  `slip_paid` int(10) DEFAULT NULL,
  `slip_balance` int(10) DEFAULT NULL, 
  `slip_procedure` varchar(255) DEFAULT NULL,
  `slip_type` varchar(20) NOT NULL,
  `slip_delete` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`slip_id`),
  UNIQUE KEY `slip_uuid` (`slip_uuid`),
  KEY `fk_slip_doctor_uuid` (`slip_doctor`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_slip_subtype` (
  `slip_subtype_id` int(11) NOT NULL AUTO_INCREMENT,
  `slip_type_alias` varchar(100) NOT NULL,
  `slip_subtype_name` varchar(100) NOT NULL,
  `slip_subtype_alias` varchar(100) NOT NULL,
  `slip_subtype_description` text DEFAULT NULL,
  `slip_subtype_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`slip_subtype_id`),
  UNIQUE KEY `slip_subtype_alias` (`slip_subtype_alias`),
  KEY `fk_slip_type_alias` (`slip_type_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_slip_type` (
  `slip_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `slip_type_name` varchar(100) NOT NULL,
  `slip_type_alias` varchar(100) NOT NULL,
  `fields` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `isBill` tinyint(1) NOT NULL,
  `slip_type_status` int(10) NOT NULL DEFAULT 1,
  `slip_type_description` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`slip_type_id`),
  UNIQUE KEY `slip_type_alias` (`slip_type_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_test_component` (
  `component_id` int(10) NOT NULL AUTO_INCREMENT,
  `component_title` varchar(100) DEFAULT NULL,
  `component_ranges` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `test_code` varchar(100) NOT NULL,
  `created_by` varchar(50) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`component_id`),
  KEY `fk_test_code_from_lab_test` (`test_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nxt_user` (
  `user_id` int(11) NOT NULL AUTO_INCREMENT,
  `user_name` varchar(100) NOT NULL,
  `user_email` varchar(100) DEFAULT NULL,
  `user_mobile` varchar(15) DEFAULT NULL,
  `user_username` varchar(50) NOT NULL,
  `user_password` varchar(255) NOT NULL,
  `user_status` int(10) NOT NULL DEFAULT 1,
  `user_permission` varchar(100) NOT NULL,
  `user_last_login` datetime DEFAULT NULL,
  `user_photo` varchar(200) DEFAULT NULL,
  `user_address` VARCHAR(255) DEFAULT NULL,
  `user_cnic` VARCHAR(50) DEFAULT NULL,
  `user_experience` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `user_degree` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `user_cnic_front` VARCHAR(255) DEFAULT NULL,
  `user_cnic_back` VARCHAR(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `user_username` (`user_username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_permission` (
  `permission_id` int(11) NOT NULL AUTO_INCREMENT,
  `permission_name` varchar(100) NOT NULL,
  `permission_alias` varchar(100) NOT NULL,
  `permission_description` text NOT NULL,
  `component_access` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `read_permission` tinyint(1) NOT NULL DEFAULT 0,
  `write_permission` tinyint(1) NOT NULL DEFAULT 0,
  `delete_permission` tinyint(1) NOT NULL DEFAULT 0,
  `permission_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`permission_id`),
  UNIQUE KEY `permission_alias` (`permission_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_db_backup` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `db_name` VARCHAR(255) NOT NULL,
    `step_message` TEXT NOT NULL,
    `step_action` VARCHAR(100) NOT NULL,
    `success` TINYINT(1) NOT NULL,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `recentactivity` (
  `activity_id` int(11) NOT NULL AUTO_INCREMENT,
  `admin_user` varchar(100) NOT NULL,
  `action_title` varchar(100) NOT NULL,
  `action_description` text NOT NULL,
  `table_affected` varchar(255) NOT NULL,
  `affected_id` int(11) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`activity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_notification` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `type` VARCHAR(100) NOT NULL,
  `description` TEXT NOT NULL,
  `affected_table` VARCHAR(255),
  `affected_id` INT(11) NOT NULL,
  `user_id` VARCHAR(255) NOT NULL,
  `ip_address` VARCHAR(45) NULL,
  `meta_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_prescriptions` (
    `prescription_id` INT(11) NOT NULL AUTO_INCREMENT,
    `patient_mrid` VARCHAR(100) NOT NULL,
    `patient_mobile` VARCHAR(100) NOT NULL,
    `patient_name` VARCHAR(255) NOT NULL,
    `doctor_alias` VARCHAR(255) NOT NULL,
    `symptoms` TEXT,
    `diagnosis` TEXT,
    `ai_id` INT(11) DEFAULT NULL,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    `created_by` VARCHAR(255) NOT NULL,
    `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
    `updated_by` VARCHAR(255) NULL,
     PRIMARY KEY (`prescription_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `prescription_items` (
    `item_id` INT(11) NOT NULL AUTO_INCREMENT,
    `prescription_id` INT(11) NOT NULL,
    `medicine_name` VARCHAR(255),
    `dosage` TEXT,
    `frequency` VARCHAR(50),
    `duration` INT(11),
    `special_instructions` TEXT,
    `category` VARCHAR(50),
    `remarks` TEXT,
    `interaction_warnings` TEXT,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    `created_by` VARCHAR(255) NOT NULL,
    `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
    `updated_by` VARCHAR(255) NULL,
     PRIMARY KEY (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;


CREATE TABLE IF NOT EXISTS `ai_feedback` (
    `feeback_id` INT(11) NOT NULL AUTO_INCREMENT,
    `doctor_alias` VARCHAR(255) NOT NULL,
    `ai_suggestion_id` INT(11) NOT NULL,
    `rating` INT(11) CHECK (rating BETWEEN 1 AND 5),
    `comments` TEXT,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    `created_by` VARCHAR(255) NOT NULL,
    `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
    `updated_by` VARCHAR(255) NULL,
    PRIMARY KEY (`feeback_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `ai_suggestions` (
    `suggestion_id` INT(11) NOT NULL AUTO_INCREMENT,
    `input` TEXT,
    `suggestions` TEXT,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    `created_by` VARCHAR(255) NOT NULL,
    `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
    `updated_by` VARCHAR(255) NULL,
     PRIMARY KEY(`suggestion_id`)  
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `prescription_vitals` (
    `vital_id` INT(11) NOT NULL AUTO_INCREMENT,
    `prescription_id` INT(11) NOT NULL,
    `pulse` VARCHAR(50) NULL,
    `blood_pressure` VARCHAR(50) NULL,
    `temperature` VARCHAR(50) NULL,
    `respiratory_rate` VARCHAR(50) NULL,
    `height` VARCHAR(50) NULL,
    `weight` VARCHAR(50) NULL,
    `bmi` VARCHAR(100) NULL,
    `ofc` VARCHAR(100) NULL,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    `created_by` VARCHAR(255) NOT NULL,
    `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
    `updated_by` VARCHAR(255) NULL,
     PRIMARY KEY(`vital_id`)  
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `prescription_other` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `prescription_id` INT(11) NOT NULL,
    `referral_consultant` VARCHAR(100) DEFAULT NULL,
    `referral_note` TEXT DEFAULT NULL,
    `disposal` VARCHAR(50) DEFAULT NULL,
    `disposal_note` TEXT DEFAULT NULL,
    `followup_date` datetime DEFAULT NULL,
    `followup_note` TEXT DEFAULT NULL,
    `created_at` datetime NOT NULL DEFAULT current_timestamp(),
    `created_by` VARCHAR(255) NOT NULL,
    `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
    `updated_by` VARCHAR(255) NULL,
     PRIMARY KEY(`id`)  
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_medicine ` (
    `id` INT(11) NOT NULL AUTO_INCREMENT,
    `medicine_name` VARCHAR(255) NOT NULL UNIQUE,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `nxt_user` (`user_id`, `user_name`, `user_email`, `user_mobile`, `user_username`, `user_password`, `user_status`, `user_permission`, `user_last_login`, `user_photo`, `user_address`, `user_cnic`, `user_experience`, `user_degree`, `user_cnic_front`, `user_cnic_back`, `created_at`, `created_by`, `updated_at`, `updated_by`) VALUES (
  1, 'Administrator', NULL, NULL, 'admin', '$2a$10$D3HzBNl77kmSdXxNUCpNqOglNmqjqRlaCKUAkLre8wa/DnTWeaNMi', 1, 'admin', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, CURRENT_TIMESTAMP(), 'admin', NULL, NULL);

INSERT INTO `nxt_permission` (`permission_id`, `permission_name`, `permission_alias`, `permission_description`, `component_access`, `read_permission`, `write_permission`, `delete_permission`, `permission_status`, `created_at`, `created_by`, `updated_at`, `updated_by`) VALUES
(1, 'Administrator', 'admin', 'permission with complete system access', '["laboratory-slip","laboratory-report","laboratory-test","laboratory-test-component","slip","bill","slip-type","department","doctor","doctor-type","patient","category","room","service","bill-vitals","permission","backup","user"]', 1, 1, 1, 1, CURRENT_TIMESTAMP(), 'admin', NULL, NULL);

INSERT INTO `nxt_slip_type` (`slip_type_id`, `slip_type_name`, `slip_type_alias`, `fields`, `isBill`, `slip_type_status`, `slip_type_description`, `created_at`, `created_by`, `updated_at`, `updated_by`) VALUES 
(1,'OPD SLIP','opd_slip','[\"uuid\",\"mrid\",\"name\",\"mobile\",\"gender\",\"dob\",\"age\",\"bloodgroup\",\"address\",\"disposal\",\"department\",\"doctor\",\"fee\",\"paid\",\"discount\",\"payable\",\"balance\"]',0,1,'',CURRENT_TIMESTAMP(), 'admin', NULL, NULL);

INSERT INTO `nxt_lab_test` (`test_id`, `test_name`, `test_code`, `test_description`, `test_charges`, `sample_require`, `report_completion`, `category`, `performed_days`, `report_title`, `clinical_interpretation`, `status`, `created_by`, `created_at`, `updated_by`, `updated_at`, `note`) VALUES
(1, 'C-ANCA', '1', '', 5500.00, '3-5cc clotted blood or serum', 'After 3 Days', 'SPECIAL', '0', 'Special Test Reports', '[]', 1, 'admin', CURRENT_TIMESTAMP(), NULL, NULL, '[]'),
(2, 'TB Gold', '100', '', 10000.00, 'Contact Lab', 'After 3 Days', 'SPECIAL', '3', 'SPECIAL TEST REPORT', '[]', 1, 'admin', CURRENT_TIMESTAMP(), NULL, NULL, '[]'),
(3, 'Dengue (NS1)', '101', '', 2600.00, 'Serum/Blood', 'After 1 Day', 'ROUTINE', '3', 'SPECIAL TEST REPORT', '[]', 1, 'admin', CURRENT_TIMESTAMP(), NULL, NULL, '[]'),
(4, 'Herpus IgG, IgM', '102', '', 4200.00, 'Serum/Blood', 'After 3 Days', 'SPECIAL', '7', '17-Ketosteroids (24 Hrs Urine)', '[]', 1, 'admin', CURRENT_TIMESTAMP(), NULL, NULL, '[]'),
(5, '17-OH CBCB (17-OHP)', '103', '', 1350.00, '3-5 cc Clotted Blood/Serum', 'After 10 Days', 'SPECIAL', '10', '17-OH Progesterone', '[]', 1, 'admin', '2024-12-15 18:15:33', NULL, NULL, '[]'),
(6, 'Vitamin D3', '104', '', 3200.00, '3-5 cc Clotted Blood/Serum', 'After 3 Days', 'SPECIAL', '14', 'SPECIAL TEST REPORT', '[]', 1, 'admin', '2024-12-15 18:18:19', NULL, NULL, '[]'),
(7, '5-HIAA (Hydroxy Indole Acetic Acid)', '105', '', 1500.00, '24 Hrs Urine', 'After 5 Days', 'SPECIAL', '5', '5-H.I.A.A. Report', '[]', 1, 'admin', '2024-12-15 18:20:22', NULL, NULL, '[]'),
(8, 'A/G Ratio', '106', '', 700.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'LIVER FUNCTIONS REPORT', '[]', 1, 'admin', '2024-12-15 18:21:33', NULL, NULL, '[]'),
(9, 'Anti CCP', '107', '', 3200.00, '3-5 cc Clotted Blood/Serum', 'After 3 Days', 'SPECIAL', '7', 'Anti CCP', '[]', 1, 'admin', '2024-12-15 18:23:56', NULL, NULL, '[]'),
(10, 'Absolute Eosinophil Count', '108', '', 250.00, '3 cc Blood In EDTA', 'After 1 Day', 'SPECIAL', '0', 'Absolute Eosinophil Count Report', '[]', 1, 'admin', '2024-12-15 18:25:05', NULL, NULL, '[]'),
(11, 'Absolute Values/Cell Counts', '109', '', 300.00, '3 cc Blood In EDTA', 'After 1 Day', 'SPECIAL', '0', 'Absolute Values/Cell Counts', '[]', 1, 'admin', '2024-12-15 18:26:19', NULL, NULL, '[]'),
(12, 'Acid Phosphatase', '111', '', 1400.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '1', 'SPECIAL CHEMISTRY REPORT', '[]', 1, 'admin', '2024-12-15 18:30:59', NULL, NULL, '[]'),
(13, 'Acid Phosphatase (Prostatic)', '112', '', 1400.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '1', 'Acid Phosphatase (Prostatic)', '[]', 1, 'admin', '2024-12-15 18:32:54', NULL, NULL, '[]'),
(14, 'Acid Phosphatase (Total)', '113', '', 1400.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '1', 'Acid Phosphatase (Total)', '[]', 1, 'admin', '2024-12-15 18:34:05', NULL, NULL, '[]'),
(15, 'Anti Mullerian Hormone AMH', '114', '', 5500.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '1', 'Special Test Reports', '[]', 1, 'admin', '2024-12-15 18:35:11', NULL, NULL, '[]'),
(16, 'ACTH', '115', '', 2600.00, '3-5 cc Blood in EDTA/Serum', 'After 2 Days', 'SPECIAL', '2', 'ENDOCRINOLOGY REPORT', '[]', 1, 'admin', '2024-12-15 18:36:32', NULL, NULL, '[]'),
(17, 'AFB Smear', '116', '', 400.00, 'Any Specimen', 'After 1 Day', 'ROUTINE', '0', 'AFB Smear', '[]', 1, 'admin', '2024-12-15 18:38:14', NULL, NULL, '[]'),
(18, 'Fertility Profile', '117', '', 5800.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '1', 'Fertility Profile - FSH, LH, Prolactin', '[]', 1, 'admin', '2024-12-15 18:44:05', NULL, NULL, '[]'),
(19, 'Albumin', '118', '', 400.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'LIVER FUNCTIONS REPORT', '[]', 1, 'admin', '2024-12-15 18:46:04', NULL, NULL, '[]'),
(20, 'Spot Urine Albumin', '119', '', 300.00, 'Random Urine', 'After 1 Day', 'ROUTINE', '1', 'URINE REPORT', '[]', 1, 'admin', '2024-12-15 18:47:47', NULL, NULL, '[]'),
(21, 'Alcohol Level', '120', '', 790.00, '3-5 cc Clotted Blood/Serum', 'After 2 Days', 'SPECIAL', '2', 'Alcohol Level Report', '[]', 1, 'admin', '2024-12-15 13:35:19', NULL, NULL, '[]'),
(22, 'Aldolase', '121', '', 600.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '1', 'SPECIAL CHEMISTRY REPORT', '[]', 1, 'admin', '2024-12-15 13:37:03', NULL, NULL, '[]'),
(23, 'Aldosterone Level', '122', '', 1100.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Aldosterone Level', '[]', 1, 'admin', '2024-12-15 13:38:13', NULL, NULL, '[]'),
(24, 'Alkaline Phosphate', '123', '', 400.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'LIVER FUNCTIONS REPORT', '[]', 1, 'admin', '2024-12-15 13:40:09', NULL, NULL, '[]'),
(25, 'ALPHA 1-Anti Trypsin Level (L-1)', '124', '', 1000.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'CARDIAC ENZYMES REPORT', '[]', 1, 'admin', '2024-12-15 13:41:14', NULL, NULL, '[]'),
(26, 'ALPHA Feto-protein (AFP)', '125', '', 2500.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '1', 'TUMOUR MARKERS REPORT', '[]', 1, 'admin', '2024-12-15 13:42:25', NULL, NULL, '[]'),
(27, 'Alpha-MDBH', '126', '', 800.00, '3-5cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '1', 'CARDIAC ENZYMES REPORT', '[]', 1, 'admin', '2024-12-15 13:43:28', NULL, NULL, '[]'),
(28, 'Amino Acid', '127', '', 950.00, '24 Hrs Urine', 'After 1 Week', 'SPECIAL', '7', 'Amino Acid', '[]', 1, 'admin', '2024-12-15 13:44:43', NULL, NULL, '[]'),
(29, 'Amino Acid Chromatography', '128', '', 950.00, '24 Hrs Urine', 'After 1 Week', 'SPECIAL', '7', 'Amino Acid Chromatography', '[]', 1, 'admin', '2024-12-15 13:45:44', NULL, NULL, '[]'),
(30, 'Aminophylline / Theophylline', '129', '', 500.00, '3-5 cc Clotted Blood/serum', 'After 2 Days', 'SPECIAL', '2', 'Aminophylline / Theophylline', '[]', 1, 'admin', '2024-12-15 13:46:42', NULL, NULL, '[]'),
(31, 'Ammonia (NH3)', '130', '', 1050.00, '3-5 cc Blood In EDTA', 'After 1 Day', 'SPECIAL', '1', 'SERUM ELECTROLYTES REPORT', '[]', 1, 'admin', '2024-12-15 13:47:47', NULL, NULL, '[]'),
(32, 'Amylase', '131', '', 1400.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'BIOCHEMISTRY REPORT', '[]', 1, 'admin', '2024-12-15 13:50:58', NULL, NULL, '[]'),
(33, 'Amylase (Urine)', '132', '', 760.00, '24 Hrs Urine/Random Urine', 'After 1 Day', 'ROUTINE', '0', 'SPECIAL CHEMISTRY REPORT', '[]', 1, 'admin', '2024-12-15 13:51:57', NULL, NULL, '[]'),
(34, 'ANA', '133', '', 0.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'SEROLOGY REPORT', '[]', 1, 'admin', '2024-12-15 14:02:58', NULL, NULL, '[]'),
(35, 'ANA By Elisa', '134', '', 4200.00, '3-5 cc Clotted Blood/Serum', 'After 5 Days', 'SPECIAL', '3', 'SEROLOGY REPORT', '[]', 1, 'admin', '2024-12-15 14:04:02', NULL, NULL, '[]'),
(36, 'C-ANCA', '135', '', 5500.00, '3-5 cc Clotted Blood/Serum', 'After 3 Days', 'SPECIAL', '3', 'Special Test Reports', '[]', 1, 'admin', '2024-12-15 14:05:07', NULL, NULL, '[]'),
(37, 'ANCA-C (IgG)', '136', '', 2200.00, 'contact Lab', 'After 1 Week', 'SPECIAL', '7', 'ANCA-C (IgM)', '[]', 1, 'admin', '2024-12-15 14:06:30', NULL, NULL, '[]'),
(38, 'ANCA-C (IgM)', '137', '', 2200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'ANCA-C (IgM)', '[]', 1, 'admin', '2024-12-15 14:07:35', NULL, NULL, '[]'),
(39, 'P-ANCA', '138', '', 5500.00, '3-5 cc Clotted Blood/Serum', 'After 3 Days', 'SPECIAL', '3', 'Special Test Reports', '[]', 1, 'admin', '2024-12-15 14:08:45', NULL, NULL, '[]'),
(40, 'Androgen Level', '139', '', 2100.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Androgen Level', '[]', 1, 'admin', '2024-12-15 14:09:49', NULL, NULL, '[]'),
(41, 'Androstenidione Level', '140', '', 1600.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Androstenidione Level', '[]', 1, 'admin', '2024-12-15 14:12:26', NULL, NULL, '[]'),
(42, 'Anemia Absolute Values', '141', '', 200.00, '2-3 Blood in EDTA', 'After 1 Day', 'ROUTINE', '1', 'Anemia Absolute Values', '[]', 1, 'admin', '2024-12-15 15:07:46', NULL, NULL, '[]'),
(43, 'Anti B2-Glycoprotein (IgG/IgM)', '142', '', 700.00, 'blood sample', 'After 1 Week', 'SPECIAL', '7', 'Anti B2-Glycoprotein (IgG/IgM)', '[]', 1, 'admin', '2024-12-15 15:09:45', NULL, NULL, '[]'),
(44, 'Anti B2-Glycoprotein 1 Screen', '143', '', 700.00, 'blood sample', 'After 1 Week', 'SPECIAL', '7', 'Anti B2-Glycoprotein 1 Screen', '[]', 1, 'admin', '2024-12-15 15:10:48', NULL, NULL, '[]'),
(45, 'Anti Cardiac Abs (IFA Method)', '144', '', 700.00, 'Plasma or serum', 'After 1 Week', 'SPECIAL', '7', 'BIO-CHEMISTRY REPORT', '[]', 1, 'admin', '2024-12-15 15:12:43', NULL, NULL, '[]'),
(46, 'Anti Cardiolipin IgG', '145', '', 4200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Cardiolipin IgG', '[]', 1, 'admin', '2024-12-15 17:07:26', NULL, NULL, '[]'),
(47, 'Anti Cardiolipin IgM', '146', '', 4200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Cardiolipin IgM', '[]', 1, 'admin', '2024-12-15 17:08:23', NULL, NULL, '[]'),
(48, 'Anti Centromer Abs', '147', '', 1100.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Centromer Abs', '[]', 1, 'admin', '2024-12-15 17:09:16', NULL, NULL, '[]'),
(49, 'Anti Cytoplasmic Antibodies', '148', '', 1200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Cytoplasmic Antibodies', '[]', 1, 'admin', '2024-12-15 17:10:25', NULL, NULL, '[]'),
(50, 'Anti DNA', '149', '', 1760.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '7', 'anti DNA', '[]', 1, 'admin', '2024-12-15 17:11:59', NULL, NULL, '[]'),
(51, 'anti', '150', '', 0.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '7', 'serology report', '[]', 1, 'admin', '2024-12-15 17:13:32', NULL, NULL, '[]'),
(52, 'Anti DS DNA IgM', '152', '', 1760.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'anti DS DNA lgM', '[]', 1, 'admin', '2024-12-15 17:15:31', NULL, NULL, '[]'),
(53, 'Anti DS DNA IgG', '151', '', 1760.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti DS DNA IgG', '[]', 1, 'admin', '2024-12-15 17:16:55', NULL, NULL, '[]'),
(54, 'Anti Endomysial Abs', '153', '', 1700.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Endomysial Abs', '[]', 1, 'admin', '2024-12-15 17:18:53', NULL, NULL, '[]'),
(55, 'Anti Epstein Barr Virus IgG (EBV)', '154', '', 700.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Epstein Barr Virus IgG (EBV)', '[]', 1, 'admin', '2024-12-15 17:20:16', NULL, NULL, '[]'),
(56, 'Anti Epstein Barr Virus IgM (EBV)', '155', '', 700.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Epstein Barr Virus IgM (EBV)', '[]', 1, 'admin', '2024-12-15 17:21:37', NULL, NULL, '[]'),
(57, 'Anti GBM (Glomerular Basement Membrane)', '156', '', 1200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti GBM ', '[]', 1, 'admin', '2024-12-15 17:22:54', NULL, NULL, '[]'),
(58, 'Anti Gliadin Antibodies IgA', '157', '', 2060.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Gliadin  IgA', '[]', 1, 'admin', '2024-12-15 17:24:39', NULL, NULL, '[]'),
(59, 'Anti Gliadin Antibodies IgG', '158', '', 2060.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Gliadin  IgG', '[]', 1, 'admin', '2024-12-15 17:25:53', NULL, NULL, '[]'),
(60, 'Anti Gliadin Antibodies IgM', '159', '', 2060.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Gliadin IgM', '[]', 1, 'admin', '2024-12-15 17:27:13', NULL, NULL, '[]'),
(61, 'Anti HB core (Total)', '160', '', 1200.00, '3-5 cc Clotted Blood/Serum', 'After 4 Days', 'SPECIAL', '7', 'hepatitis virological report', '[]', 1, 'admin', '2024-12-15 17:29:30', NULL, NULL, '[]'),
(63, 'Anti HB core IgG', '161', '', 1200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'hepatitis virological report', '[]', 1, 'admin', '2024-12-15 18:59:08', NULL, NULL, '[]'),
(64, 'Anti HB core IgM', '162', '', 1200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'hepatitis virological report', '[]', 1, 'admin', '2024-12-15 19:00:39', NULL, NULL, '[]'),
(65, 'Anti HBe', '163', '', 1500.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'hepatitis virological report', '[]', 1, 'admin', '2024-12-15 19:01:53', NULL, NULL, '[]'),
(66, 'Anti HbSAg (ELISA)', '164', '', 1500.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'hepatitis virological report', '[]', 1, 'admin', '2024-12-15 11:06:51', NULL, NULL, '[]'),
(67, 'Anti HCV (ELISA)', '165', '', 2200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '1', 'hepatitis virological report', '[]', 1, 'admin', '2024-12-15 11:08:13', NULL, NULL, '[]'),
(68, 'Anti HCV (Screening)', '167', '', 800.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'screening report', '[]', 1, 'admin', '2024-12-15 11:10:14', NULL, NULL, '[]'),
(69, 'Anti HDV IgM', '168', '', 1500.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'HEPATITIS VIROLOGICAL REPORT', '[]', 1, 'admin', '2024-12-15 11:12:00', NULL, NULL, '[]'),
(70, 'Anti HEV IgG', '169', '', 3200.00, '3-5 cc Clotted Blood/Serum', 'After 3 Days', 'SPECIAL', '3', 'HEPATITIS VIROLOGICAL REPORT', '[]', 1, 'admin', '2024-12-15 11:13:13', NULL, NULL, '[]'),
(71, 'Anti HEV IgM', '170', '', 3200.00, '3-5 cc Clotted Blood/Serum', 'After 3 Days', 'SPECIAL', '3', 'Hepatitis  virological Report', '[]', 1, 'admin', '2024-12-15 11:14:37', NULL, NULL, '[]'),
(72, 'Anti HGB', '171', '', 1950.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'HEPATITIS VIROLOGICAL REPORT', '[]', 1, 'admin', '2024-12-15 11:21:10', NULL, NULL, '[]'),
(73, 'Anti HGV IgG', '172', '', 1950.00, '3-5 cc Clotted Blood/Serum', 'After 3 Days', 'SPECIAL', '3', 'HEPATITIS VIROLOGICAL REPORT', '[]', 1, 'admin', '2024-12-15 11:22:22', NULL, NULL, '[]'),
(74, 'Anti HGV IgM', '173', '', 1950.00, '3-5 cc Clotted Blood/Serum', 'After 3 Days', 'SPECIAL', '3', 'HEPATITIS VIROLOGICAL REPORT', '[]', 1, 'admin', '2024-12-15 11:23:23', NULL, NULL, '[]'),
(75, 'Anti HIV-1 & 2 (ELISA)', '174', '', 3000.00, '3-5 cc Clotted Blood/Serum', 'After 2 Days', 'SPECIAL', '2', 'AIDS TEST', '[]', 1, 'admin', '2024-12-15 11:24:44', NULL, NULL, '[]'),
(76, 'Anti HIV (Screening)', '175', '', 800.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', ' SCREENING REPORT', '[]', 1, 'admin', '2024-12-15 11:26:23', NULL, NULL, '[]'),
(77, 'Anti HSV IgG (1+2)', '176', '', 2500.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'HEPATITIS VIROLOGICAL REPORT', '[]', 1, 'admin', '2024-12-15 11:28:10', NULL, NULL, '[]'),
(78, 'Anti HSV IgM (1+2)', '177', '', 2500.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'HEPATITIS VIROLOGICAL REPORT', '[]', 1, 'admin', '2024-12-15 11:29:10', NULL, NULL, '[]'),
(79, 'Anti JO-1', '178', '', 1200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti JO-1', '[]', 1, 'admin', '2024-12-15 11:30:06', NULL, NULL, '[]'),
(80, 'Anti KLM (Kidney Liver Microsomal Abs)', '179', '', 1400.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti L.K.M', '[]', 1, 'admin', '2024-12-15 11:31:05', NULL, NULL, '[]'),
(81, 'Anti Lacto Ferrin', '180', '', 2500.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Lacto Ferrin', '[]', 1, 'admin', '2024-12-15 11:32:05', NULL, NULL, '[]'),
(82, 'Anti Leucocyte Plasma Abs', '181', '', 1050.00, '2-3 cc Blood in EDTA', 'After 1 Week', 'SPECIAL', '7', 'Anti Leucocyte Plasma Abs', '[]', 1, 'admin', '2024-12-15 11:33:40', NULL, NULL, '[]'),
(83, 'Anti Microsomal Abs (AMA)', '182', '', 1225.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Microsomal Abs (AMA)', '[]', 1, 'admin', '2024-12-15 11:35:17', NULL, NULL, '[]'),
(84, 'Anti Mitochondrial Antibody', '183', '', 1050.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Mitochondrial Antibody', '[]', 1, 'admin', '2024-12-15 11:40:29', NULL, NULL, '[]'),
(85, 'Anti Nucleosome (Lupus Abs SLE)', '184', '', 1900.00, 'nill', 'After 1 Week ', 'SPECIAL', '7', 'Anti Nucleosome ', '[]', 1, 'admin', '2024-12-15 11:42:09', NULL, NULL, '[]'),
(86, 'Anti Nucleotide Abs', '185', '', 1100.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Nucleotide Abs', '[]', 1, 'admin', '2024-12-15 11:43:13', NULL, NULL, '[]'),
(87, 'Anti Phospholipid IgG', '186', '', 3600.00, '3-5 cc Clotted Blood/Serum', 'After 2 Days', 'SPECIAL', '2', 'SPECIAL CHEMISTRY REPORT', '[]', 1, 'admin', '2024-12-15 11:44:36', NULL, NULL, '[]'),
(88, 'Anti Phospholipid IgM', '187', '', 3600.00, '3-5 cc Clotted Blood/Serum', 'After 2 Days', 'SPECIAL', '2', 'Anti Phospholipid IgM', '[]', 1, 'admin', '2024-12-15 11:45:18', NULL, NULL, '[]'),
(89, 'Anti Prothrombine (Screen)', '188', '', 950.00, 'nill', 'After 1 Week', 'SPECIAL', '7', 'Anti Prothrombine (Screen)', '[]', 1, 'admin', '2024-12-15 11:46:23', NULL, NULL, '[]'),
(90, 'Anti Prothrombine IgA', '189', '', 950.00, 'nill', 'After 1 Week', 'SPECIAL', '7', 'Anti Prothrombine IgA', '[]', 1, 'admin', '2024-12-15 11:47:12', NULL, NULL, '[]'),
(91, 'Anti Prothrombine IgG', '190', '', 950.00, 'nill', 'After 1 Week', 'SPECIAL', '7', 'Anti Prothrombine IgG', '[]', 1, 'admin', '2024-12-15 11:48:02', NULL, NULL, '[]'),
(92, 'Anti SCL-70', '191', '', 1100.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti SCL-70', '[]', 1, 'admin', '2024-12-15 11:48:59', NULL, NULL, '[]'),
(93, 'Anti Smooth Muscle Abs (SMA)', '192', '', 1200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Smooth Muscle Abs ', '[]', 1, 'admin', '2024-12-15 11:50:20', NULL, NULL, '[]'),
(94, 'Anti Sperm Antibodies', '193', '', 1100.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti Sperm Antibodies', '[]', 1, 'admin', '2024-12-15 11:51:19', NULL, NULL, '[]'),
(95, 'Anti SS-A (RO)', '194', '', 1100.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti SS-A (RO)', '[]', 1, 'admin', '2024-12-15 11:53:07', NULL, NULL, '[]'),
(96, 'Anti SS-B (LA)', '195', '', 1100.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Anti SS-B (LA)', '[]', 1, 'admin', '2024-12-15 11:54:02', NULL, NULL, '[]'),
(97, 'Anti Thrombin-III', '196', '', 2150.00, 'Citrate Tube (From Lab)', 'After 2 Weeks', 'SPECIAL', '14', 'Anti Thrombin-III', '[]', 1, 'admin', '2024-12-15 12:16:21', NULL, NULL, '[]'),
(98, 'Anti Thyroglobulin Antibodies', '197', '', 0.00, '3-5 cc Clotted Blood/Serum', 'After 2 Days', 'SPECIAL', '2', 'Anti Thyroglobulin Antibodies', '[]', 1, 'admin', '2024-12-15 12:19:14', NULL, NULL, '[]'),
(99, 'Anti Tissue Transglutaminase IgA', '198', '', 2200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'special report', '[]', 1, 'admin', '2024-12-15 07:01:57', NULL, NULL, '[]'),
(100, 'Anti Tissue Transglutaminase IgG & IgA', '199', '', 2000.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week ', 'SPECIAL', '7', 'Special report', '[]', 1, 'admin', '2024-12-15 07:03:24', NULL, NULL, '[]'),
(101, 'APO Lipoprotein A', '200', '', 1100.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Special report', '[]', 1, 'admin', '2024-12-15 07:04:46', NULL, NULL, '[]'),
(102, 'APO Lipoprotein B', '201', '', 1100.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Special Report', '[]', 1, 'admin', '2024-12-15 07:05:45', NULL, NULL, '[]'),
(103, 'APTT (Activated Partial Thromboplastin Time)', '20', '', 1000.00, 'Citrate Tube (From Lab)', 'After 1 Day', 'ROUTINE', '0', 'Haematology report', '[]', 1, 'admin', '2024-12-15 07:12:06', NULL, NULL, '[]'),
(104, 'Arterial Blood Gases (ABG\'s)', '203', '', 800.00, '3-5 cc Arterial Heparinized Sample', 'After 1 Day', 'SPECIAL', '0', 'Arterial Blood Gases (ABG\'s)', '[]', 1, 'admin', '2024-12-15 07:14:40', NULL, NULL, '[]'),
(105, 'Ascitic Fluid For AFB Culture', '204', '', 2000.00, 'Specimen Fluid', 'After 6 Weeks', 'SPECIAL', '42', 'Ascitic Fluid For AFB Culture', '[]', 1, 'admin', '2024-12-15 07:19:22', NULL, NULL, '[]'),
(106, 'Ascitic Fluid For AFB Smear / Z.N.', '205', '', 400.00, 'Specimen Fluid', 'After 1 Day', 'ROUTINE', '0', 'Ascitic Fluid For AFB Smear / Z.N.', '[]', 1, 'admin', '2024-12-15 07:21:22', NULL, NULL, '[]'),
(107, 'Ascitic Fluid For Amylase', '206', '', 800.00, 'Specimen Fluid', 'After 1 Day', 'ROUTINE', '0', 'Ascitic Fluid For Amylase', '[]', 1, 'admin', '2024-12-15 07:26:12', NULL, NULL, '[]'),
(108, 'Ascitic Fluid For Analysis (C/E)', '207', '', 1400.00, 'Specimen Fluid', 'After 1 Day', 'ROUTINE', '1', 'Ascitic Fluid For Analysis (C/E)', '[]', 1, 'admin', '2024-12-15 07:29:16', NULL, NULL, '[]'),
(109, 'Ascitic Fluid For C/S', '208', '', 1000.00, 'Specimen Fluid', 'After 7 Days', 'SPECIAL', '7', 'Ascitic Fluid For C/S', '[]', 1, 'admin', '2024-12-15 09:25:52', NULL, NULL, '[]'),
(110, 'Ascitic Fluid For Cytology', '209', '', 1000.00, 'Specimen Fluid', 'After 1 Day', 'SPECIAL', '7', 'Ascitic Fluid For Cytology', '[]', 1, 'admin', '2024-12-15 09:27:13', NULL, NULL, '[]'),
(111, 'Ascitic Fluid For Gram Stain', '210', '', 400.00, 'Specimen Fluid', 'After 1 Day', 'ROUTINE', '0', 'Ascitic Fluid For Gram Stain', '[]', 1, 'admin', '2024-12-15 09:28:22', NULL, NULL, '[]'),
(112, 'Ascitic Fluid For LDH', '211', '', 600.00, 'Specimen Fluid', 'After 1 Day', 'SPECIAL', '1', 'Ascitic Fluid For LDH', '[]', 1, 'admin', '2024-12-15 09:29:55', NULL, NULL, '[]'),
(113, 'Ascitic Fluid For Malignant Cell', '212', '', 400.00, 'Specimen Fluid', 'After 1 Day', 'SPECIAL', '1', 'Ascitic Fluid For Malignant Cell', '[]', 1, 'admin', '2024-12-15 09:32:06', NULL, NULL, '[]'),
(114, 'Ascitic Fluid For MTB By PCR', '213', '', 4000.00, 'Specimen Fluid', 'After 10 Days', 'SPECIAL', '10', 'Ascitic Fluid For MTB By PCR', '[]', 1, 'admin', '2024-12-15 09:32:58', NULL, NULL, '[]'),
(115, 'Ascitic Fluid For Protein', '214', '', 600.00, 'Specimen Fluid', 'After 1 Day', 'ROUTINE', '7', 'Ascitic Fluid For Protein', '[]', 1, 'admin', '2024-12-15 09:34:55', NULL, NULL, '[]'),
(116, 'ASO TITRE', '215', '', 1600.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'Serology Report', '[]', 1, 'admin', '2024-12-15 09:36:28', NULL, NULL, '[]'),
(117, 'Aspergillus Abs', '216', '', 2050.00, '3-5 cc Clotted Blood/Serum', 'After 1 Week', 'SPECIAL', '7', 'Aspergillus Abs', '[]', 1, 'admin', '2024-12-15 09:39:50', NULL, NULL, '[]'),
(118, 'AST (SGOT)', '217', '', 500.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'Cardiac Enzyme report', '[]', 1, 'admin', '2024-12-15 09:41:19', NULL, NULL, '[]'),
(119, 'Atypical Lymphocytes', '218', '', 150.00, '3 cc Blood in EDTA', 'After 1 Week', 'SPECIAL', '7', 'Atypical Lymphocytes', '[]', 1, 'admin', '2024-12-15 09:43:28', NULL, NULL, '[]'),
(120, 'Azure Granules', '219', '', 300.00, 'Random urine', 'After 1 Day', 'SPECIAL', '1', 'Azure Granules', '[]', 1, 'admin', '2024-12-15 09:44:49', NULL, NULL, '[]'),
(121, 'B-2 Micro Globulin', '220', '', 1800.00, '3-5 cc Clotted Blood/Serum', 'After 2 Days', 'SPECIAL', '1', 'B-2 Micro Globulin', '[]', 1, 'admin', '2024-12-15 09:46:25', NULL, NULL, '[]'),
(122, 'Bacterial Colony Count', '221', '', 1200.00, 'Any Specimen', 'After 3 Days', 'SPECIAL', '3', 'Bacterial Colony Count', '[]', 1, 'admin', '2024-12-15 10:21:19', NULL, NULL, '[]'),
(123, 'Bence Jones Protein (Urine)', '222', '', 1000.00, 'Random Urine', 'After 1 Day', 'ROUTINE', '0', 'Bence Jones Protein (Urine)', '[]', 1, 'admin', '2024-12-15 10:22:47', NULL, NULL, '[]'),
(124, 'Beta HCG', '223', '', 2000.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '7', 'ENDOCRINOLOGY REPORT', '[]', 1, 'admin', '2024-12-15 10:25:08', NULL, NULL, '[]'),
(125, 'Bicarbonate (HCO3)', '224', '', 800.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'SERUM ELECTROLYTES REPORT', '[]', 1, 'admin', '2024-12-15 10:26:02', NULL, NULL, '[]'),
(126, 'Bile Acid', '225', '', 3800.00, '3-5 cc Clotted Blood/Serum', 'After 2 Days', 'SPECIAL', '2', 'SPECIAL TEST REPORT', '[]', 1, 'admin', '2024-12-15 10:26:51', NULL, NULL, '[]'),
(127, 'BIL SGPT SGOT ALK PROT ALB', '226', '', 900.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'BIL SGPT SGOT ALK PROT AL', '[]', 1, 'admin', '2024-12-15 10:28:28', NULL, NULL, '[]'),
(128, 'BIL SGPT SGOT ALK PROT ALB GGT', '227', '', 1000.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'LIVER FUNCTIONS REPORT', '[]', 1, 'admin', '2024-12-15 10:30:17', NULL, NULL, '[]'),
(129, 'Bilirubin Direct (Conjugated)', '228', '', 700.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '1', 'LIVER FUNCTIONS REPORT', '[]', 1, 'admin', '2024-12-15 10:32:37', NULL, NULL, '[]'),
(130, 'Bilirubin Indirect (Unconjugated)', '229', '', 550.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'LIVER FUNCTIONS REPORT', '[]', 1, 'admin', '2024-12-15 10:34:07', NULL, NULL, '[]'),
(131, 'Bilirubin Total', '230', '', 400.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'LIVER FUNCTIONS REPORT', '[]', 1, 'admin', '2024-12-15 10:35:16', NULL, NULL, '[]'),
(132, 'Biopsy Endometrial Curettage (D&C)', '231', '', 5500.00, 'Specimen', 'After 1 Week', 'SPECIAL', '7', 'HISTOPATHOLOGY REPORT', '[]', 1, 'admin', '2024-12-15 10:36:19', NULL, NULL, '[]'),
(133, 'Biopsy For H/P (Small)', '232', '', 4000.00, 'Specimen', 'After 1 Week', 'SPECIAL', '7', 'HISTOPATHOLOGY REPORT', '[]', 1, 'admin', '2024-12-15 10:37:10', NULL, NULL, '[]'),
(134, 'Biopsy for H/P (Small)', '233', '', 5000.00, 'Specimen', 'After 1 Week', 'SPECIAL', '7', 'HISTOPATHOLOGY REPORT', '[]', 1, 'admin', '2024-12-15 10:38:50', NULL, NULL, '[]'),
(135, 'Biopsy Extra Large', '234', '', 7000.00, 'Specimen', 'After 1 Week', 'SPECIAL', '7', 'HISTOPATHOLOGY REPORT', '[]', 1, 'admin', '2024-12-15 10:39:39', NULL, NULL, '[]'),
(136, 'Biopsy Large', '235', '', 6000.00, 'Specimen', 'After 1 Week', 'SPECIAL', '7', 'HISTOPATHOLOGY REPORT', '[]', 1, 'admin', '2024-12-15 10:40:38', NULL, NULL, '[]'),
(137, 'Biopsy Appendex', '236', '', 5000.00, 'Specimen', 'After 1 Week', 'SPECIAL', '7', 'HISTOPATHOLOGY REPORT', '[]', 1, 'admin', '2024-12-15 10:41:29', NULL, NULL, '[]'),
(138, 'Bleeding Time', '237', '', 500.00, 'Contact Lab', 'After 1 Day', 'ROUTINE', '0', 'HAEMATOLOGY REPORT', '[]', 1, 'admin', '2024-12-15 10:42:24', NULL, NULL, '[]'),
(139, 'Retic Count', '238', '', 500.00, '3 cc Blood In EDTA', 'After 1 Day', 'ROUTINE', '0', 'Blood C/E Retic Count', '[]', 1, 'admin', '2024-12-15 10:45:59', NULL, NULL, '[]'),
(140, 'CBC-Blood Complete Examination', '239', '', 700.00, '3 cc Blood In EDTA', 'After 1 Day', 'ROUTINE', '0', 'HAEMATOLOGY REPORT', '[]', 1, 'admin', '2024-12-15 10:46:44', NULL, NULL, '[]'),
(141, 'Heamogram', '240', '', 300.00, '3 cc Blood In EDTA', 'After 1 Day', 'SPECIAL', '0', 'Blood Count Report', '[]', 1, 'admin', '2024-12-15 10:47:40', NULL, NULL, '[]'),
(142, 'Blood Culture For Anaerobic', '241', '', 1200.00, 'Culture Vial', 'After 1 Week', 'SPECIAL', '7', 'Blood Culture For Anaerobic', '[]', 1, 'admin', '2024-12-15 10:48:29', NULL, NULL, '[]'),
(143, 'Blood Eosinophil Count', '242', '', 370.00, '2-3 cc Blood In EDTA', 'After 1 Day', 'SPECIAL', '1', 'Blood Film For Filariasis', '[]', 1, 'admin', '2024-12-15 10:49:35', NULL, NULL, '[]'),
(144, 'Blood Film For Filariasis', '243', '', 600.00, '3 cc Blood In EDTA', 'After 1 Day', 'SPECIAL', '1', 'Blood For C/S', '[]', 1, 'admin', '2024-12-15 10:50:54', NULL, NULL, '[]'),
(145, 'Blood For C/S', '244', '', 2200.00, 'culture vial', 'After 1 Week', 'SPECIAL', '7', 'Blood For C/S', '[]', 1, 'admin', '2024-12-15 10:52:05', NULL, NULL, '[]'),
(146, 'Blood for MTB by PCR', '245', '', 5000.00, '3-5 cc Clotted Blood/Serum', 'After 10 Days', 'SPECIAL', '10', 'Blood For MTB by PCR', '[]', 1, 'admin', '2024-12-15 10:52:53', NULL, NULL, '[]'),
(147, 'Blood Group & Cross Match', '246', '', 2500.00, '3 cc Blood in EDTA/Clotted', 'After 1 Day', 'ROUTINE', '0', 'Blood Group & Cross Match Report', '[]', 1, 'admin', '2024-12-15 07:50:50', NULL, NULL, '[]'),
(148, 'Blood Group & Rh Factor', '247', '', 500.00, '3 cc Blood in EDTA', 'After 1 Day', 'ROUTINE', '0', 'Blood Group Report', '[]', 1, 'admin', '2024-12-15 07:51:42', NULL, NULL, '[]'),
(149, 'Blood Osmolality', '248', '', 650.00, '2-3 cc Blood in EDTA', 'After 2 Days', 'SPECIAL', '2', 'Blood Osmolality', '[]', 1, 'admin', '2024-12-15 07:52:25', NULL, NULL, '[]'),
(150, 'Blood Smear for MP', '249', '', 600.00, '2-3 cc Blood in EDTA', 'After 1 Day', 'ROUTINE', '0', 'Blood Smear for MP', '[]', 1, 'admin', '2024-12-15 07:53:27', NULL, NULL, '[]'),
(151, 'RFT/Renal Function', '250', '', 1200.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'RFT/Renal Function', '[]', 1, 'admin', '2024-12-15 07:54:24', NULL, NULL, '[]'),
(152, 'Bone Marrow Biopsy', '251', '', 2500.00, 'Contact Lab', 'Contact Lab', 'SPECIAL', '7', 'Bone Marrow Biopsy report', '[]', 1, 'admin', '2024-12-15 07:55:16', NULL, NULL, '[]'),
(153, 'Bone Marrow Slides Review', '252', '', 1600.00, 'Slides', 'After 5 Days', 'SPECIAL', '7', 'Bone Marrow Biopsy Report', '[]', 1, 'admin', '2024-12-15 07:56:01', NULL, NULL, '[]'),
(154, 'Breast Milk for C/E', '253', '', 1000.00, 'Breast Milk', 'After 1 Day', 'ROUTINE', '1', 'Milk Analysis Report', '[]', 1, 'admin', '2024-12-15 07:56:56', NULL, NULL, '[]'),
(155, 'Breast Milk for Culture', '254', '', 1200.00, 'Breast Milk', 'After 3 Days', 'SPECIAL', '7', 'Breast Milk for Culture', '[]', 1, 'admin', '2024-12-15 07:57:45', NULL, NULL, '[]'),
(156, 'Breast Milk for Cytology', '255', '', 600.00, 'Breast Milk', 'After 3 Days', 'SPECIAL', '7', 'Breast Milk for Cytology', '[]', 1, 'admin', '2024-12-15 07:58:24', NULL, NULL, '[]'),
(157, 'Breast Milk for Gram Stains', '256', '', 600.00, 'Breast Milk', 'After 1 Day', 'ROUTINE', '7', 'Breast Milk for Gram Stains', '[]', 1, 'admin', '2024-12-15 07:59:13', NULL, NULL, '[]'),
(158, 'Breast Milk for ZN', '257', '', 600.00, 'Breast Milk', 'After 1 Day', 'ROUTINE', '0', 'Breast Milk for ZN', '[]', 1, 'admin', '2024-12-15 08:00:00', NULL, NULL, '[]'),
(159, 'Bronchial Washing AFB Culture', '258', '', 1500.00, 'Specimen Fluid', 'After 6 Weeks', 'SPECIAL', '6', 'Bronchial Washing AFB Culture Report', '[]', 1, 'admin', '2024-12-15 08:02:14', NULL, NULL, '[]'),
(160, 'Bronchial Washing C/S', '259', '', 1200.00, 'Specimen Fluid', 'After 3 Days', 'SPECIAL', '6', 'Bronchial Washing C/S Report', '[]', 1, 'admin', '2024-12-15 08:11:21', NULL, NULL, '[]'),
(161, 'Bronchial Washing for Analysis', '260', '', 900.00, 'Specimen Fluid', 'After 1 Day', 'SPECIAL', '7', 'Bronchial Washing Report', '[]', 1, 'admin', '2024-12-15 08:12:07', NULL, NULL, '[]'),
(162, 'Bronchial Washing for Cytology', '261', '', 1000.00, 'Specimen Fluid', 'After 3 Days', 'SPECIAL', '7', 'Bronchial Washing for Cytology', '[]', 0, 'admin', '2024-12-15 08:12:55', NULL, '2024-12-15 18:07:57', '[]'),
(163, 'Bronchial Washing For Gram', '262', '', 1000.00, 'Specimen Fluid', 'After 1 Day', 'ROUTINE', '7', 'Bronchial Washing for Gram Report', '[]', 1, 'admin', '2024-12-15 08:13:39', NULL, NULL, '[]'),
(164, 'Bronchial Washing For ZN', '263', '', 500.00, 'Specimen Fluid', 'After 1 Day', 'SPECIAL', '7', 'Bronchial Washing For ZN', '[]', 1, 'admin', '2024-12-15 08:14:24', NULL, NULL, '[]'),
(165, 'Bronchial Washing MTB By PCR', '264', '', 6000.00, 'Specimen Fluid', 'After 10 Days', 'SPECIAL', '10', 'Bronchial Washing MTB By PCR Report', '[]', 1, 'admin', '2024-12-15 08:15:14', NULL, NULL, '[]'),
(166, 'Brucella Test', '265', '', 275.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'SPECIAL', '1', 'Brucella Test Report', '[]', 1, 'admin', '2024-12-15 08:16:09', NULL, NULL, '[]'),
(167, 'Buceal Smear for Bar Bodies', '266', '', 550.00, 'Contact Lab', 'After 1 Day', 'SPECIAL', '1', 'Buceal Smear for Bar Bodies Report', '[]', 1, 'admin', '2024-12-15 08:17:00', NULL, NULL, '[]'),
(168, 'BUN', '267', '', 500.00, '3-5 cc Clotted Blood/Serum', 'After 1 Day', 'ROUTINE', '0', 'Renal Function Report', '[]', 1, 'admin', '2024-12-15 08:17:44', NULL, NULL, '[]'),
(169, 'C-2 Monitoring', '268', '', 1400.00, '3 cc Blood in EDTA', 'After 2 Days', 'SPECIAL', '2', 'C-2 Monitoring', '[]', 1, 'admin', '2024-12-15 08:18:34', NULL, NULL, '[]'),
(170, 'C-3', '269', '', 950.00, '3-5 cc Clotted Blood/Serum', 'After 5 Days', 'SPECIAL', '5', 'Special Biochemistry Report', '[]', 1, 'admin', '2024-12-15 08:19:16', NULL, NULL, '[]'),
(171, 'C-4', '270', '', 950.00, '3-5 cc Clotted Blood/Serum', 'After 5 Days', 'SPECIAL', '5', 'Special Biochemistry Report', '[]', 1, 'admin', '2024-12-15 08:20:00', NULL, NULL, '[]');

-- Procedure For Backup And Copy
DELIMITER //

CREATE PROCEDURE backup_and_copy(IN source_db VARCHAR(255), IN backup_db VARCHAR(255))
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE tbl_name VARCHAR(255);
    DECLARE cur CURSOR FOR
        SELECT table_name FROM information_schema.tables WHERE table_schema = source_db;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Create the backup database dynamically
    SET @create_db_query = CONCAT('CREATE DATABASE IF NOT EXISTS `', backup_db, '`');
    PREPARE stmt FROM @create_db_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Loop through all tables in the source database
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO tbl_name;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Copy data from each table to the backup database
        SET @copy_query = CONCAT('CREATE TABLE `', backup_db, '`.`', tbl_name, '` LIKE `', source_db, '`.`', tbl_name, '`');
        PREPARE stmt FROM @copy_query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET @insert_query = CONCAT('INSERT INTO `', backup_db, '`.`', tbl_name, '` SELECT * FROM `', source_db, '`.`', tbl_name, '`');
        PREPARE stmt FROM @insert_query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    END LOOP;
    CLOSE cur;

    -- Return the name of the backup database
    SELECT backup_db AS backup_database_name;
END//

DELIMITER ;
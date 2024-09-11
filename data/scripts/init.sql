CREATE DATABASE IF NOT EXISTS `nxt-hospital-testing`;

USE `nxt-hospital-testing`;

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
  `bill_slip_uuid` varchar(50) NOT NULL,
  `bill_patient_mrid` varchar(50) NOT NULL,
  `bill_vitals` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `bill_total` int(11) NOT NULL DEFAULT 0,
  `bill_paid` int(11) NOT NULL DEFAULT 0,
  `bill_discount` int(11) NOT NULL DEFAULT 0,
  `bill_balance` int(11) NOT NULL DEFAULT 0,
  `bill_delete` int(11) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(50) DEFAULT NULL,
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
  `doctor_address` varchar(255) DEFAULT NULL,
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
  `report_date` date NOT NULL,
  `reference` varchar(100) DEFAULT NULL,
  `consultant` varchar(100) NOT NULL DEFAULT 'self',
  `invoice_delete` int(11) NOT NULL DEFAULT 1,
  `total` int(11) NOT NULL DEFAULT 0,
  `paid` int(11) NOT NULL DEFAULT 0,
  `discount` int(11) NOT NULL DEFAULT 0,
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
  `patient_mrid` varchar(50) NOT NULL,
  `test_results` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  `report_delete` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(50) NOT NULL,
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
  `slip_department` varchar(20) DEFAULT NULL,
  `slip_doctor` varchar(20) NOT NULL,
  `slip_appointment` varchar(20) DEFAULT 'walk_in_patient',
  `slip_fee` int(10) DEFAULT NULL,
  `slip_discount` int(10) DEFAULT NULL,
  `slip_total` int(10) DEFAULT NULL,
  `slip_procedure` varchar(255) DEFAULT NULL,
  `slip_type` varchar(20) NOT NULL,
  `slip_subtype` varchar(20) DEFAULT NULL,
  `slip_delete` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) NOT NULL,
  PRIMARY KEY (`slip_id`),
  UNIQUE KEY `slip_uuid` (`slip_uuid`),
  KEY `fk_slip_department_uuid` (`slip_department`),
  KEY `fk_slip_doctor_uuid` (`slip_doctor`),
  KEY `fk_table_slip_type_uuid` (`slip_type`),
  KEY `fk_table_slip_subtype_uuid` (`slip_subtype`),
  KEY `fk_slip_appointment_uuid` (`slip_appointment`)
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
  `component_name` varchar(100) NOT NULL,
  `component_unit` varchar(255) NOT NULL,
  `normal_range_male` varchar(50) DEFAULT NULL,
  `normal_range_female` varchar(50) DEFAULT NULL,
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


INSERT INTO `nxt_user` (`user_id`, `user_name`, `user_email`, `user_mobile`, `user_username`, `user_password`, `user_status`, `user_permission`, `user_last_login`, `user_photo`, `user_address`, `created_at`, `created_by`, `updated_at`, `updated_by`) VALUES (
  1, 'Administrator', NULL, NULL, 'admin', '$2a$10$D3HzBNl77kmSdXxNUCpNqOglNmqjqRlaCKUAkLre8wa/DnTWeaNMi', 1, 'admin', NULL, NULL, NULL, CURRENT_TIMESTAMP(), 'admin', NULL, NULL);

INSERT INTO `nxt_permission` (`permission_id`, `permission_name`, `permission_alias`, `permission_description`, `component_access`, `read_permission`, `write_permission`, `delete_permission`, `permission_status`, `created_at`, `created_by`, `updated_at`, `updated_by`) VALUES
(1, 'Administrator', 'admin', 'permission with complete system access', 'Appointment,Appointment-Type,Category,Department,Doctor,Doctor-Type,Laboratory-Test,Test-Component,Patient,Room,Service,Slip,Slip-Subtype,User,Recent-Activity', 1, 1, 1, 1, CURRENT_TIMESTAMP(), 'admin', NULL, NULL);
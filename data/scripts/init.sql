CREATE DATABASE IF NOT EXISTS `nxt-hospital`;

USE `nxt-hospital`;

CREATE TABLE IF NOT EXISTS `nxt_appointment` (
  `appointment_id` int(11) NOT NULL AUTO_INCREMENT,
  `appointment_uuid` varchar(20) NOT NULL,
  `appointment_patient_mrid` varchar(20) NOT NULL,
  `appointment_patient_mobile` varchar(15) NOT NULL,
  `appointment_type_alias` varchar(100) NOT NULL,
  `appointment_department_alias` varchar(20) NOT NULL,
  `appointment_doctor_alias` varchar(20) NOT NULL,
  `appointment_at` datetime NOT NULL,
  `appointment_status` varchar(10) NOT NULL DEFAULT 'pending',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`appointment_id`),
  UNIQUE KEY `appointment_uuid` (`appointment_uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_appointment_type` (
  `appointment_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `appointment_type_name` varchar(100) NOT NULL,
  `appointment_type_alias` varchar(100) NOT NULL,
  `appointment_type_description` text DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`appointment_type_id`),
  UNIQUE KEY `appointment_type_alias` (`appointment_type_alias`)
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
  UNIQUE KEY `doctor_alias` (`doctor_alias`)
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
  `created_by` varchar(100) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  PRIMARY KEY (`test_id`),
  UNIQUE KEY `test_code` (`test_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `nxt_patient` (
  `patient_id` int(11) NOT NULL AUTO_INCREMENT,  
  `patient_mrid` varchar(20) NOT NULL,
  `patient_name` varchar(100) NOT NULL,
  `patient_mobile` varchar(15) NOT NULL,
  `patient_email` varchar(100) DEFAULT NULL,
  `patient_gender` varchar(20) NOT NULL,
  `patient_age` varchar(10) NOT NULL,
  `patient_blood_group` varchar(10) NOT NULL,
  `patient_address` varchar(255) NOT NULL,
  `patient_delete` int(10) NOT NULL DEFAULT 1,
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
  `service_rate` decimal(10,2) NOT NULL,
  `service_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`service_id`),
  UNIQUE KEY `service_alias` (`service_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_slip` (
  `slip_id` int(11) NOT NULL AUTO_INCREMENT,
  `slip_number` varchar(50) NOT NULL,
  `slip_type_alias` varchar(100) NOT NULL,
  `slip_subtype_alias` varchar(100) NOT NULL,
  `slip_patient_mrid` varchar(20) NOT NULL,
  `slip_date` date NOT NULL,
  `slip_total_amount` decimal(10,2) NOT NULL,
  `slip_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`slip_id`),
  UNIQUE KEY `slip_type_alias` (`slip_type_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_slip_subtype` (
  `slip_subtype_id` int(11) NOT NULL AUTO_INCREMENT,
  `slip_subtype_name` varchar(100) NOT NULL,
  `slip_subtype_alias` varchar(100) NOT NULL,
  `slip_subtype_description` text DEFAULT NULL,
  `slip_subtype_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`slip_subtype_id`),
  UNIQUE KEY `slip_subtype_alias` (`slip_subtype_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_slip_type` (
  `slip_type_id` int(11) NOT NULL AUTO_INCREMENT,
  `slip_type_name` varchar(100) NOT NULL,
  `slip_type_alias` varchar(100) NOT NULL,
  `slip_type_description` text DEFAULT NULL,
  `slip_type_status` int(10) NOT NULL DEFAULT 1,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`slip_type_id`),
  UNIQUE KEY `slip_type_alias` (`slip_type_alias`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `nxt_test_component` (
  `test_component_id` int(11) NOT NULL AUTO_INCREMENT,
  `test_component_name` varchar(100) NOT NULL,
  `test_component_normal_range` varchar(255) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) NOT NULL,
  `updated_at` datetime DEFAULT NULL ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`test_component_id`),
  UNIQUE KEY `test_component_name` (`test_component_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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

INSERT INTO `nxt_permission` (`permission_id`, `permission_name`, `permission_alias`, `permission_description`, `component_access`, `read_permission`, `write_permission`, `delete_permission`, `permission_status`, `created_at`, `created_by`, `updated_at`, `updated_by`) VALUES (1, 'Administrator', 'admin', 'permission with complete system access', '["nxt_user","nxt_permission"]', 1, 1, 1, 1, CURRENT_TIMESTAMP(), 'admin', NULL, NULL);

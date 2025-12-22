-- Patient Match Audit Table
-- Logs patient matching decisions for compliance and debugging

CREATE TABLE IF NOT EXISTS `nxt_patient_match_audit` (
  `audit_id` INT NOT NULL AUTO_INCREMENT,
  `tenant_id` VARCHAR(100) NOT NULL DEFAULT 'system_default_tenant',
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
  INDEX `idx_matched_patient` (`matched_patient_id`),
  CONSTRAINT `fk_patient_match_audit_tenant` 
    FOREIGN KEY (`tenant_id`) 
    REFERENCES `nxt_tenant` (`tenant_id`) 
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_patient_match_audit_user` 
    FOREIGN KEY (`user_id`) 
    REFERENCES `nxt_user` (`user_id`) 
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_patient_match_audit_patient` 
    FOREIGN KEY (`matched_patient_id`) 
    REFERENCES `nxt_patient` (`patient_id`) 
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci 
COMMENT='Audit log for patient matching decisions';

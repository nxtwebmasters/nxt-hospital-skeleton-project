DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`%` PROCEDURE `backup_and_copy` (IN `source_db` VARCHAR(255), IN `backup_db` VARCHAR(255))   BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE tbl_name VARCHAR(255);
    DECLARE cur CURSOR FOR
        SELECT table_name FROM information_schema.tables WHERE table_schema = source_db;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- SECURITY FIX: Validate database names to prevent SQL injection
    -- Only allow alphanumeric, underscore, and hyphen characters
    IF source_db REGEXP '[^a-zA-Z0-9_-]' OR backup_db REGEXP '[^a-zA-Z0-9_-]' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Invalid database name: Only alphanumeric, underscore, and hyphen allowed';
    END IF;

    -- Additional length validation
    IF LENGTH(source_db) > 64 OR LENGTH(backup_db) > 64 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Database name too long: Maximum 64 characters';
    END IF;

    -- Create backup database if it doesn't exist
    SET @create_db_query = CONCAT('CREATE DATABASE IF NOT EXISTS `', backup_db, '`');
    PREPARE stmt FROM @create_db_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    -- Loop through all tables in source database
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO tbl_name;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Create table structure in backup database
        SET @copy_query = CONCAT('CREATE TABLE `', backup_db, '`.`', tbl_name, '` LIKE `', source_db, '`.`', tbl_name, '`');
        PREPARE stmt FROM @copy_query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        -- Copy data from source to backup
        SET @insert_query = CONCAT('INSERT INTO `', backup_db, '`.`', tbl_name, '` SELECT * FROM `', source_db, '`.`', tbl_name, '`');
        PREPARE stmt FROM @insert_query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;
    CLOSE cur;

    -- Return the backup database name
    SELECT backup_db AS backup_database_name;
END$$

DELIMITER ;

-- --------------------------------------------------------
-- Procedure: sp_validate_tenant_subscription
-- Purpose:   Validates whether a tenant has an active subscription
-- --------------------------------------------------------

DELIMITER //

CREATE PROCEDURE IF NOT EXISTS sp_validate_tenant_subscription(
  IN  p_tenant_id VARCHAR(100),
  OUT p_is_valid  BOOLEAN,
  OUT p_status    VARCHAR(50),
  OUT p_message   TEXT
)
BEGIN
  DECLARE v_subscription_status VARCHAR(50);
  DECLARE v_end_date        DATETIME;
  DECLARE v_trial_end_date  DATETIME;

  SELECT
    ts.status,
    ts.end_date,
    ts.trial_end_date
  INTO
    v_subscription_status,
    v_end_date,
    v_trial_end_date
  FROM nxt_tenant_subscription ts
  WHERE ts.tenant_id = p_tenant_id
    AND ts.status IN ('trial', 'active')
  ORDER BY ts.created_at DESC
  LIMIT 1;

  IF v_subscription_status IS NULL THEN
    SET p_is_valid = FALSE;
    SET p_status   = 'no_subscription';
    SET p_message  = 'No active subscription found';
  ELSEIF v_subscription_status = 'trial' AND v_trial_end_date < NOW() THEN
    SET p_is_valid = FALSE;
    SET p_status   = 'trial_expired';
    SET p_message  = 'Trial period has expired';
  ELSEIF v_subscription_status = 'active' AND v_end_date IS NOT NULL AND v_end_date < NOW() THEN
    SET p_is_valid = FALSE;
    SET p_status   = 'subscription_expired';
    SET p_message  = 'Subscription has expired';
  ELSE
    SET p_is_valid = TRUE;
    SET p_status   = v_subscription_status;
    SET p_message  = 'Subscription is valid';
  END IF;
END //

DELIMITER ;
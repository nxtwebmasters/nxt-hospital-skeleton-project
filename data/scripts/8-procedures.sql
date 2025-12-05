-- This script adds the stored procedure after all schemas and permissions are set.
DELIMITER //
CREATE DEFINER=`root`@`%` PROCEDURE `nxt-hospital`.`backup_and_copy`(IN source_db VARCHAR(255), IN backup_db VARCHAR(255))
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE tbl_name VARCHAR(255);
    DECLARE cur CURSOR FOR
        SELECT table_name FROM information_schema.tables WHERE table_schema = source_db;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    SET @create_db_query = CONCAT('CREATE DATABASE IF NOT EXISTS `', backup_db, '`');
    PREPARE stmt FROM @create_db_query;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO tbl_name;
        IF done THEN
            LEAVE read_loop;
        END IF;

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

    SELECT backup_db AS backup_database_name;
END//
DELIMITER ;
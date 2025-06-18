-- =================================================================
-- EXPLICIT PERMISSIONS FOR THE APPLICATION USER
-- =================================================================
-- This script grants the 'nxt_user' full access to both databases.
-- It is more reliable than relying on the automatic grant for the first DB.
-- =================================================================
GRANT ALL PRIVILEGES ON `nxt-hospital`.* TO 'nxt_user'@'%';
GRANT ALL PRIVILEGES ON `nxt-campaign`.* TO 'nxt_user'@'%';
FLUSH PRIVILEGES;
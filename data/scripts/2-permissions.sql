-- =================================================================
-- EXPLICIT PERMISSIONS FOR THE APPLICATION USER
-- =================================================================
-- SECURITY FIX: Apply principle of least privilege
-- - Removed ALL PRIVILEGES (was overprivileged)
-- - Restricted to specific IPs in Docker network (172.18.0.%)
-- - Removed dangerous privileges (DROP, CREATE USER, GRANT, etc.)
-- =================================================================

-- For Docker internal network (adjust if using different subnet)
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON `nxt-hospital`.* TO 'nxt_user'@'172.18.0.%';

-- For localhost (development/testing)
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON `nxt-hospital`.* TO 'nxt_user'@'localhost';

-- For specific production IP (uncomment and set your backend server IP)
-- GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON `nxt-hospital`.* TO 'nxt_user'@'YOUR_BACKEND_IP';

-- Keep legacy wildcard for backward compatibility (REMOVE in production after migration)
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON `nxt-hospital`.* TO 'nxt_user'@'%';

FLUSH PRIVILEGES;

-- ⚠️ PRODUCTION RECOMMENDATION:
-- 1. Remove the '%' wildcard grant above
-- 2. Use firewall rules to restrict port 3306 access
-- 3. Use SSH tunneling for remote database access
-- 4. Enable MySQL audit logging for security monitoring
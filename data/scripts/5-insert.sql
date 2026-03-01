-- ====================================================================================
-- SEED / REFERENCE DATA INSERTS
-- Run after: 1-schema.sql, 2-permissions.sql, 3-procedures.sql, 4-views.sql
-- ====================================================================================

-- --------------------------------------------------------
-- Default / System Tenant
-- --------------------------------------------------------

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
  '{{DEFAULT_TENANT_SUBDOMAIN}}',
  'active',
  'enterprise',
  '{"fbr":true,"campaigns":true,"ai":true,"health_authority_analytics":true}',
  NOW(),
  'migration_script'
) ON DUPLICATE KEY UPDATE tenant_id=tenant_id;

-- --------------------------------------------------------
-- Subscription Plans
-- --------------------------------------------------------

INSERT INTO `nxt_subscription_plan` (`plan_id`, `plan_name`, `plan_description`, `plan_type`, `monthly_price`, `annual_price`, `currency`, `max_users`, `max_patients`, `max_storage_gb`, `included_modules`, `trial_days`, `is_public`, `sort_order`) VALUES
('PLN001', 'Free Trial',    '15-day free trial',                     'trial',        0.00,      0.00,      'PKR', 3,    100,   0.5, '["patients", "billing", "slipping"]', 15, TRUE, 1),
('PLN002', 'Basic',         'Perfect for small clinics',             'basic',        15000.00,  162000.00, 'PKR', 10,   2000,  2,   '["patients", "billing", "slipping", "appointments", "prescription"]', 0, TRUE, 2),
('PLN003', 'Professional',  'Ideal for growing hospitals',           'professional', 25000.00,  270000.00, 'PKR', 25,   5000,  10,  '["patients", "billing", "slipping", "appointments", "prescription", "laboratory", "pharmacy", "inventory", "campaigns", "tax_management"]', 0, TRUE, 3),
('PLN004', 'Enterprise',    'Complete solution for large hospitals', 'enterprise',   40000.00,  432000.00, 'PKR', 100,  20000, 50,  '["patients", "billing", "slipping", "appointments", "prescription", "laboratory", "pharmacy", "inventory", "campaigns", "tax_management", "ai", "fbr", "health_authority_analytics", "api_access", "room_management"]', 0, TRUE, 4),
('PLN005', 'Lifetime',      'One-time payment, lifetime access',    'custom',        0.00,     750000.00, 'PKR', NULL, NULL,  100, '["patients", "billing", "slipping", "appointments", "prescription", "laboratory", "pharmacy", "inventory", "campaigns", "tax_management", "ai", "fbr", "health_authority_analytics", "api_access", "room_management"]', 0, FALSE, 5)
ON DUPLICATE KEY UPDATE
  `plan_name`        = VALUES(`plan_name`),
  `plan_description` = VALUES(`plan_description`),
  `monthly_price`    = VALUES(`monthly_price`),
  `annual_price`     = VALUES(`annual_price`),
  `included_modules` = VALUES(`included_modules`),
  `max_users`        = VALUES(`max_users`),
  `max_patients`     = VALUES(`max_patients`);

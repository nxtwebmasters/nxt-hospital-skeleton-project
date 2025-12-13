-- This script creates database views after all schemas, permissions, and procedures are set.

-- Additional indexes for campaign performance
-- Indexes for campaign performance are created in `1-schema.sql`.

-- Create view for campaign analytics (tenant-aware)
CREATE OR REPLACE VIEW vw_campaign_analytics AS
SELECT 
    c.tenant_id,
    c.campaign_id,
    c.campaign_name,
    c.campaign_type,
    c.campaign_channel,
    c.campaign_status,
    COUNT(cq.queue_id) as total_triggered,
    SUM(CASE WHEN cq.status = 'sent' THEN 1 ELSE 0 END) as successful_sends,
    SUM(CASE WHEN cq.status = 'failed' THEN 1 ELSE 0 END) as failed_sends,
    SUM(CASE WHEN cq.status = 'pending' THEN 1 ELSE 0 END) as pending_sends,
    ROUND((SUM(CASE WHEN cq.status = 'sent' THEN 1 ELSE 0 END) / NULLIF(COUNT(cq.queue_id), 0)) * 100, 2) as success_rate,
    MIN(cq.created_at) as first_trigger,
    MAX(cq.created_at) as last_trigger
FROM nxt_campaign c
LEFT JOIN nxt_campaign_queue cq ON c.campaign_id = cq.campaign_id AND c.tenant_id = cq.tenant_id
WHERE c.campaign_type = 'triggered'
GROUP BY c.tenant_id, c.campaign_id, c.campaign_name, c.campaign_type, c.campaign_channel, c.campaign_status;

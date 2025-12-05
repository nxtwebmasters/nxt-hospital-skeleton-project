-- This script creates database views after all schemas, permissions, and procedures are set.

-- Additional indexes for campaign performance
CREATE INDEX IF NOT EXISTS `idx_campaign_type_status` ON `nxt_campaign`(`campaign_type`, `campaign_status`);
CREATE INDEX IF NOT EXISTS `idx_campaign_channel` ON `nxt_campaign`(`campaign_channel`);
CREATE INDEX IF NOT EXISTS `idx_trigger_event` ON `nxt_campaign`(`trigger_event`);

-- Create view for campaign analytics
CREATE OR REPLACE VIEW vw_campaign_analytics AS
SELECT 
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
LEFT JOIN nxt_campaign_queue cq ON c.campaign_id = cq.campaign_id
WHERE c.campaign_type = 'triggered'
GROUP BY c.campaign_id, c.campaign_name, c.campaign_type, c.campaign_channel, c.campaign_status;

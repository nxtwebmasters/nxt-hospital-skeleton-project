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
--
-- Phase 2: Pharmacy Management Views
--

--
-- View: v_pharmacy_stock_fifo
-- Purpose: Shows all active pharmacy stock batches ordered by FIFO (oldest first)
--
CREATE OR REPLACE VIEW v_pharmacy_stock_fifo AS
SELECT 
    ps.stock_id,
    ps.tenant_id,
    ps.medicine_id,
    m.medicine_name,
    m.therapeutic_class,
    ps.batch_number,
    ps.expiry_date,
    DATEDIFF(ps.expiry_date, CURDATE()) AS days_until_expiry,
    CASE 
        WHEN DATEDIFF(ps.expiry_date, CURDATE()) <= 0 THEN 'EXPIRED'
        WHEN DATEDIFF(ps.expiry_date, CURDATE()) <= 30 THEN 'CRITICAL'
        WHEN DATEDIFF(ps.expiry_date, CURDATE()) <= 60 THEN 'WARNING'
        ELSE 'NORMAL'
    END AS expiry_status,
    ps.quantity_received,
    ps.quantity_in_stock,
    (ps.quantity_received - ps.quantity_in_stock) AS quantity_consumed,
    ps.unit_cost,
    (ps.quantity_in_stock * ps.unit_cost) AS batch_value,
    ps.received_date,
    ps.storage_location,
    ps.status AS batch_status,
    s.supplier_name,
    ps.grn_number,
    ps.po_id
FROM nxt_pharmacy_stock ps
INNER JOIN nxt_medicine m ON ps.medicine_id = m.medicine_id AND ps.tenant_id = m.tenant_id
LEFT JOIN nxt_supplier s ON ps.supplier_id = s.supplier_id
WHERE ps.status = 'ACTIVE' AND ps.quantity_in_stock > 0
ORDER BY ps.tenant_id, ps.medicine_id, ps.received_date ASC, ps.expiry_date ASC;

--
-- View: v_purchase_order_summary
-- Purpose: Aggregate view of PO stats by supplier and status
--
CREATE OR REPLACE VIEW v_purchase_order_summary AS
SELECT 
    po.tenant_id,
    po.supplier_id,
    s.supplier_name,
    COUNT(po.po_id) AS total_pos,
    SUM(CASE WHEN po.po_status = 'DRAFT' THEN 1 ELSE 0 END) AS draft_count,
    SUM(CASE WHEN po.po_status = 'PENDING_APPROVAL' THEN 1 ELSE 0 END) AS pending_approval_count,
    SUM(CASE WHEN po.po_status = 'APPROVED' THEN 1 ELSE 0 END) AS approved_count,
    SUM(CASE WHEN po.po_status = 'RECEIVED' THEN 1 ELSE 0 END) AS received_count,
    SUM(CASE WHEN po.po_status = 'PARTIALLY_RECEIVED' THEN 1 ELSE 0 END) AS partially_received_count,
    SUM(CASE WHEN po.po_status = 'CANCELLED' THEN 1 ELSE 0 END) AS cancelled_count,
    SUM(CASE WHEN po.po_status IN ('APPROVED', 'RECEIVED', 'PARTIALLY_RECEIVED') THEN po.grand_total ELSE 0 END) AS total_value,
    SUM(CASE WHEN po.po_status = 'RECEIVED' THEN po.grand_total ELSE 0 END) AS received_value,
    MIN(po.po_date) AS first_po_date,
    MAX(po.po_date) AS last_po_date
FROM nxt_purchase_orders po
INNER JOIN nxt_supplier s ON po.supplier_id = s.supplier_id
GROUP BY po.tenant_id, po.supplier_id, s.supplier_name;

--
-- View: v_dispensing_patient_history
-- Purpose: Patient medication history with batch traceability
--
CREATE OR REPLACE VIEW v_dispensing_patient_history AS
SELECT 
    pd.dispensing_id,
    pd.tenant_id,
    pd.dispensing_reference,
    pd.patient_mrid,
    pd.patient_name,
    pd.medicine_id,
    pd.medicine_name,
    pd.quantity_dispensed,
    pd.unit_of_measure,
    pd.total_cost,
    pd.dispensed_at,
    pd.dispensed_by,
    pd.prescription_id,
    pd.bill_uuid,
    pd.return_status,
    pd.return_quantity,
    pd.batch_details,
    JSON_LENGTH(pd.batch_details) AS batches_used_count,
    CASE 
        WHEN pd.return_status = 'FULLY_RETURNED' THEN 0
        WHEN pd.return_status = 'PARTIALLY_RETURNED' THEN (pd.quantity_dispensed - pd.return_quantity)
        ELSE pd.quantity_dispensed
    END AS net_quantity_dispensed
FROM nxt_pharmacy_dispensing pd
ORDER BY pd.tenant_id, pd.patient_mrid, pd.dispensed_at DESC;

--
-- View: v_pharmacy_stock_valuation_fifo
-- Purpose: Stock valuation using FIFO costing per item
--
CREATE OR REPLACE VIEW v_pharmacy_stock_valuation_fifo AS
SELECT 
    ps.tenant_id,
    ps.medicine_id,
    m.medicine_name,
    m.therapeutic_class,
    COUNT(DISTINCT ps.batch_number) AS total_batches,
    SUM(ps.quantity_in_stock) AS total_quantity,
    SUM(ps.quantity_in_stock * ps.unit_cost) AS total_fifo_value,
    AVG(ps.unit_cost) AS average_unit_cost,
    MIN(ps.unit_cost) AS min_unit_cost,
    MAX(ps.unit_cost) AS max_unit_cost,
    MIN(ps.received_date) AS oldest_batch_date,
    MAX(ps.received_date) AS newest_batch_date,
    MIN(ps.expiry_date) AS earliest_expiry,
    SUM(CASE WHEN ps.expiry_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN ps.quantity_in_stock ELSE 0 END) AS expiring_soon_quantity,
    SUM(CASE WHEN ps.expiry_date <= DATE_ADD(CURDATE(), INTERVAL 30 DAY) THEN (ps.quantity_in_stock * ps.unit_cost) ELSE 0 END) AS expiring_soon_value
FROM nxt_pharmacy_stock ps
INNER JOIN nxt_medicine m ON ps.medicine_id = m.medicine_id AND ps.tenant_id = m.tenant_id
WHERE ps.status = 'ACTIVE' AND ps.quantity_in_stock > 0
GROUP BY ps.tenant_id, ps.medicine_id, m.medicine_name, m.therapeutic_class;

--
-- View: v_po_receiving_status
-- Purpose: Shows PO line item receiving progress
--
CREATE OR REPLACE VIEW v_po_receiving_status AS
SELECT 
    po.tenant_id,
    po.po_id,
    po.po_number,
    po.supplier_id,
    s.supplier_name,
    po.po_date,
    po.expected_delivery_date,
    po.po_status,
    COUNT(poi.po_item_id) AS total_line_items,
    SUM(poi.quantity_ordered) AS total_ordered_qty,
    SUM(poi.quantity_received) AS total_received_qty,
    SUM(poi.quantity_ordered - poi.quantity_received) AS total_pending_qty,
    ROUND((SUM(poi.quantity_received) / NULLIF(SUM(poi.quantity_ordered), 0)) * 100, 2) AS receive_completion_pct,
    po.grand_total,
    po.grn_number,
    po.received_at,
    po.received_by
FROM nxt_purchase_orders po
INNER JOIN nxt_supplier s ON po.supplier_id = s.supplier_id
LEFT JOIN nxt_purchase_order_items poi ON po.po_id = poi.po_id
GROUP BY po.tenant_id, po.po_id, po.po_number, po.supplier_id, s.supplier_name, 
         po.po_date, po.expected_delivery_date, po.po_status, po.grand_total, 
         po.grn_number, po.received_at, po.received_by;
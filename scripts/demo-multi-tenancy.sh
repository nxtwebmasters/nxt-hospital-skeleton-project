#!/bin/bash
# Multi-Tenancy Demo Script
# Demonstrates tenant isolation working in the deployed system

set -e

echo "================================================"
echo "  HMS Multi-Tenancy Demonstration"
echo "================================================"
echo ""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

DB_USER="nxt_user"
DB_PASS="NxtWebMasters464"
DB_NAME="nxt-hospital"

echo -e "${BLUE}Step 1: Verify Multi-Tenant Schema${NC}"
echo "-------------------------------------------"
echo "Checking how many tables have tenant_id column..."
TENANT_TABLES=$(docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS -sN \
  -e "SELECT COUNT(DISTINCT TABLE_NAME) FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA='$DB_NAME' AND COLUMN_NAME='tenant_id'" $DB_NAME 2>/dev/null)
echo -e "${GREEN}✓ Found $TENANT_TABLES tables with tenant_id column${NC}"
echo ""

echo -e "${BLUE}Step 2: Check Existing Tenants${NC}"
echo "-------------------------------------------"
docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS -t \
  -e "SELECT tenant_id, tenant_name, tenant_subdomain, tenant_status FROM nxt_tenant" $DB_NAME 2>/dev/null
echo ""

echo -e "${BLUE}Step 3: Create Demo Tenants${NC}"
echo "-------------------------------------------"
echo "Creating Hospital A (tenant_demo_hospital_a)..."
docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS $DB_NAME 2>/dev/null <<EOF
INSERT INTO nxt_tenant (tenant_id, tenant_name, tenant_subdomain, tenant_status, created_at)
VALUES ('tenant_demo_hospital_a', 'Demo Hospital A', 'hospital-a', 'active', NOW())
ON DUPLICATE KEY UPDATE tenant_name=tenant_name;
EOF
echo -e "${GREEN}✓ Hospital A created${NC}"

echo "Creating Clinic B (tenant_demo_clinic_b)..."
docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS $DB_NAME 2>/dev/null <<EOF
INSERT INTO nxt_tenant (tenant_id, tenant_name, tenant_subdomain, tenant_status, created_at)
VALUES ('tenant_demo_clinic_b', 'Demo Clinic B', 'clinic-b', 'active', NOW())
ON DUPLICATE KEY UPDATE tenant_name=tenant_name;
EOF
echo -e "${GREEN}✓ Clinic B created${NC}"
echo ""

echo -e "${BLUE}Step 4: Insert Test Patients (Tenant-Isolated)${NC}"
echo "-------------------------------------------"

echo "Adding patient to Default Tenant..."
docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS $DB_NAME 2>/dev/null <<EOF
INSERT INTO nxt_patient (
  tenant_id, patient_name, patient_mobile, patient_mrid, 
  patient_gender, patient_age, created_at
) VALUES (
  'tenant_system_default', 'John Default', '03001234567', 'MR-DEFAULT-001',
  'Male', 45, NOW()
) ON DUPLICATE KEY UPDATE patient_name=patient_name;
EOF
echo -e "${GREEN}✓ John Default added to tenant_system_default${NC}"

echo "Adding patient to Hospital A..."
docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS $DB_NAME 2>/dev/null <<EOF
INSERT INTO nxt_patient (
  tenant_id, patient_name, patient_mobile, patient_mrid,
  patient_gender, patient_age, created_at
) VALUES (
  'tenant_demo_hospital_a', 'Alice Anderson', '03119876543', 'MR-HOSP-A-001',
  'Female', 32, NOW()
) ON DUPLICATE KEY UPDATE patient_name=patient_name;
EOF
echo -e "${GREEN}✓ Alice Anderson added to tenant_demo_hospital_a${NC}"

echo "Adding patient to Clinic B..."
docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS $DB_NAME 2>/dev/null <<EOF
INSERT INTO nxt_patient (
  tenant_id, patient_name, patient_mobile, patient_mrid,
  patient_gender, patient_age, created_at
) VALUES (
  'tenant_demo_clinic_b', 'Bob Brown', '03228887766', 'MR-CLINIC-B-001',
  'Male', 28, NOW()
) ON DUPLICATE KEY UPDATE patient_name=patient_name;
EOF
echo -e "${GREEN}✓ Bob Brown added to tenant_demo_clinic_b${NC}"
echo ""

echo -e "${BLUE}Step 5: Demonstrate Tenant Isolation${NC}"
echo "-------------------------------------------"
echo ""
echo -e "${YELLOW}Query 1: All patients (no tenant filter - BAD!)${NC}"
docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS -t \
  -e "SELECT patient_name, patient_mrid, tenant_id FROM nxt_patient 
      WHERE patient_mrid LIKE 'MR-%' 
      ORDER BY created_at DESC LIMIT 10" $DB_NAME 2>/dev/null
echo -e "${YELLOW}⚠ This shows ALL tenants' data - demonstrates why tenant_id filters are critical!${NC}"
echo ""

echo -e "${YELLOW}Query 2: Default Tenant Only (WITH tenant_id filter - GOOD!)${NC}"
docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS -t \
  -e "SELECT patient_name, patient_mrid, tenant_id FROM nxt_patient 
      WHERE tenant_id = 'tenant_system_default' 
      ORDER BY created_at DESC LIMIT 10" $DB_NAME 2>/dev/null
echo -e "${GREEN}✓ Only shows default tenant's patients${NC}"
echo ""

echo -e "${YELLOW}Query 3: Hospital A Only (WITH tenant_id filter - GOOD!)${NC}"
docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS -t \
  -e "SELECT patient_name, patient_mrid, tenant_id FROM nxt_patient 
      WHERE tenant_id = 'tenant_demo_hospital_a' 
      ORDER BY created_at DESC LIMIT 10" $DB_NAME 2>/dev/null
echo -e "${GREEN}✓ Only shows Hospital A's patients${NC}"
echo ""

echo -e "${YELLOW}Query 4: Clinic B Only (WITH tenant_id filter - GOOD!)${NC}"
docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS -t \
  -e "SELECT patient_name, patient_mrid, tenant_id FROM nxt_patient 
      WHERE tenant_id = 'tenant_demo_clinic_b' 
      ORDER BY created_at DESC LIMIT 10" $DB_NAME 2>/dev/null
echo -e "${GREEN}✓ Only shows Clinic B's patients${NC}"
echo ""

echo -e "${BLUE}Step 6: Verify Tenant Counts${NC}"
echo "-------------------------------------------"
docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS -t \
  -e "SELECT 
        tenant_id, 
        COUNT(*) as patient_count 
      FROM nxt_patient 
      GROUP BY tenant_id 
      ORDER BY tenant_id" $DB_NAME 2>/dev/null
echo ""

echo "================================================"
echo -e "${GREEN}✓ Multi-Tenancy Demonstration Complete!${NC}"
echo "================================================"
echo ""
echo "Key Takeaways:"
echo "  1. Database schema has tenant_id in 50+ tables"
echo "  2. Multiple tenants can coexist in same database"
echo "  3. Data is isolated when queries use WHERE tenant_id = ?"
echo "  4. Without tenant_id filter, data leaks across tenants"
echo ""
echo "Next Steps:"
echo "  - Test API endpoints with tenant-aware queries"
echo "  - Verify backend controllers use TenantQueryHelper"
echo "  - Fix remaining 65 queries missing tenant_id filters"
echo "  - Test cross-tenant access attempts (security audit)"
echo ""
echo "Clean up demo data:"
echo "  docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS \\"
echo "    -e \"DELETE FROM nxt_patient WHERE patient_mrid LIKE 'MR-%-%'\" $DB_NAME"
echo "  docker exec hospital-mysql mysql -u $DB_USER -p$DB_PASS \\"
echo "    -e \"DELETE FROM nxt_tenant WHERE tenant_id LIKE 'tenant_demo_%'\" $DB_NAME"
echo ""

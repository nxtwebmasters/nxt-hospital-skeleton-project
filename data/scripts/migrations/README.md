# Database Migrations

This directory contains database migration scripts for the NXT Hospital Management System.

## Migration Files

Migrations are numbered sequentially and should be run in order:

- `001-payment-receipts-table.sql` - Adds payment transaction table with receipt upload support

## Running Migrations

### On Production VM (Linux)

```bash
cd nxt-hospital-skeleton-project
chmod +x run-migration.sh
./run-migration.sh
```

### On Windows (Local Development)

```powershell
cd nxt-hospital-skeleton-project
.\run-migration.ps1
```

## What the Migration Script Does

1. Loads database credentials from `hms-backend.env`
2. Detects if MySQL is running in Docker container or as standalone
3. Executes all `.sql` files in `data/scripts/migrations/` in alphabetical order
4. Stops on first error to prevent partial migrations
5. Provides summary of successful and failed migrations

## After Running Migrations

1. **Restart Backend:**
   ```bash
   docker-compose restart hospital-apis
   ```

2. **Verify Table Creation:**
   ```bash
   docker-compose exec mysql mysql -u root -p nxt-hospital -e "SHOW TABLES LIKE 'nxt_payment_transaction';"
   ```

3. **Test Payment Receipts API:**
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3001/api-server/payment/receipts
   ```

4. **Access Admin Panel:**
   - Login to hospital-frontend
   - Navigate to Tenant Management
   - Click "Payment Receipts" button

## Creating New Migrations

When adding new migrations:

1. Create a new file in `data/scripts/migrations/`
2. Use sequential numbering: `002-description.sql`, `003-description.sql`, etc.
3. Include comments explaining the purpose
4. Use `IF NOT EXISTS` checks to make migrations idempotent
5. Test locally before deploying to production

## Example Migration Structure

```sql
-- Migration: Feature Description
-- Date: YYYY-MM-DD
-- Description: What this migration does

USE `nxt-hospital`;

-- Your migration SQL here
CREATE TABLE IF NOT EXISTS `table_name` (
  -- columns
);

SELECT 'Migration XXX-description.sql completed successfully' AS status;
```

## Troubleshooting

### Error: "Table already exists"

This is expected behavior. The migration script checks for existing tables and skips creation if they exist.

### Error: "Access denied"

Check that the database credentials in `hms-backend.env` are correct:
- `DB_HOST`
- `DB_USERNAME`
- `DB_PASSWORD`
- `SOURCE_DB_NAME`

### Error: "Cannot connect to Docker"

The script will automatically fall back to direct MySQL connection if Docker is not running.

## Manual Migration Execution

If the automated script fails, you can run migrations manually:

```bash
# Using Docker
docker-compose exec mysql mysql -u root -p nxt-hospital < data/scripts/migrations/001-payment-receipts-table.sql

# Using direct connection
mysql -h localhost -u root -p nxt-hospital < data/scripts/migrations/001-payment-receipts-table.sql
```

## Rollback Strategy

Currently, migrations do not include automatic rollback. To rollback a migration:

1. Create a reverse migration (e.g., `001-payment-receipts-table-rollback.sql`)
2. Execute it manually
3. Test thoroughly before deploying to production

Example rollback:
```sql
DROP TABLE IF EXISTS `nxt_payment_transaction`;
```

## Integration with 1-schema.sql

The main schema file (`data/scripts/1-schema.sql`) should be updated to include new tables for fresh installations. Migrations are for updating existing databases only.

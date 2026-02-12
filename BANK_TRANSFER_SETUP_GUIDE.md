# ============================================
# NXT HOSPITAL - BANK TRANSFER CONFIGURATION GUIDE
# ============================================
# This file documents all required environment variables for bank transfer payment processing
# Copy these to your .env file and update with your actual bank details

# Bank Account Information (REQUIRED for Bank Transfer)
# ------------------------------------------------------
# These details will be shown to customers when they select bank transfer

# Bank name - Full official name of your bank
BANK_NAME=Allied Bank Limited

# Account title - Name on the bank account
BANK_ACCOUNT_TITLE=NXT HOSPITAL

# Account number - Your bank account number
BANK_ACCOUNT_NUMBER=0010012345678900

# IBAN - International Bank Account Number (Pakistan format: PK + 2 digits + 4-letter bank code + 16 digits)
BANK_IBAN=PK36ABPA0010012345678900

# SWIFT Code - For international transfers (optional)
BANK_SWIFT=ABPAPKKA

# Branch Code - Your bank branch code
BANK_BRANCH=0010

# Admin Email - Where payment notifications will be sent
ADMIN_EMAIL=nxtwebmasters@gmail.com

# Base URL - Your application URL (for email links and receipts)
BASE_URL=https://hms.nxtwebmasters.com

# Base Domain - For tenant subdomains (without protocol)
BASE_DOMAIN=nxtwebmasters.com


# ============================================
# PAYMENT GATEWAY CREDENTIALS (Currently Disabled)
# ============================================
# These are currently not configured. When you're ready to enable them:
# 1. Sign up for merchant accounts with JazzCash/EasyPaisa
# 2. Get your API credentials from their merchant portals
# 3. Uncomment and fill in these values
# 4. Update signup.html to re-enable the payment buttons

# JazzCash Configuration (Disabled - Coming Soon)
# ------------------------------------------------
# JAZZCASH_MERCHANT_ID=your_merchant_id
# JAZZCASH_PASSWORD=your_password
# JAZZCASH_INTEGRITY_SALT=your_integrity_salt
# JAZZCASH_API_URL=https://sandbox.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform/
# Note: Use production URL when going live: https://payments.jazzcash.com.pk/CustomerPortal/transactionmanagement/merchantform/

# EasyPaisa Configuration (Disabled - Coming Soon)
# -------------------------------------------------
# EASYPAISA_STORE_ID=your_store_id
# EASYPAISA_API_URL=https://easypay.easypaisa.com.pk/tpg
# EASYPAISA_HASH_KEY=your_hash_key


# ============================================
# EMAIL CONFIGURATION
# ============================================
# Required for sending welcome emails, payment confirmations, and admin notifications

EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_SECURE=false
EMAIL_USER=your-email@gmail.com
EMAIL_PASSWORD=your-app-password
EMAIL_FROM=noreply@nxthms.com
EMAIL_FROM_NAME=NXT HOSPITAL


# ============================================
# FILE UPLOAD CONFIGURATION
# ============================================
# For payment receipt uploads

# Path where uploaded files (receipts, images) will be stored
IMAGE_STORAGE_PATH=./public/uploads

# Maximum file size for uploads (in bytes) - Currently 5MB
MAX_UPLOAD_SIZE=5242880


# ============================================
# QUICK SETUP CHECKLIST
# ============================================
# [ ] 1. Copy this file to .env
# [ ] 2. Update BANK_* variables with your actual bank details
# [ ] 3. Set ADMIN_EMAIL to receive payment notifications
# [ ] 4. Configure EMAIL_* settings for sending notifications
# [ ] 5. Test by creating a test signup at /signup.html
# [ ] 6. Verify you receive admin notification email
# [ ] 7. Customer should receive welcome email with bank details
# [ ] 8. After customer uploads receipt, verify at /api-server/payment/admin/pending-receipts


# ============================================
# IMPORTANT SECURITY NOTES
# ============================================
# 1. Never commit .env file to version control
# 2. Add .env to .gitignore (already done)
# 3. Keep backup of .env file in secure location
# 4. Rotate passwords regularly
# 5. Use strong passwords for database and email
# 6. Enable 2FA on email account used for notifications


# ============================================
# TESTING BANK TRANSFER FLOW
# ============================================
# 1. Navigate to: https://your-domain.com/signup.html
# 2. Select a subscription plan
# 3. Fill in signup form
# 4. Bank Transfer option should be pre-selected
# 5. Click "Create Account"
# 6. Modal will show bank details with your configured information
# 7. Check customer email for welcome message with bank details
# 8. Check admin email for new signup notification
# 9. Customer can upload receipt at: /payment-receipt-upload.html
# 10. Admin verifies at: POST /api-server/payment/admin/verify-manual


# ============================================
# PRODUCTION DEPLOYMENT
# ============================================
# When deploying to production:
# 1. Ensure all BANK_* variables are correct
# 2. Use production database credentials
# 3. Enable HTTPS (already configured in nginx)
# 4. Set NODE_ENV=production
# 5. Update BASE_URL and BASE_DOMAIN to production domain
# 6. Test complete flow end-to-end before going live
# 7. Monitor admin email for payment notifications
# 8. Set up automated backup of payment receipts folder

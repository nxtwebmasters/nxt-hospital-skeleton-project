# Frontend Performance Fix - Rebuild Script (Windows)
# Run this on your development machine to rebuild the frontend image

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Frontend Performance Fix - Image Rebuild" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"

# Check if in correct directory
if (-not (Test-Path "hospital-frontend\Dockerfile")) {
    Write-Host "❌ Error: Run this script from the nxt-hms-revamp root directory" -ForegroundColor Red
    Write-Host "Expected: d:\personal-project-repos\nxt-hms-revamp\" -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 1: Checking Docker is running..." -ForegroundColor Green
try {
    docker ps | Out-Null
    Write-Host "✅ Docker is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Building hospital-frontend with performance fixes..." -ForegroundColor Green
Write-Host "This will take 5-10 minutes..." -ForegroundColor Yellow

cd hospital-frontend

# Build the image
docker build -t pandanxt/hospital-frontend:performance-fix-v1 . 

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build completed successfully" -ForegroundColor Green

Write-Host ""
Write-Host "Step 3: Verifying image..." -ForegroundColor Green
docker images pandanxt/hospital-frontend:performance-fix-v1

Write-Host ""
Write-Host "Step 4: Testing image locally (optional)..." -ForegroundColor Green
Write-Host "Run: docker run -d -p 8080:80 pandanxt/hospital-frontend:performance-fix-v1" -ForegroundColor Cyan
Write-Host "Then visit: http://localhost:8080" -ForegroundColor Cyan

Write-Host ""
$pushImage = Read-Host "Do you want to push to Docker Hub? (y/n)"

if ($pushImage -eq 'y' -or $pushImage -eq 'Y') {
    Write-Host ""
    Write-Host "Step 5: Logging into Docker Hub..." -ForegroundColor Green
    docker login
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Docker login failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "Step 6: Pushing image to Docker Hub..." -ForegroundColor Green
    docker push pandanxt/hospital-frontend:performance-fix-v1
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Push failed!" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "✅ Image pushed successfully" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. SSH to production server:" -ForegroundColor Yellow
    Write-Host "   ssh root@familycare.nxtwebmasters.com" -ForegroundColor White
    Write-Host ""
    Write-Host "2. Run deployment script:" -ForegroundColor Yellow
    Write-Host "   cd ~/nxt-hospital-skeleton-project" -ForegroundColor White
    Write-Host "   bash scripts/deploy-frontend-performance-fix.sh" -ForegroundColor White
    Write-Host ""
    Write-Host "3. Or manually update docker-compose.yml:" -ForegroundColor Yellow
    Write-Host "   image: pandanxt/hospital-frontend:performance-fix-v1" -ForegroundColor White
    Write-Host "   docker compose up -d hospital-frontend" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Build Complete (Not Pushed)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Image built locally:" -ForegroundColor Yellow
    Write-Host "  pandanxt/hospital-frontend:performance-fix-v1" -ForegroundColor White
    Write-Host ""
    Write-Host "To push later, run:" -ForegroundColor Yellow
    Write-Host "  docker push pandanxt/hospital-frontend:performance-fix-v1" -ForegroundColor White
    Write-Host ""
}

cd ..

Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Cyan
Write-Host "  See: nxt-hospital-skeleton-project\docs\FRONTEND_LOADING_ISSUE_CRITICAL_FIX.md" -ForegroundColor White
Write-Host ""

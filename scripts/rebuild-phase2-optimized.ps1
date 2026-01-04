# Phase 2 Bundle Optimization - Quick Rebuild Script
# Run this after Phase 2 changes to rebuild optimized bundle

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Phase 2 Bundle Optimization - Rebuild" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"

# Check if in correct directory
if (-not (Test-Path "hospital-frontend\package.json")) {
    Write-Host "❌ Error: Run this script from the nxt-hms-revamp root directory" -ForegroundColor Red
    exit 1
}

cd hospital-frontend

Write-Host "📊 Changes Applied in Phase 2:" -ForegroundColor Green
Write-Host "  ✅ jQuery, Bootstrap, Chart.js → CDN (~3MB saved)" -ForegroundColor White
Write-Host "  ✅ XLSX lazy loaded (~1.2MB saved)" -ForegroundColor White
Write-Host "  ✅ Build optimization enabled" -ForegroundColor White
Write-Host "  ✅ gzip compression configured" -ForegroundColor White
Write-Host ""
Write-Host "Total Immediate Savings: ~4.2MB" -ForegroundColor Yellow
Write-Host ""

Write-Host "Step 1: Installing dependencies..." -ForegroundColor Green
npm ci

Write-Host ""
Write-Host "Step 2: Building with optimizations..." -ForegroundColor Green
Write-Host "(This will take 5-10 minutes with full optimization)" -ForegroundColor Yellow
Write-Host ""

# Build with production config
npm run build

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed! Check errors above." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "✅ Build completed successfully" -ForegroundColor Green

Write-Host ""
Write-Host "Step 3: Analyzing bundle sizes..." -ForegroundColor Green

if (Test-Path "dist") {
    # List all JS files and their sizes
    Write-Host ""
    Write-Host "Bundle Sizes:" -ForegroundColor Cyan
    Get-ChildItem -Path "dist\*.js" -Recurse | 
        Sort-Object Length -Descending | 
        Select-Object Name, @{Name="Size (MB)";Expression={[math]::Round($_.Length/1MB, 2)}} |
        Format-Table -AutoSize

    $totalSize = (Get-ChildItem -Path "dist\*.js" -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
    Write-Host "Total Bundle Size: $([math]::Round($totalSize, 2)) MB" -ForegroundColor Yellow
    
    if ($totalSize -gt 10) {
        Write-Host ""
        Write-Host "⚠️  Bundle still large!" -ForegroundColor Yellow
        Write-Host "Next step: Implement lazy loading (see PHASE2_BUNDLE_OPTIMIZATION_COMPLETE.md)" -ForegroundColor Yellow
    } elseif ($totalSize -gt 5) {
        Write-Host ""
        Write-Host "✅ Good progress! Target: < 5MB" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "🎉 Excellent! Bundle size optimized!" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Step 4: Building Docker image..." -ForegroundColor Green
$buildImage = Read-Host "Build Docker image now? (y/n)"

if ($buildImage -eq 'y' -or $buildImage -eq 'Y') {
    Write-Host "Building image: pandanxt/hospital-frontend:phase2-optimized" -ForegroundColor Cyan
    docker build -t pandanxt/hospital-frontend:phase2-optimized .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker image built successfully" -ForegroundColor Green
        
        Write-Host ""
        $pushImage = Read-Host "Push to Docker Hub? (y/n)"
        
        if ($pushImage -eq 'y' -or $pushImage -eq 'Y') {
            docker push pandanxt/hospital-frontend:phase2-optimized
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✅ Image pushed successfully" -ForegroundColor Green
            }
        }
    }
}

cd ..

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Phase 2 Build Complete" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📦 Immediate Improvements Applied:" -ForegroundColor Yellow
Write-Host "  • CDN libraries reduce parallel download time" -ForegroundColor White
Write-Host "  • Gzip compression reduces transfer by 70-80%" -ForegroundColor White
Write-Host "  • XLSX lazy loads only when needed" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Next Steps for Maximum Performance:" -ForegroundColor Yellow
Write-Host "  1. Implement lazy loading modules (see patient.module.ts example)" -ForegroundColor White
Write-Host "  2. Convert all routes to loadChildren pattern" -ForegroundColor White
Write-Host "  3. Target: < 3MB initial bundle (90% reduction)" -ForegroundColor White
Write-Host ""
Write-Host "📚 Documentation:" -ForegroundColor Yellow
Write-Host "  • Phase 2 Guide: docs\PHASE2_BUNDLE_OPTIMIZATION_COMPLETE.md" -ForegroundColor White
Write-Host "  • Critical Fix: docs\FRONTEND_LOADING_ISSUE_CRITICAL_FIX.md" -ForegroundColor White
Write-Host ""
Write-Host "🔍 To analyze bundle:" -ForegroundColor Yellow
Write-Host "  cd hospital-frontend" -ForegroundColor White
Write-Host "  npm run analyze" -ForegroundColor White
Write-Host ""

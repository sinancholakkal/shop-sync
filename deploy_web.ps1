# ShopSync GitHub Pages Deployment Script
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " ShopSync Web Deployment to GitHub Pages " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

Write-Host "`n1. Building Flutter Web with --base-href /shop-sync/ ..." -ForegroundColor Yellow
flutter build web --base-href "/shop-sync/" --release

if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed! Please check errors." -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Ensuring 404.html and .nojekyll exist..." -ForegroundColor Yellow
Copy-Item "build\web\index.html" "build\web\404.html" -Force
New-Item -ItemType File -Path "build\web\.nojekyll" -Force | Out-Null

Write-Host "`n3. Packing web build into gh-pages branch..." -ForegroundColor Yellow
Push-Location "build\web"
git init
git checkout -B gh-pages
git add -A
git commit -m "Deploy ShopSync to GitHub Pages"
Pop-Location
git fetch build\web gh-pages:gh-pages -f
Remove-Item -Recurse -Force "build\web\.git"

Write-Host "`n4. Pushing gh-pages to GitHub..." -ForegroundColor Yellow
git push origin gh-pages -f

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n Deployment successful!" -ForegroundColor Green
    Write-Host "Live App URL: https://sinancholakkal.github.io/shop-sync/" -ForegroundColor Green
} else {
    Write-Host "`n Push failed or credentials prompt needed." -ForegroundColor Yellow
    Write-Host "You can run: git push origin gh-pages -f" -ForegroundColor Yellow
}

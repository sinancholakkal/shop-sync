# ShopSync 🛍️
> Modern, Glassmorphic Retail POS & Inventory Management Application built with Flutter.

[![Deploy ShopSync Web to GitHub Pages](https://github.com/sinancholakkal/shop-sync/actions/workflows/deploy.yml/badge.svg)](https://github.com/sinancholakkal/shop-sync/actions/workflows/deploy.yml)
[![Live Demo](https://img.shields.io/badge/Demo-GitHub%20Pages-blue?logo=github)](https://sinancholakkal.github.io/shop-sync/)

Live Web App: **[https://sinancholakkal.github.io/shop-sync/](https://sinancholakkal.github.io/shop-sync/)**

---

## ✨ Features

- **Sequential Product Numbering:** Auto-assigned, permanent, sequential item numbers (`#1`, `#2`, `#3`...) for every product. Searchable directly by item number (e.g. `5` or `#5`).
- **Suggested Search Keys & Aliases:** Tag regional or alternative names (e.g. *"ചായയരിപ്പ"*, *"ടീ സ്ട്രൈനർ"*, *"Strainer"*) so staff can find items instantly under colloquial terms.
- **Role-Based Access Control (RBAC):** Granular permissions for Shop Owner, Full Access Staff, Item & Inventory Manager, and Stock Counting Staff. Automatic hiding of sensitive acquisition costs and profit margins.
- **Dynamic Category Management:** Custom product categories with strict thresholds and limits.
- **Real-Time Transactions & Analytics:** Track retail and wholesale sales, revenue graphs, and low-stock alerts.
- **Zero-Overflow Responsive Glassmorphism:** Tailored dark/light theme designed for mobile, tablet, and desktop screens.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.24+ recommended)
- Chrome / Edge (for Web development)

### Running Locally
```bash
# Clone the repository
git clone https://github.com/sinancholakkal/shop-sync.git
cd shop-sync

# Install packages
flutter pub get

# Run on Chrome
flutter run -d chrome
```

---

## 🌐 Web Build & GitHub Pages Deployment

### Option A: One-Click Deploy Script (Recommended)
Run the included PowerShell script in your terminal:
```powershell
.\deploy_web.ps1
```
This automatically compiles the web bundle with the correct base path, sets up `404.html` and `.nojekyll`, and pushes to the `gh-pages` branch.

---

### Option B: Minimal Manual Web Build & Push Steps

If you prefer running commands manually, follow these 4 steps:

#### Step 1: Build the Web release bundle
Because GitHub Pages serves repository pages at `https://<username>.github.io/<repo>/`, you **must** supply `--base-href`:
```bash
flutter build web --base-href "/shop-sync/" --release
```

#### Step 2: Ensure SPA Routing (404 Handling) & Bypass Jekyll
GitHub Pages serves `404.html` on direct route refreshes. Copy `index.html` to `404.html` and create `.nojekyll`:
```powershell
Copy-Item "build\web\index.html" "build\web\404.html" -Force
New-Item -ItemType File -Path "build\web\.nojekyll" -Force | Out-Null
```

#### Step 3: Package `build/web` into the `gh-pages` branch
```powershell
Push-Location "build\web"
git init
git checkout -B gh-pages
git add -A
git commit -m "Deploy ShopSync to GitHub Pages"
Pop-Location
git fetch build\web gh-pages:gh-pages -f
Remove-Item -Recurse -Force "build\web\.git"
```

#### Step 4: Push to GitHub
```bash
git push origin gh-pages -f
```

---

### ❓ Why is `-f` (Force) needed when pushing to `gh-pages`?

When you push your source code to the `main` branch, you want Git to keep an unbroken history of every edit (`git push origin main`).

However, the **`gh-pages` branch is purely a compiled artifact hosting branch**:
1. Every time you run `flutter build web`, a new set of minified JavaScript bundles and asset hashes are generated.
2. The deployment commit is packaged fresh from `build/web`. It does **not** share an incremental commit history with the previous build's commit on GitHub.
3. Without `-f`, Git will reject the push with a **`[rejected - non-fast-forward]`** error because the histories don't align.
4. Using `-f` safely tells Git: *"Completely replace the published website artifacts with the new latest build."*

---

### Option C: Fully Automated GitHub Actions Deploy

You can also let GitHub build and deploy automatically on every push to `main`:
1. Go to your repo **Settings** > **Pages**.
2. Under **Build and deployment** > **Source**, select **GitHub Actions**.
3. Now, whenever you run:
   ```bash
   git push origin main
   ```
   GitHub Actions will automatically run the test suite, build the web app, and deploy it live!

---

## 🧪 Testing

Run the automated test suite (44+ tests covering RBAC, inventory, auto-increment, and responsive layouts):
```bash
flutter test
```

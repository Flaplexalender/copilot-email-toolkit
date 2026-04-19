<#
.SYNOPSIS
    Copilot Email Setup — Automated installer for VS Code + GitHub Copilot + Gmail API
.DESCRIPTION
    This script checks prerequisites, installs what it can, and opens browser pages
    for the steps that need human interaction.
.NOTES
    Run: Right-click this file → "Run with PowerShell"
    Or:  powershell -ExecutionPolicy Bypass -File setup.ps1
#>

$ErrorActionPreference = "Continue"
$Host.UI.RawUI.WindowTitle = "Copilot Email Setup"

# ── Helpers ──────────────────────────────────────────────────────────────────

function Write-Step {
    param([string]$Number, [string]$Text)
    Write-Host ""
    Write-Host "  [$Number] " -ForegroundColor Cyan -NoNewline
    Write-Host $Text -ForegroundColor White
    Write-Host "  $('─' * 60)" -ForegroundColor DarkGray
}

function Write-Ok   { param([string]$Text) Write-Host "    ✓ $Text" -ForegroundColor Green }
function Write-Warn { param([string]$Text) Write-Host "    ⚠ $Text" -ForegroundColor Yellow }
function Write-Err  { param([string]$Text) Write-Host "    ✗ $Text" -ForegroundColor Red }
function Write-Info { param([string]$Text) Write-Host "    → $Text" -ForegroundColor Gray }

function Pause-Step {
    Write-Host ""
    Write-Host "    Press any key to continue..." -ForegroundColor DarkYellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ── Banner ───────────────────────────────────────────────────────────────────

Clear-Host
Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║                                                       ║" -ForegroundColor Cyan
Write-Host "  ║   Copilot Email Setup — Gmail + AI in VS Code         ║" -ForegroundColor Cyan
Write-Host "  ║                                                       ║" -ForegroundColor Cyan
Write-Host "  ║   This script will help you set up:                   ║" -ForegroundColor Cyan
Write-Host "  ║     • Python 3.10+                                    ║" -ForegroundColor Cyan
Write-Host "  ║     • Visual Studio Code                              ║" -ForegroundColor Cyan
Write-Host "  ║     • GitHub Copilot Pro subscription (`$10/mo)        ║" -ForegroundColor Cyan
Write-Host "  ║     • Google Gmail API access                         ║" -ForegroundColor Cyan
Write-Host "  ║     • Everything you need to manage email with AI     ║" -ForegroundColor Cyan
Write-Host "  ║                                                       ║" -ForegroundColor Cyan
Write-Host "  ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

# ── Step 1: Check Python ────────────────────────────────────────────────────

Write-Step "1/8" "Checking Python installation..."

$pythonCmd = $null
foreach ($cmd in @("python", "python3", "py")) {
    try {
        $ver = & $cmd --version 2>&1
        if ($ver -match "Python (\d+)\.(\d+)") {
            $major = [int]$Matches[1]
            $minor = [int]$Matches[2]
            if ($major -ge 3 -and $minor -ge 10) {
                $pythonCmd = $cmd
                Write-Ok "Found $ver"
                break
            }
        }
    } catch {}
}

if (-not $pythonCmd) {
    Write-Warn "Python 3.10+ not found."
    Write-Info "Opening Python download page..."
    Start-Process "https://www.python.org/downloads/"
    Write-Host ""
    Write-Host "    IMPORTANT: During installation, check the box that says:" -ForegroundColor Yellow
    Write-Host '    [✓] "Add Python to PATH"' -ForegroundColor White
    Write-Host ""
    Write-Host "    After installing Python, CLOSE this window and run setup.ps1 again." -ForegroundColor Yellow
    Pause-Step
    exit 1
}

# ── Step 2: Check VS Code ──────────────────────────────────────────────────

Write-Step "2/8" "Checking Visual Studio Code..."

$codeCmd = $null
foreach ($cmd in @("code", "code-insiders")) {
    try {
        $ver = & $cmd --version 2>&1 | Select-Object -First 1
        if ($ver -match "^\d+\.\d+") {
            $codeCmd = $cmd
            Write-Ok "Found VS Code ($ver)"
            break
        }
    } catch {}
}

if (-not $codeCmd) {
    Write-Warn "VS Code not found."
    Write-Info "Opening VS Code download page..."
    Start-Process "https://code.visualstudio.com/Download"
    Write-Host ""
    Write-Host "    Install VS Code, then CLOSE this window and run setup.ps1 again." -ForegroundColor Yellow
    Pause-Step
    exit 1
}

# ── Step 3: Install VS Code Extensions ──────────────────────────────────────

Write-Step "3/8" "Installing VS Code extensions..."

$extensions = @(
    "GitHub.copilot",
    "GitHub.copilot-chat",
    "ms-python.python"
)

foreach ($ext in $extensions) {
    Write-Info "Installing $ext..."
    & $codeCmd --install-extension $ext --force 2>&1 | Out-Null
    Write-Ok "$ext installed"
}

# ── Step 4: Install Python dependencies ─────────────────────────────────────

Write-Step "4/8" "Installing Python packages..."

$packages = @(
    "google-auth",
    "google-auth-oauthlib",
    "google-api-python-client"
)

& $pythonCmd -m pip install --quiet --upgrade pip 2>&1 | Out-Null
& $pythonCmd -m pip install --quiet $($packages -join " ") 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Ok "All Python packages installed"
} else {
    Write-Err "Some packages may have failed. Try running manually:"
    Write-Info "$pythonCmd -m pip install $($packages -join ' ')"
}

# ── Step 5: GitHub Copilot Pro Subscription ─────────────────────────────────

Write-Step "5/8" "GitHub Copilot Pro Subscription ($10/month)"

Write-Host ""
Write-Host "    You need a GitHub account and Copilot Pro subscription." -ForegroundColor White
Write-Host "    This gives you access to Claude Opus 4.6 in VS Code Chat." -ForegroundColor White
Write-Host ""
Write-Host "    Opening the subscription page now..." -ForegroundColor Gray

Start-Process "https://github.com/settings/copilot"
Start-Sleep -Seconds 2

Write-Info "If you already have Copilot Pro, just continue."
Write-Info "If not, subscribe to 'Copilot Pro' ($10/month)."
Pause-Step

# ── Step 6: Google Cloud Console — Create Project & Enable Gmail API ────────

Write-Step "6/8" "Google Cloud Console — Gmail API Setup"

Write-Host ""
Write-Host "    This is the most involved step. Follow these instructions:" -ForegroundColor White
Write-Host ""
Write-Host "    1. Sign in with your Google/Gmail account" -ForegroundColor Yellow
Write-Host "    2. Create a new project (name it anything, e.g. 'Email Helper')" -ForegroundColor Yellow
Write-Host "    3. Enable the Gmail API (search 'Gmail API' → Enable)" -ForegroundColor Yellow
Write-Host ""
Write-Host "    Opening Google Cloud Console..." -ForegroundColor Gray

Start-Process "https://console.cloud.google.com/projectcreate"
Start-Sleep -Seconds 3

Write-Info "After creating the project, press any key to continue..."
Pause-Step

# ── Step 6b: Enable Gmail API ──────────────────────────────────────────────

Write-Host ""
Write-Info "Opening Gmail API page..."
Start-Process "https://console.cloud.google.com/apis/library/gmail.googleapis.com"
Start-Sleep -Seconds 2

Write-Host "    Click the blue 'Enable' button on the page." -ForegroundColor Yellow
Pause-Step

# ── Step 6c: OAuth Consent Screen ──────────────────────────────────────────

Write-Host ""
Write-Info "Opening OAuth Consent Screen setup..."
Start-Process "https://console.cloud.google.com/apis/credentials/consent"
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "    Configure the consent screen:" -ForegroundColor Yellow
Write-Host '    • User Type: "External" → Create' -ForegroundColor White
Write-Host '    • App name: "Email Helper" (or anything)' -ForegroundColor White
Write-Host '    • User support email: your Gmail address' -ForegroundColor White
Write-Host '    • Developer contact: your Gmail address' -ForegroundColor White
Write-Host '    • Click "Save and Continue" through all steps' -ForegroundColor White
Write-Host '    • On the "Test users" page, add YOUR Gmail address' -ForegroundColor White
Write-Host '    • Click "Save and Continue" → "Back to Dashboard"' -ForegroundColor White
Pause-Step

# ── Step 6d: Create OAuth Credentials ──────────────────────────────────────

Write-Host ""
Write-Info "Opening Credentials page..."
Start-Process "https://console.cloud.google.com/apis/credentials"
Start-Sleep -Seconds 2

Write-Host ""
Write-Host "    Create OAuth 2.0 credentials:" -ForegroundColor Yellow
Write-Host '    • Click "+ CREATE CREDENTIALS" → "OAuth client ID"' -ForegroundColor White
Write-Host '    • Application type: "Desktop app"' -ForegroundColor White
Write-Host '    • Name: "Email Helper" (or anything)' -ForegroundColor White
Write-Host '    • Click "Create"' -ForegroundColor White
Write-Host '    • Click "DOWNLOAD JSON"' -ForegroundColor White
Write-Host ""
Write-Host "    Save the downloaded file as:" -ForegroundColor Yellow
Write-Host "    $ScriptDir\credentials\google_credentials.json" -ForegroundColor Cyan
Write-Host ""

# Open credentials folder for easy drag-and-drop
$credDir = Join-Path $ScriptDir "credentials"
if (-not (Test-Path $credDir)) { New-Item -ItemType Directory -Path $credDir -Force | Out-Null }
Start-Process "explorer.exe" $credDir

Write-Host "    The credentials folder has been opened for you." -ForegroundColor Gray
Write-Host "    Rename the downloaded file to 'google_credentials.json' and put it there." -ForegroundColor Yellow
Pause-Step

# ── Step 7: Authenticate with Gmail ─────────────────────────────────────────

Write-Step "7/8" "Authenticate with Gmail"

$credFile = Join-Path $ScriptDir "credentials\google_credentials.json"

if (-not (Test-Path $credFile)) {
    Write-Warn "credentials\google_credentials.json not found yet."
    Write-Host ""
    Write-Host "    Did you download and save the credentials file?" -ForegroundColor Yellow
    Write-Host "    Expected location: $credFile" -ForegroundColor Gray
    Write-Host ""
    $response = Read-Host "    Type 'skip' to skip auth for now, or press Enter to retry"
    
    if ($response -eq "skip") {
        Write-Warn "Skipping authentication. Run gmail_auth.py manually later."
    } else {
        if (Test-Path $credFile) {
            Write-Ok "Found credentials file!"
        } else {
            Write-Err "Still not found. Run gmail_auth.py manually after placing the file."
        }
    }
} 

if (Test-Path $credFile) {
    Write-Info "Running Gmail authentication..."
    Write-Host "    A browser window will open. Sign in with your Gmail account" -ForegroundColor Yellow
    Write-Host "    and click 'Allow' to grant email access." -ForegroundColor Yellow
    Write-Host ""

    & $pythonCmd (Join-Path $ScriptDir "gmail_auth.py")
    
    if ($LASTEXITCODE -eq 0) {
        Write-Ok "Gmail authentication successful!"
    } else {
        Write-Err "Authentication failed. Check the error above and try again."
        Write-Info "You can run gmail_auth.py manually: $pythonCmd gmail_auth.py"
    }
}

# ── Step 8: Final Setup ─────────────────────────────────────────────────────

Write-Step "8/8" "Final Setup — You're Almost Done!"

Write-Host ""
Write-Host "    Opening VS Code..." -ForegroundColor Gray
& $codeCmd $ScriptDir 2>&1 | Out-Null
Start-Sleep -Seconds 3

Write-Host ""
Write-Host "  ╔═══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║                                                       ║" -ForegroundColor Green
Write-Host "  ║   ✓  Setup Complete!                                  ║" -ForegroundColor Green
Write-Host "  ║                                                       ║" -ForegroundColor Green
Write-Host "  ║   Next steps in VS Code:                              ║" -ForegroundColor Green
Write-Host "  ║                                                       ║" -ForegroundColor Green
Write-Host "  ║   1. Open the Copilot Chat panel (Ctrl+Shift+I)      ║" -ForegroundColor Green
Write-Host "  ║   2. Click the model selector at the top              ║" -ForegroundColor Green
Write-Host "  ║   3. Choose 'Claude Opus 4.6'                        ║" -ForegroundColor Green
Write-Host "  ║   4. Type: 'Read my gmail_helper.py file, then       ║" -ForegroundColor Green
Write-Host "  ║      help me organize my inbox'                       ║" -ForegroundColor Green
Write-Host "  ║                                                       ║" -ForegroundColor Green
Write-Host "  ║   See guide.html for detailed instructions & tips!    ║" -ForegroundColor Green
Write-Host "  ║                                                       ║" -ForegroundColor Green
Write-Host "  ╚═══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Pause-Step

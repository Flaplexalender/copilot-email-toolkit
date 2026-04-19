#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════
# Copilot Email Setup — Automated installer for macOS
# ═══════════════════════════════════════════════════════════════════════════
# Usage:
#   chmod +x setup.sh
#   ./setup.sh

set -e

# ── Colors ───────────────────────────────────────────────────────────────
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;90m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

step() { echo -e "\n  ${CYAN}[$1]${NC} ${WHITE}$2${NC}\n  ${GRAY}────────────────────────────────────────────${NC}"; }
ok()   { echo -e "    ${GREEN}✓${NC} $1"; }
warn() { echo -e "    ${YELLOW}⚠${NC} $1"; }
err()  { echo -e "    ${RED}✗${NC} $1"; }
info() { echo -e "    ${GRAY}→${NC} $1"; }

pause_step() {
    echo ""
    echo -e "    ${YELLOW}Press Enter to continue...${NC}"
    read -r
}

# ── Banner ───────────────────────────────────────────────────────────────

clear
echo ""
echo -e "  ${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "  ${CYAN}║                                                       ║${NC}"
echo -e "  ${CYAN}║   Copilot Email Setup — Gmail + AI in VS Code         ║${NC}"
echo -e "  ${CYAN}║                                                       ║${NC}"
echo -e "  ${CYAN}║   This script will help you set up:                   ║${NC}"
echo -e "  ${CYAN}║     • Python 3.10+                                    ║${NC}"
echo -e "  ${CYAN}║     • Visual Studio Code                              ║${NC}"
echo -e "  ${CYAN}║     • GitHub Copilot Pro subscription (\$10/mo)        ║${NC}"
echo -e "  ${CYAN}║     • Google Gmail API access                         ║${NC}"
echo -e "  ${CYAN}║     • Everything you need to manage email with AI     ║${NC}"
echo -e "  ${CYAN}║                                                       ║${NC}"
echo -e "  ${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ── Step 1: Check Python ────────────────────────────────────────────────

step "1/8" "Checking Python installation..."

PYTHON_CMD=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        ver=$("$cmd" --version 2>&1)
        if [[ "$ver" =~ Python\ ([0-9]+)\.([0-9]+) ]]; then
            major="${BASH_REMATCH[1]}"
            minor="${BASH_REMATCH[2]}"
            if [[ "$major" -ge 3 && "$minor" -ge 10 ]]; then
                PYTHON_CMD="$cmd"
                ok "Found $ver"
                break
            fi
        fi
    fi
done

if [[ -z "$PYTHON_CMD" ]]; then
    warn "Python 3.10+ not found."
    info "Opening Python download page..."
    open "https://www.python.org/downloads/macos/"
    echo ""
    echo -e "    ${YELLOW}Install Python, then close this terminal and run ./setup.sh again.${NC}"
    pause_step
    exit 1
fi

# ── Step 2: Check VS Code ──────────────────────────────────────────────

step "2/8" "Checking Visual Studio Code..."

CODE_CMD=""
for cmd in code code-insiders; do
    if command -v "$cmd" &>/dev/null; then
        ver=$("$cmd" --version 2>&1 | head -1)
        if [[ "$ver" =~ ^[0-9]+\.[0-9]+ ]]; then
            CODE_CMD="$cmd"
            ok "Found VS Code ($ver)"
            break
        fi
    fi
done

if [[ -z "$CODE_CMD" ]]; then
    warn "VS Code not found."
    info "Opening VS Code download page..."
    open "https://code.visualstudio.com/Download"
    echo ""
    echo -e "    ${YELLOW}Install VS Code, then close this terminal and run ./setup.sh again.${NC}"
    echo ""
    echo -e "    ${GRAY}After installing, you may need to add the 'code' command to PATH:${NC}"
    echo -e "    ${GRAY}Open VS Code → press Cmd+Shift+P → type 'shell command' →${NC}"
    echo -e "    ${GRAY}click 'Shell Command: Install code command in PATH'${NC}"
    pause_step
    exit 1
fi

# ── Step 3: Install VS Code Extensions ──────────────────────────────────

step "3/8" "Installing VS Code extensions..."

for ext in "GitHub.copilot" "GitHub.copilot-chat" "ms-python.python"; do
    info "Installing $ext..."
    "$CODE_CMD" --install-extension "$ext" --force &>/dev/null
    ok "$ext installed"
done

# ── Step 4: Install Python Dependencies ─────────────────────────────────

step "4/8" "Installing Python packages..."

"$PYTHON_CMD" -m pip install --quiet --upgrade pip 2>/dev/null
"$PYTHON_CMD" -m pip install --quiet google-auth google-auth-oauthlib google-api-python-client 2>&1

if [[ $? -eq 0 ]]; then
    ok "All Python packages installed"
else
    err "Some packages may have failed. Try running manually:"
    info "$PYTHON_CMD -m pip install google-auth google-auth-oauthlib google-api-python-client"
fi

# ── Step 5: GitHub Copilot Pro Subscription ─────────────────────────────

step "5/8" "GitHub Copilot Pro Subscription (\$10/month)"

echo ""
echo -e "    ${WHITE}You need a GitHub account and Copilot Pro subscription.${NC}"
echo -e "    ${WHITE}This gives you access to Claude Opus 4.6 in VS Code Chat.${NC}"
echo ""
echo -e "    ${GRAY}Opening the subscription page now...${NC}"

open "https://github.com/settings/copilot"
sleep 2

info "If you already have Copilot Pro, just continue."
info "If not, subscribe to 'Copilot Pro' (\$10/month)."
pause_step

# ── Step 6: Google Cloud Console ────────────────────────────────────────

step "6/8" "Google Cloud Console — Gmail API Setup"

echo ""
echo -e "    ${WHITE}This is the most involved step. Follow these instructions:${NC}"
echo ""
echo -e "    ${YELLOW}1. Sign in with your Google/Gmail account${NC}"
echo -e "    ${YELLOW}2. Create a new project (name it anything, e.g. 'Email Helper')${NC}"
echo -e "    ${YELLOW}3. Enable the Gmail API (search 'Gmail API' → Enable)${NC}"
echo ""
echo -e "    ${GRAY}Opening Google Cloud Console...${NC}"

open "https://console.cloud.google.com/projectcreate"
sleep 3

info "After creating the project, press Enter to continue..."
pause_step

# ── Step 6b: Enable Gmail API ──────────────────────────────────────────

echo ""
info "Opening Gmail API page..."
open "https://console.cloud.google.com/apis/library/gmail.googleapis.com"
sleep 2

echo -e "    ${YELLOW}Click the blue 'Enable' button on the page.${NC}"
pause_step

# ── Step 6c: OAuth Consent Screen ──────────────────────────────────────

echo ""
info "Opening OAuth Consent Screen setup..."
open "https://console.cloud.google.com/apis/credentials/consent"
sleep 2

echo ""
echo -e "    ${YELLOW}Configure the consent screen:${NC}"
echo -e "    ${WHITE}• User Type: \"External\" → Create${NC}"
echo -e "    ${WHITE}• App name: \"Email Helper\" (or anything)${NC}"
echo -e "    ${WHITE}• User support email: your Gmail address${NC}"
echo -e "    ${WHITE}• Developer contact: your Gmail address${NC}"
echo -e "    ${WHITE}• Click \"Save and Continue\" through all steps${NC}"
echo -e "    ${WHITE}• On \"Test users\" page, add YOUR Gmail address${NC}"
echo -e "    ${WHITE}• Click \"Save and Continue\" → \"Back to Dashboard\"${NC}"
pause_step

# ── Step 6d: Create OAuth Credentials ──────────────────────────────────

echo ""
info "Opening Credentials page..."
open "https://console.cloud.google.com/apis/credentials"
sleep 2

echo ""
echo -e "    ${YELLOW}Create OAuth 2.0 credentials:${NC}"
echo -e "    ${WHITE}• Click \"+ CREATE CREDENTIALS\" → \"OAuth client ID\"${NC}"
echo -e "    ${WHITE}• Application type: \"Desktop app\"${NC}"
echo -e "    ${WHITE}• Name: \"Email Helper\" (or anything)${NC}"
echo -e "    ${WHITE}• Click \"Create\"${NC}"
echo -e "    ${WHITE}• Click \"DOWNLOAD JSON\"${NC}"
echo ""
echo -e "    ${YELLOW}Save the downloaded file as:${NC}"
echo -e "    ${CYAN}${SCRIPT_DIR}/credentials/google_credentials.json${NC}"
echo ""

# Ensure credentials dir exists and open it in Finder
CRED_DIR="${SCRIPT_DIR}/credentials"
mkdir -p "$CRED_DIR"
open "$CRED_DIR"

echo -e "    ${GRAY}The credentials folder has been opened in Finder.${NC}"
echo -e "    ${YELLOW}Rename the downloaded file to 'google_credentials.json' and put it there.${NC}"
pause_step

# ── Step 7: Authenticate with Gmail ─────────────────────────────────────

step "7/8" "Authenticate with Gmail"

CRED_FILE="${SCRIPT_DIR}/credentials/google_credentials.json"

if [[ ! -f "$CRED_FILE" ]]; then
    warn "credentials/google_credentials.json not found yet."
    echo ""
    echo -e "    ${YELLOW}Did you download and save the credentials file?${NC}"
    echo -e "    ${GRAY}Expected location: ${CRED_FILE}${NC}"
    echo ""
    echo -n "    Type 'skip' to skip auth for now, or press Enter to retry: "
    read -r response

    if [[ "$response" == "skip" ]]; then
        warn "Skipping authentication. Run gmail_auth.py manually later."
    else
        if [[ -f "$CRED_FILE" ]]; then
            ok "Found credentials file!"
        else
            err "Still not found. Run gmail_auth.py manually after placing the file."
        fi
    fi
fi

if [[ -f "$CRED_FILE" ]]; then
    info "Running Gmail authentication..."
    echo -e "    ${YELLOW}A browser window will open. Sign in with your Gmail account${NC}"
    echo -e "    ${YELLOW}and click 'Allow' to grant email access.${NC}"
    echo ""

    "$PYTHON_CMD" "${SCRIPT_DIR}/gmail_auth.py"

    if [[ $? -eq 0 ]]; then
        ok "Gmail authentication successful!"
    else
        err "Authentication failed. Check the error above and try again."
        info "You can run gmail_auth.py manually: $PYTHON_CMD gmail_auth.py"
    fi
fi

# ── Step 8: Final Setup ─────────────────────────────────────────────────

step "8/8" "Final Setup — You're Almost Done!"

echo ""
echo -e "    ${GRAY}Opening VS Code...${NC}"
"$CODE_CMD" "$SCRIPT_DIR" &>/dev/null &
sleep 3

echo ""
echo -e "  ${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "  ${GREEN}║                                                       ║${NC}"
echo -e "  ${GREEN}║   ✓  Setup Complete!                                  ║${NC}"
echo -e "  ${GREEN}║                                                       ║${NC}"
echo -e "  ${GREEN}║   Next steps in VS Code:                              ║${NC}"
echo -e "  ${GREEN}║                                                       ║${NC}"
echo -e "  ${GREEN}║   1. Open Copilot Chat (Cmd+Shift+I)                  ║${NC}"
echo -e "  ${GREEN}║   2. Click the model selector at the top              ║${NC}"
echo -e "  ${GREEN}║   3. Choose 'Claude Opus 4.6'                         ║${NC}"
echo -e "  ${GREEN}║   4. Type: 'Read my gmail_helper.py file, then        ║${NC}"
echo -e "  ${GREEN}║      help me organize my inbox'                       ║${NC}"
echo -e "  ${GREEN}║                                                       ║${NC}"
echo -e "  ${GREEN}║   See guide.html for detailed instructions & tips!    ║${NC}"
echo -e "  ${GREEN}║                                                       ║${NC}"
echo -e "  ${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

pause_step

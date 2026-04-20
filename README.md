# Copilot Email Setup Kit

Manage your Gmail inbox with AI (Claude Opus 4.6) in Visual Studio Code.
Works on **Windows** and **Mac**.

## Quick Start

### Windows
1. **Right-click `setup.ps1`** → "Run with PowerShell"
2. Follow the prompts — the script installs everything and opens each browser page for you

### Mac
1. Open **Terminal**, navigate to this folder
2. Run: `chmod +x setup.sh && ./setup.sh`
3. Follow the prompts — same flow as Windows

### Both Platforms
1. **Subscribe** to GitHub Copilot Pro ($10/month) at github.com/settings/copilot
2. **Open VS Code** → sign into GitHub → open Copilot Chat (Ctrl+Shift+I / Cmd+Shift+I) → select **Claude Opus 4.6**
3. **🎉 You now have an AI assistant!** — Copilot can walk you through the remaining Google Cloud / Gmail API steps
4. **Set up Google Cloud** — create project, enable Gmail API, create OAuth credentials
5. **Download credentials** → save as `credentials/google_credentials.json`
6. **Authenticate** — run `python gmail_auth.py` (or `python3` on Mac)
7. **Start chatting** — "Read gmail_helper.py, then help me organize my inbox"

## Detailed Guide

Open **guide.html** in your browser for the full visual step-by-step walkthrough.
The guide has a Windows/Mac toggle and click-by-click instructions for every step.

## Files

| File | Purpose |
|------|---------|
| `guide.html` | Visual step-by-step guide (Windows + Mac) |
| `setup.ps1` | Automated setup script (Windows) |
| `setup.sh` | Automated setup script (Mac) |
| `gmail_auth.py` | Gmail authentication (run once) |
| `gmail_helper.py` | Email toolkit for Copilot |
| `credentials/` | Your Google credentials go here |

## Requirements

- Windows 10/11 or macOS 12+
- Gmail account
- GitHub account + Copilot Pro ($10/month)
- ~30 minutes for initial setup

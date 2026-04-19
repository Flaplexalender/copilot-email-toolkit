"""
Gmail Authentication Script
----------------------------
Run this once to connect your Gmail account.
A browser window will open — sign in and click "Allow".

Usage:
    python gmail_auth.py
"""

import json
import sys
from pathlib import Path

SCOPES = [
    "https://www.googleapis.com/auth/gmail.modify",
    "https://www.googleapis.com/auth/gmail.compose",
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.readonly",
]

SCRIPT_DIR = Path(__file__).parent
CRED_FILE = SCRIPT_DIR / "credentials" / "google_credentials.json"
TOKEN_FILE = SCRIPT_DIR / "credentials" / "google_token.json"


def main():
    # Check dependencies
    try:
        from google_auth_oauthlib.flow import InstalledAppFlow
        from googleapiclient.discovery import build
    except ImportError:
        print("\n  Missing Python packages. Run:")
        print("  pip install google-auth google-auth-oauthlib google-api-python-client\n")
        sys.exit(1)

    # Check credentials file
    if not CRED_FILE.exists():
        print(f"\n  ✗ Credentials file not found at:")
        print(f"    {CRED_FILE}")
        print(f"\n  Download it from Google Cloud Console → Credentials")
        print(f"  and save it as: credentials\\google_credentials.json\n")
        sys.exit(1)

    # Check if already authenticated
    if TOKEN_FILE.exists():
        print(f"\n  Found existing token at {TOKEN_FILE}")
        response = input("  Re-authenticate? (y/N): ").strip().lower()
        if response != "y":
            print("  Keeping existing authentication.")
            _test_connection()
            return

    # Run OAuth flow
    print("\n  Starting authentication...")
    print("  A browser window will open. Sign in with your Gmail account.\n")

    flow = InstalledAppFlow.from_client_secrets_file(str(CRED_FILE), SCOPES)
    creds = flow.run_local_server(port=0)

    # Save token
    TOKEN_FILE.parent.mkdir(parents=True, exist_ok=True)
    TOKEN_FILE.write_text(creds.to_json(), encoding="utf-8")
    print(f"\n  ✓ Authentication successful!")
    print(f"  Token saved to: {TOKEN_FILE}")

    # Test the connection
    _test_connection()


def _test_connection():
    """Quick test: fetch profile and count inbox messages."""
    try:
        from google.oauth2.credentials import Credentials
        from googleapiclient.discovery import build

        creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
        service = build("gmail", "v1", credentials=creds)

        profile = service.users().getProfile(userId="me").execute()
        email = profile.get("emailAddress", "unknown")
        total = profile.get("messagesTotal", 0)

        result = service.users().messages().list(
            userId="me", labelIds=["INBOX"], maxResults=1
        ).execute()
        inbox_count = result.get("resultSizeEstimate", 0)

        print(f"\n  ✓ Connected as: {email}")
        print(f"  ✓ Total messages: {total:,}")
        print(f"  ✓ Inbox messages: {inbox_count:,}")
        print(f"\n  You're all set! Open VS Code and start chatting with Copilot.\n")

    except Exception as e:
        print(f"\n  ⚠ Connection test failed: {e}")
        print(f"  The token was saved, but you may need to re-authenticate.\n")


if __name__ == "__main__":
    main()

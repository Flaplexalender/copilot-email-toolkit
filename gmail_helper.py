"""
Gmail Helper — Email management functions for use with GitHub Copilot Chat
===========================================================================

This file gives Copilot Chat (Claude Opus 4.6) the ability to read, search,
label, archive, draft, and send your Gmail messages.

HOW TO USE WITH COPILOT CHAT:
    1. Open this file in VS Code
    2. Open Copilot Chat (Ctrl+Shift+I)
    3. Select Claude Opus 4.6 as the model
    4. Say: "Read gmail_helper.py, then help me organize my inbox"
    5. Copilot will use these functions to manage your email

Available functions:
    - connect()              → Set up Gmail connection
    - search(query)          → Search for messages
    - read_message(msg_id)   → Read a full message
    - get_thread(thread_id)  → Read entire conversation
    - list_labels()          → Show all labels/folders
    - create_label(name)     → Create a new label
    - label_messages(ids, label)  → Apply a label to messages
    - archive(ids)           → Remove from inbox (keeps in All Mail)
    - trash(ids)             → Move to trash
    - mark_read(ids)         → Mark messages as read
    - draft_new(to, subject, body)  → Create a new draft
    - draft_reply(thread_id, body)  → Draft a reply
    - send_draft(draft_id)   → Send a draft
    - inbox_summary()        → Quick overview of your inbox
"""

import base64
import email
import json
import re
import sys
from datetime import datetime
from email.mime.text import MIMEText
from pathlib import Path
from typing import Optional

# ── Setup ────────────────────────────────────────────────────────────────────

SCRIPT_DIR = Path(__file__).parent
TOKEN_FILE = SCRIPT_DIR / "credentials" / "google_token.json"

SCOPES = [
    "https://www.googleapis.com/auth/gmail.modify",
    "https://www.googleapis.com/auth/gmail.compose",
    "https://www.googleapis.com/auth/gmail.send",
    "https://www.googleapis.com/auth/gmail.readonly",
]

_service = None


def connect():
    """Connect to Gmail. Run this first before using other functions."""
    global _service

    try:
        from google.oauth2.credentials import Credentials
        from google.auth.transport.requests import Request
        from googleapiclient.discovery import build
    except ImportError:
        print("Missing packages. Run: pip install google-auth google-auth-oauthlib google-api-python-client")
        return None

    if not TOKEN_FILE.exists():
        print(f"No token found at {TOKEN_FILE}")
        print("Run gmail_auth.py first to authenticate.")
        return None

    creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)

    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
        TOKEN_FILE.write_text(creds.to_json(), encoding="utf-8")

    _service = build("gmail", "v1", credentials=creds)

    profile = _service.users().getProfile(userId="me").execute()
    print(f"✓ Connected as {profile['emailAddress']}")
    return _service


def _svc():
    """Get or create the Gmail service."""
    global _service
    if _service is None:
        connect()
    return _service


# ── Search & Read ────────────────────────────────────────────────────────────


def search(query: str, max_results: int = 20) -> list[dict]:
    """
    Search Gmail messages.

    Args:
        query: Gmail search query (same syntax as the Gmail search bar).
               Examples:
                 "is:unread"
                 "from:john@example.com"
                 "subject:invoice after:2025/01/01"
                 "has:attachment filename:pdf"
                 "in:inbox is:unread"
                 "label:Finance"
        max_results: Maximum number of results (default 20).

    Returns:
        List of dicts with id, threadId, subject, from, date, snippet, labels.
    """
    svc = _svc()
    result = svc.users().messages().list(
        userId="me", q=query, maxResults=max_results
    ).execute()

    messages = []
    for msg_stub in result.get("messages", []):
        msg = svc.users().messages().get(
            userId="me", id=msg_stub["id"], format="metadata",
            metadataHeaders=["Subject", "From", "Date", "To"]
        ).execute()

        headers = {}
        for h in msg.get("payload", {}).get("headers", []):
            headers[h["name"].lower()] = h["value"]

        messages.append({
            "id": msg["id"],
            "threadId": msg["threadId"],
            "subject": headers.get("subject", "(no subject)"),
            "from": headers.get("from", ""),
            "to": headers.get("to", ""),
            "date": headers.get("date", ""),
            "snippet": msg.get("snippet", ""),
            "labels": msg.get("labelIds", []),
            "unread": "UNREAD" in msg.get("labelIds", []),
        })

    print(f"Found {len(messages)} messages for query: {query}")
    return messages


def read_message(msg_id: str) -> dict:
    """
    Read the full content of a message.

    Args:
        msg_id: The message ID (from search results).

    Returns:
        Dict with id, threadId, subject, from, to, date, body, labels.
    """
    svc = _svc()
    msg = svc.users().messages().get(userId="me", id=msg_id, format="full").execute()

    headers = {}
    for h in msg.get("payload", {}).get("headers", []):
        headers[h["name"].lower()] = h["value"]

    body = _extract_body(msg.get("payload", {}))

    return {
        "id": msg["id"],
        "threadId": msg["threadId"],
        "subject": headers.get("subject", "(no subject)"),
        "from": headers.get("from", ""),
        "to": headers.get("to", ""),
        "date": headers.get("date", ""),
        "body": body,
        "snippet": msg.get("snippet", ""),
        "labels": msg.get("labelIds", []),
    }


def get_thread(thread_id: str) -> list[dict]:
    """
    Get all messages in a conversation thread.

    Args:
        thread_id: The thread ID.

    Returns:
        List of message dicts (same format as read_message), oldest first.
    """
    svc = _svc()
    thread = svc.users().threads().get(userId="me", id=thread_id, format="full").execute()

    messages = []
    for msg in thread.get("messages", []):
        headers = {}
        for h in msg.get("payload", {}).get("headers", []):
            headers[h["name"].lower()] = h["value"]

        body = _extract_body(msg.get("payload", {}))

        messages.append({
            "id": msg["id"],
            "threadId": msg["threadId"],
            "subject": headers.get("subject", "(no subject)"),
            "from": headers.get("from", ""),
            "to": headers.get("to", ""),
            "date": headers.get("date", ""),
            "body": body,
            "snippet": msg.get("snippet", ""),
            "labels": msg.get("labelIds", []),
        })

    print(f"Thread has {len(messages)} messages")
    return messages


# ── Labels ───────────────────────────────────────────────────────────────────


def list_labels() -> list[dict]:
    """
    List all Gmail labels (folders).

    Returns:
        List of dicts with id, name, type (system/user).
    """
    svc = _svc()
    result = svc.users().labels().list(userId="me").execute()

    labels = []
    for label in result.get("labels", []):
        labels.append({
            "id": label["id"],
            "name": label["name"],
            "type": label.get("type", "user"),
        })

    labels.sort(key=lambda x: x["name"])
    print(f"Found {len(labels)} labels")
    return labels


def create_label(name: str) -> dict:
    """
    Create a new label. Supports nested labels with "/" separator.

    Args:
        name: Label name. Use "/" for nesting, e.g., "Finance/Receipts".

    Returns:
        Dict with the new label's id and name.
    """
    svc = _svc()
    body = {
        "name": name,
        "labelListVisibility": "labelShow",
        "messageListVisibility": "show",
    }
    label = svc.users().labels().create(userId="me", body=body).execute()
    print(f"✓ Created label: {label['name']} (id: {label['id']})")
    return {"id": label["id"], "name": label["name"]}


def _get_label_id(name: str) -> Optional[str]:
    """Get label ID by name, creating it if needed."""
    svc = _svc()
    result = svc.users().labels().list(userId="me").execute()
    for label in result.get("labels", []):
        if label["name"].lower() == name.lower():
            return label["id"]

    # Create if not found
    new_label = create_label(name)
    return new_label["id"]


# ── Organize ─────────────────────────────────────────────────────────────────


def label_messages(msg_ids: list[str], label_name: str):
    """
    Apply a label to one or more messages.

    Args:
        msg_ids: List of message IDs (or a single ID string).
        label_name: Label name (created automatically if it doesn't exist).
    """
    if isinstance(msg_ids, str):
        msg_ids = [msg_ids]

    svc = _svc()
    label_id = _get_label_id(label_name)

    svc.users().messages().batchModify(
        userId="me",
        body={"ids": msg_ids, "addLabelIds": [label_id]}
    ).execute()

    print(f"✓ Applied '{label_name}' to {len(msg_ids)} message(s)")


def archive(msg_ids: list[str]):
    """
    Archive messages (remove from Inbox but keep in All Mail).

    Args:
        msg_ids: List of message IDs (or a single ID string).
    """
    if isinstance(msg_ids, str):
        msg_ids = [msg_ids]

    svc = _svc()
    svc.users().messages().batchModify(
        userId="me",
        body={"ids": msg_ids, "removeLabelIds": ["INBOX"]}
    ).execute()

    print(f"✓ Archived {len(msg_ids)} message(s)")


def trash(msg_ids: list[str]):
    """
    Move messages to trash.

    Args:
        msg_ids: List of message IDs (or a single ID string).
    """
    if isinstance(msg_ids, str):
        msg_ids = [msg_ids]

    svc = _svc()
    for mid in msg_ids:
        svc.users().messages().trash(userId="me", id=mid).execute()

    print(f"✓ Trashed {len(msg_ids)} message(s)")


def mark_read(msg_ids: list[str]):
    """
    Mark messages as read.

    Args:
        msg_ids: List of message IDs (or a single ID string).
    """
    if isinstance(msg_ids, str):
        msg_ids = [msg_ids]

    svc = _svc()
    svc.users().messages().batchModify(
        userId="me",
        body={"ids": msg_ids, "removeLabelIds": ["UNREAD"]}
    ).execute()

    print(f"✓ Marked {len(msg_ids)} message(s) as read")


# ── Drafts & Sending ────────────────────────────────────────────────────────


def draft_new(to: str, subject: str, body: str) -> dict:
    """
    Create a new email draft.

    Args:
        to: Recipient email address.
        subject: Email subject line.
        body: Email body (plain text).

    Returns:
        Dict with draft id and message id.
    """
    svc = _svc()

    message = MIMEText(body)
    message["to"] = to
    message["subject"] = subject

    raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
    draft = svc.users().drafts().create(
        userId="me", body={"message": {"raw": raw}}
    ).execute()

    print(f"✓ Draft created: '{subject}' → {to}")
    return {"draft_id": draft["id"], "message_id": draft["message"]["id"]}


def draft_reply(thread_id: str, body: str) -> dict:
    """
    Create a reply draft in an existing conversation thread.

    Args:
        thread_id: The thread ID to reply in.
        body: Reply body text.

    Returns:
        Dict with draft id and message id.
    """
    svc = _svc()

    # Get the last message in the thread for headers
    thread = svc.users().threads().get(
        userId="me", id=thread_id, format="metadata",
        metadataHeaders=["Subject", "From", "To", "Message-ID"]
    ).execute()

    last_msg = thread["messages"][-1]
    headers = {}
    for h in last_msg.get("payload", {}).get("headers", []):
        headers[h["name"].lower()] = h["value"]

    subject = headers.get("subject", "")
    if not subject.lower().startswith("re:"):
        subject = f"Re: {subject}"

    # Reply to the sender
    reply_to = headers.get("from", headers.get("to", ""))

    message = MIMEText(body)
    message["to"] = reply_to
    message["subject"] = subject
    if "message-id" in headers:
        message["In-Reply-To"] = headers["message-id"]
        message["References"] = headers["message-id"]

    raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
    draft = svc.users().drafts().create(
        userId="me",
        body={"message": {"raw": raw, "threadId": thread_id}}
    ).execute()

    print(f"✓ Reply draft created in thread: {subject}")
    return {"draft_id": draft["id"], "message_id": draft["message"]["id"]}


def send_draft(draft_id: str) -> dict:
    """
    Send an existing draft.

    Args:
        draft_id: The draft ID (from draft_new or draft_reply).

    Returns:
        Dict with the sent message id.
    """
    svc = _svc()
    result = svc.users().drafts().send(userId="me", body={"id": draft_id}).execute()
    print(f"✓ Draft sent! Message ID: {result['id']}")
    return {"message_id": result["id"]}


def list_drafts(max_results: int = 20) -> list[dict]:
    """
    List existing drafts.

    Returns:
        List of dicts with draft_id, subject, to, snippet.
    """
    svc = _svc()
    result = svc.users().drafts().list(userId="me", maxResults=max_results).execute()

    drafts = []
    for d in result.get("drafts", []):
        draft = svc.users().drafts().get(userId="me", id=d["id"], format="metadata").execute()
        headers = {}
        for h in draft["message"].get("payload", {}).get("headers", []):
            headers[h["name"].lower()] = h["value"]

        drafts.append({
            "draft_id": d["id"],
            "subject": headers.get("subject", "(no subject)"),
            "to": headers.get("to", ""),
            "snippet": draft["message"].get("snippet", "")[:100],
        })

    print(f"Found {len(drafts)} drafts")
    return drafts


# ── Quick Overview ───────────────────────────────────────────────────────────


def inbox_summary() -> dict:
    """
    Get a quick summary of your inbox.

    Returns:
        Dict with total_inbox, unread_count, and a list of the 10 newest messages.
    """
    svc = _svc()

    # Get inbox count
    inbox_result = svc.users().messages().list(
        userId="me", labelIds=["INBOX"], maxResults=1
    ).execute()
    inbox_total = inbox_result.get("resultSizeEstimate", 0)

    # Get unread count
    unread_result = svc.users().messages().list(
        userId="me", labelIds=["INBOX", "UNREAD"], maxResults=1
    ).execute()
    unread_total = unread_result.get("resultSizeEstimate", 0)

    # Get 10 newest
    newest = search("in:inbox", max_results=10)

    summary = {
        "total_inbox": inbox_total,
        "unread_count": unread_total,
        "newest_messages": newest,
    }

    print(f"\n📬 Inbox: {inbox_total} messages ({unread_total} unread)")
    return summary


# ── Helpers ──────────────────────────────────────────────────────────────────


def _extract_body(payload: dict) -> str:
    """Extract plain text body from a Gmail message payload."""
    if payload.get("mimeType") == "text/plain" and "body" in payload:
        data = payload["body"].get("data", "")
        if data:
            return base64.urlsafe_b64decode(data).decode("utf-8", errors="replace")

    if "parts" in payload:
        for part in payload["parts"]:
            if part.get("mimeType") == "text/plain":
                data = part.get("body", {}).get("data", "")
                if data:
                    return base64.urlsafe_b64decode(data).decode("utf-8", errors="replace")
            if "parts" in part:
                result = _extract_body(part)
                if result:
                    return result

        # Fall back to HTML
        for part in payload["parts"]:
            if part.get("mimeType") == "text/html":
                data = part.get("body", {}).get("data", "")
                if data:
                    html = base64.urlsafe_b64decode(data).decode("utf-8", errors="replace")
                    return re.sub(r"<[^>]+>", "", html).strip()

    return ""


# ── Main (for testing) ──────────────────────────────────────────────────────

if __name__ == "__main__":
    print("Gmail Helper — connecting...")
    connect()
    print("\nRunning inbox summary...")
    inbox_summary()
    print("\nReady! Use these functions with Copilot Chat in VS Code.")

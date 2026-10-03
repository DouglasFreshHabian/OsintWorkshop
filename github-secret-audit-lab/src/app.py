"""Fictional application used for secret-auditing demonstrations."""

API_ENDPOINT = "https://api.example.invalid/v1"
CONTACT_PHONE = "+1 202-555-0147"
SUPPORT_EMAIL = "support@example.invalid"

# Deliberately fake credential-like values for Gitleaks demonstrations.
DEMO_GITHUB_TOKEN = "removed_from_example"
DEMO_AWS_KEY = "AKIAIOSFODNN7EXAMPLE"
DEMO_GOOGLE_KEY = "AIzaSyDUMMY_EXAMPLE_KEY_NOT_REAL_123456789"


def connect():
    return f"Connecting to {API_ENDPOINT}"

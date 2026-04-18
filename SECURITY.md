# Security Policy

## Reporting a vulnerability

Email **rnato.netoo@gmail.com** with details. Do not open a public issue.

Expected response: acknowledgement within 72 hours, triage within 7 days.

## Scope

This is a client-side puzzle game. Likely concerns:

- Save file tampering leading to crashes
- AdMob plugin issues (Android only)
- Third-party dependency vulnerabilities flagged by Dependabot

## Out of scope

- Modifying your own local save file to change scores
- Cheating the daily challenge by changing your device clock
- Self-XSS in exported web build

# CLAUDE.md

Plan for Artifact 4 (TCSS 490): a twice-a-day dose reminder for my mom. Read `README.md` for the requirements, which come from her own answers in `LOG.md`.

## Rules

- **Never put medication names, doses or any real health information** in code, tests, README, LOG, commits or screenshots. Use made-up demo data only. The app itself stores times only.
- The app is a reminder and a log. Do not add anything that suggests, calculates or changes a dose.
- Keep it simple: three tabs, big buttons. Ask before adding features she did not ask for.
- Logic goes in `DoseCore/` with a test for each behaviour; `App/` stays thin. Run `cd DoseCore && swift test` before committing.
- No accounts, servers, analytics or network calls. Data stays on the phone.
- Commit messages are plain and short. **Do not add a `Co-Authored-By: Claude` line or a "Generated with Claude Code" line.**
- Do not push, create repositories or post anything without the user saying so.

## Logging

Add an entry to `LOG.md` for each meaningful step (date, tool, prompt, what it produced, what I changed). Do not invent results. Say plainly what has not been run or tested.

# CLAUDE.md

Plan for Artifact 4 (TCSS 490): a twice-a-day dose reminder for my mom. Read `README.md` for the requirements, which come from her own answers in `LOG.md`.

## The plan in short

- **What:** a twice-a-day (8 am, 8 pm) dose reminder for an iPhone, for my mom: one gentle reminder, then repeats until she taps "I took it"; shows the last missed or late dose; a history she can share with her neurologist. Details and her own answers are in `README.md` and `LOG.md`.
- **Who owns what:** Ibrahim owns everything for now. With a partner: one owns `DoseCore/`, the other `App/`; each works on their own branch and merges by pull request into `main`.
- **Done means:** it runs on her phone, she has used it, and I have logged where she got stuck.

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

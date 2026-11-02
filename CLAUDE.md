# CLAUDE.md

Plan for Artifact 4 (TCSS 490): a customizable dose reminder, built first for my mom. Read `README.md` for the requirements, which come from her own answers in `LOG.md`.

## The plan in short

- **What:** a dose reminder for an iPhone that anyone can customize (add, rename, retime, switch off or delete reminders, up to 8). It starts with my mom's setup, 8 am and 8 pm: one gentle reminder, then repeats until she taps "I took it"; shows the last missed or late dose; a history she can share with her neurologist. Details and her own answers are in `README.md` and `LOG.md`.
- **Who owns what:** Ibrahim owns everything for now. With a partner: one owns `DoseCore/`, the other `App/`; each works on their own branch and merges by pull request into `main`.
- **Done means:** it runs on her phone, she has used it, and I have logged where she got stuck.

## Rules

- **Never put medication names, doses or any real health information** in code, tests, README, LOG, commits or screenshots. Use made-up demo data only, with generic labels like "Morning" or "Reminder 1". The app lets a person type a label for each reminder; it must never suggest one, and labels stay on the phone.
- The app is a reminder and a log. Do not add anything that suggests, calculates or changes a dose.
- Keep it simple: three tabs, big buttons. Ask before adding features she did not ask for. Customizable reminders are the one addition I chose on 2026-11-02.
- Logic goes in `DoseCore/` with a test for each behaviour; `App/` stays thin. Run `cd DoseCore && swift test` before committing.
- No accounts, servers, analytics or network calls. Data stays on the phone.
- Commit messages are plain and short. **Do not add a `Co-Authored-By: Claude` line or a "Generated with Claude Code" line.**
- Do not push, create repositories or post anything without the user saying so.

## Logging

Add an entry to `LOG.md` for each meaningful step (date, tool, prompt, what it produced, what I changed). Do not invent results. Say plainly what has not been run or tested.

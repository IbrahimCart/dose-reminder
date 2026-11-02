# Doses: a simple twice-a-day reminder app

TCSS 490 (Generative AI and Software Development, UW Autumn 2026), Artifact 4: *For Someone Else*, by Ibrahim Cartan.

## Who it is for

My mom, who takes about 12 medications twice a day, 12 hours apart (8 am and 8 pm), and relies on phone alarms and a pillbox. I asked her what she needs before building anything. Her answers are in [`LOG.md`](LOG.md), and the design follows them.

| What she told me | What the app does |
|---|---|
| Uses alarms at 8 am and 8 pm | Two daily doses; the 12 pills are one "Morning" or "Evening" dose with one tap |
| Forgets when busy; can't tell if she already took it | The Today screen says "Taken at 8:04" or "Not yet" in large text |
| Wants one gentle reminder, then something firmer if she misses it | One reminder at dose time; if she has not tapped "I took it", reminders repeat until she does |
| Wants to see the last time she missed a dose | "Last missed or late dose" is on the home screen |
| Wants a record for her neurologist | History list and a share button that makes a plain-text summary |
| Only on her phone, nobody else told | No accounts, no server; data is a file on the phone |
| Does not want her medications named | The app never asks for or stores a medication name |
| Health app is confusing; wants it straightforward | Three tabs, big buttons, almost no settings |

## How it is built

- **`DoseCore/`**: a Swift package with all the logic and no screen code: the schedule, whether a dose is upcoming, due, taken, late or missed, the reminder plan, the neurologist summary and saving to a file. It has 12 unit tests (`cd DoseCore && swift test`).
- **`App/`**: the SwiftUI screens (Today, History, Settings) and the notification code. Reminders are local notifications, so they work offline and without a server. A notification has an "I took it" button, so she can record a dose without opening the app.
- **`project.yml`**: XcodeGen description of the Xcode project (`brew install xcodegen && xcodegen`).

**A dose counts as** *taken* if recorded within 2 hours of its time, *late* if recorded after that, and *missed* if nothing is recorded. The 2-hour window comes from her saying she feels symptoms within about an hour or two of a missed dose; it can be changed in Settings.

## Safety and privacy

- This is a reminder and a log. It never suggests or changes a dose, and it does not replace her doctor's or pharmacist's instructions.
- Only times are stored, on the phone. This repository contains no medication names, and the demo data is made up.
- If reminders are switched off in iPhone Settings, the Today screen says so.

## Team and ownership

Ibrahim only (I asked my professor whether this submission can be done alone; the answer is recorded in `LOG.md`). The person I built it for is my mom, who is outside the team. The earlier attempt for another group (a Discord bot pull request) is in [`IbrahimCart/artifact-4-discord-bot-pr`](https://github.com/IbrahimCart/artifact-4-discord-bot-pr).

## How collisions are avoided

- **One owner:** Ibrahim owns all the code, the log and the card. If a partner joins, we split by folder first: one person owns `DoseCore/` (logic and tests), the other owns `App/` (screens and notifications), and nobody edits the other's folder without asking.
- **Branches:** each person works on their own branch and opens a pull request into `main`; the other person reviews and merges. Nobody pushes straight to `main` once there are two of us.
- **Agents:** each person's agent follows [`CLAUDE.md`](CLAUDE.md), which repeats the plan, so agents that never talk to each other work from the same one.
- **The person it is for** (my mom) does not edit the code. Her feedback goes into `LOG.md` and I change the app.

## Definition of done

1. The app runs on her iPhone and she has used it to record real doses. *Not done yet.*
2. I watched her use it and wrote down where she got stuck and what I changed. *Not done yet.*
3. `LOG.md` is current and my portfolio card links here with a reflection. *In progress.*

## Status

The logic and the screens are written. The logic is tested; the screens pass a type check but have **not been run on a phone or in the simulator yet**, because Xcode is not installed on my Mac yet.

## Running it

1. Install Xcode and `xcodegen`, then run `xcodegen` in this folder to create `DoseReminder.xcodeproj`.
2. Open it in Xcode, pick your team under *Signing*, choose the phone or a simulator and press Run.
3. With a free Apple ID the app expires after 7 days and must be re-installed.

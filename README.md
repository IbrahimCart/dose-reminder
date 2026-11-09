# Doses: a simple customizable reminder app

TCSS 490 (Generative AI and Software Development, UW Autumn 2026), Artifact 4: *For Someone Else*, by Ibrahim Cartan.

## Who it is for

I built it for my mom, who takes about 12 medications twice a day, 12 hours apart (8 am and 8 pm), and relies on phone alarms and a pillbox. I asked her what she needs before building anything. Her answers are in [`LOG.md`](LOG.md), and the design follows them.

On 2026-11-02 I made it general so anyone can use it: a person adds their own reminders, names them, sets the times and switches them on or off. It starts with the two reminders my mom needs (Morning 8:00 and Evening 20:00), so her version is simply the default.

| What she told me | What the app does |
|---|---|
| Uses alarms at 8 am and 8 pm | Starts with two reminders, "Morning" and "Evening"; the 12 pills are one dose with one tap |
| Forgets when busy; can't tell if she already took it | The Today screen says "Taken at 8:04" or "Not yet" in large text |
| Wants one gentle reminder, then something firmer if she misses it | One reminder at dose time; if she has not tapped "I took it", reminders repeat until she does |
| Wants to see the last time she missed a dose | "Last missed or late dose" is on the home screen |
| Wants a record to show her doctor | History list and a share button that makes a plain-text summary (and an optional notes list) |
| Only on her phone, nobody else told | No accounts, no server; data is a file on the phone |
| Does not want her medications named | The app never asks for a medication name or suggests one. Each reminder has a label the person types ("Morning" and "Evening" by default), kept only on the phone |
| Health app is confusing; wants it straightforward | Three tabs, big buttons, a short Settings list |

## How it is built

- **`DoseCore/`**: a Swift package with all the logic and no screen code: the schedule, whether a dose is upcoming, due, taken, late or missed, the reminder plan, the plain-text summary and saving to a file. It has 20 unit tests (`cd DoseCore && swift test`).
- **`App/`**: the SwiftUI screens (Today, History, Settings, and a small editor for one reminder) and the notification code. Reminders are local notifications, so they work offline and without a server. A notification has an "I took it" button, so she can record a dose without opening the app.
- **`project.yml`**: XcodeGen description of the Xcode project (`brew install xcodegen && xcodegen`).

**A dose counts as** *taken* if recorded within 2 hours of its time, *late* if recorded after that, and *missed* if nothing is recorded. The 2-hour window comes from her saying she feels symptoms within about an hour or two of a missed dose; it can be changed in Settings.

## Safety and privacy

- This is a reminder and a log. It never suggests or changes a dose, and it does not replace her doctor's or pharmacist's instructions.
- Only reminder labels, times and notes the person types are stored, and only on the phone. The app never suggests a label, and this repository contains no medication names; the demo data is made up and generic.
- A label the person types also appears in the reminder on the lock screen, and Settings says so.
- If reminders are switched off in iPhone Settings, the Today screen says so.

## Team and ownership

Ibrahim only. I could not find a partner, and as of Nov 8 my professor has not replied to my question about working alone (if he does, the answer goes in `LOG.md`). The plan below, and the team rules in `CLAUDE.md`, still say how a partner would split the work with me. The person I built it for is my mom, who is outside the team. The earlier attempt for another group (a Discord bot pull request) is in [`IbrahimCart/artifact-4-discord-bot-pr`](https://github.com/IbrahimCart/artifact-4-discord-bot-pr).

## How collisions are avoided

- **One owner:** Ibrahim owns all the code, the log and the card. If a partner joins, we split by folder first: one person owns `DoseCore/` (logic and tests), the other owns `App/` (screens and notifications), and nobody edits the other's folder without asking.
- **Branches:** each person works on their own branch and opens a pull request into `main`; the other person reviews and merges. Nobody pushes straight to `main` once there are two of us.
- **Agents:** each person's agent follows [`CLAUDE.md`](CLAUDE.md), which repeats the plan, so agents that never talk to each other work from the same one.
- **The person it is for** (my mom) does not edit the code. Her feedback goes into `LOG.md` and I change the app.

## Definition of done

1. The app runs on her iPhone and she has used it to record real doses. *Done: installed on her phone and she used it.*
2. I watched her use it and wrote down where she got stuck and what I changed. *Done: she got stuck undoing an accidental tap because Undo looked like plain text; it is now a button (LOG Step 11).*
3. `LOG.md` is current and my portfolio card links here with a reflection. *In progress.*

## Customizing reminders

In Settings a person can add a reminder (up to 8, because iOS keeps at most 64 pending notifications), rename it, change its time, switch it off, or swipe to delete it. Each reminder has its own card on Today and its own rows in History. Renaming a reminder keeps its history; deleting one keeps what was already recorded under its old name. Changing a time or adding or removing a reminder restarts "missed" tracking from that moment, so the app never invents missed doses from the past.

Settings also sets how long after its time a dose counts as missed. It is typed as hours and minutes in two boxes (from 1 minute to 24 hours; 90 minutes becomes 1 hour 30 mins), or stepped with the arrows, 15 minutes at a time.

An older save file (from before custom reminders) cannot be read, so the first launch after updating starts fresh.

## Status

The logic is tested (20 unit tests pass) and the app builds with Xcode 27.2. On 2026-11-02 I installed it on my own iPhone 17 Pro Max and confirmed the Today screen shows the two default reminders. The iOS simulator never finished starting on my Mac, so there are no simulator runs.

**Used by my mom:** she used it on her own phone and told me it helped her keep track of her doses and that the reminders came at the right times (LOG Step 13). I did not time the reminders myself. **Not yet verified by me:** adding and editing reminders in Settings on a device, and the "I took it" button on a notification.

## Running it

1. Install Xcode and `xcodegen`, then run `xcodegen` in this folder to create `DoseReminder.xcodeproj`.
2. Open it in Xcode, pick your team under *Signing*, choose the phone or a simulator and press Run.
3. With a free Apple ID the app expires after 7 days and must be re-installed.

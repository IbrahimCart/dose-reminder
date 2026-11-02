# Artifact 4 Log: Doses (reminder app for my mom)

A running log of what I planned and what changed for TCSS 490 Artifact 4, and the AI prompts I used. Newest entries go at the bottom.

## Template

### Step N: short title
- **Date:**
- **Tool / model:**
- **Prompt:**
- **What it produced:**
- **What I changed and why:**

---

### Step 1: Choose the project and the person
- **Date:** 2026-11-01
- **Tool / model:** Claude Code
- **Prompt:** "for artifact 4, i want to make a medication tracker for my mom who takes medication for epilepsy. would that be good for this artifact"
- **What it produced:** A check against the assignment (a real person outside the team, a handover I control, her needs found by asking). It told me to ask her first, keep her real medication information out of public places, and make it a tracker and not medical advice. It listed three ways to build it for an iPhone: a web page, a native app, or her phone's built-in Medications feature.
- **What I changed and why:** I switched Artifact 4 to this project after my first attempt (a pull request to another group's Discord bot, closed by the maintainers the same day; see the notes repo) did not give me a handover. The first attempt stays in the notes repo as part of my reflection.

### Step 2: Ask her what she needs
- **Date:** 2026-11-01
- **Tool / model:** Claude Code (it drafted the questions); I asked her myself.
- **Prompt:** "what are some questions i should ask"
- **What it produced:** 14 questions in four groups (how she manages now, what goes wrong, what would help, her phone and comfort, privacy).
- **What I changed and why:** I asked her and wrote down her answers (summarised, in her words where I could). *Her phone:* iPhone 17 Pro Max. *How she manages:* alarms at 8 am and 8 pm; around 12 medications, 12 hours apart; times rarely change. *What goes wrong:* she has missed doses and feels symptoms within about an hour or two; she forgets when busy or when her routine changes; the only way to know whether she took it is her pillbox. *What would help:* a reminder, and to see the last time she missed a dose; one gentle reminder, switching to a tap-to-confirm one if she misses it; only on her phone, not shared; a record for her neurologist. *Comfort:* she does not use the Health app's Medications feature because it is confusing; she wants something straightforward; she is fine with me setting it up and watching her use it. *Privacy:* she does not want her medications named anywhere.

### Step 3: Decide what to build
- **Date:** 2026-11-01
- **Tool / model:** Claude Code
- **Prompt:** "here are the answers to those questions" (her answers pasted in).
- **What it produced:** A table matching each answer to a feature, and a recommendation: a native iPhone app, because a web page cannot send reliable reminders on an iPhone and she wants reminders that escalate. It also pointed out that her "don't name my medications" request makes things simpler, since the app only needs "Morning" and "Evening".
- **What I changed and why:** I accepted the plan. I did not ask for a seizure log, but I kept a small optional one because she said the record for her neurologist matters (it is one button in History). I did not add sharing with family because she said no.

### Step 4: Build the logic and the screens
- **Date:** 2026-11-01
- **Tool / model:** Claude Code (Claude Opus 5.5 / Sonnet 5.5)
- **Prompt:** "i changed from auto to bypass permissions on here. you could start on the app"
- **What it produced:** The `DoseCore` Swift package (schedule, dose status, reminder plan, neurologist summary, saving to a file) with 12 unit tests, which pass, and the SwiftUI app (Today, History, Settings, notifications with an "I took it" button) with an XcodeGen project file. The app screens pass a type check against the macOS SDK.
- **What I changed and why:** Xcode is not installed on my Mac, so I could not build or run the app. I did not claim it works; I wrote that in the README. I replaced the first test framework (XCTest, not available without Xcode) with Swift Testing so the tests could run. I also made the design choices that protect her: an "Undo" for an accidental tap, a late dose that is recorded as "late" and not hidden, and "I took it" only opening one hour before a dose so she cannot tick tomorrow's dose by mistake.

## Next

- Install Xcode, run the app in the simulator, fix whatever breaks, and add real screenshots.
- Install it on her phone, watch her use it for a few minutes, and write down where she got stuck.
- Hear back from my professor about working alone.
- Write my reflection for the portfolio card.

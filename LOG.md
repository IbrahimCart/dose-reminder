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
- **Prompt:** "for artifact 4, i want to make a medication tracker for my mom, who takes medication every day. would that be good for this artifact"
- **What it produced:** A check against the assignment (a real person outside the team, a handover I control, her needs found by asking). It told me to ask her first, keep her real medication information out of public places, and make it a tracker and not medical advice. It listed three ways to build it for an iPhone: a web page, a native app, or her phone's built-in Medications feature.
- **What I changed and why:** I switched Artifact 4 to this project after my first attempt (a pull request to another group's Discord bot, closed by the maintainers the same day; see the notes repo) did not give me a handover. The first attempt stays in the notes repo as part of my reflection.

### Step 2: Ask her what she needs
- **Date:** 2026-11-01
- **Tool / model:** Claude Code (it drafted the questions); I asked her myself.
- **Prompt:** "what are some questions i should ask"
- **What it produced:** 14 questions in four groups (how she manages now, what goes wrong, what would help, her phone and comfort, privacy).
- **What I changed and why:** I asked her and wrote down her answers (summarised, in her words where I could). *Her phone:* iPhone 17 Pro Max. *How she manages:* alarms at 8 am and 8 pm; around 12 medications, 12 hours apart; times rarely change. *What goes wrong:* she has missed doses and notices it within about an hour or two; she forgets when busy or when her routine changes; the only way to know whether she took it is her pillbox. *What would help:* a reminder, and to see the last time she missed a dose; one gentle reminder, switching to a tap-to-confirm one if she misses it; only on her phone, not shared; a record she can show her doctor. *Comfort:* she does not use the Health app's Medications feature because it is confusing; she wants something straightforward; she is fine with me setting it up and watching her use it. *Privacy:* she does not want her medications named anywhere.

### Step 3: Decide what to build
- **Date:** 2026-11-01
- **Tool / model:** Claude Code
- **Prompt:** "here are the answers to those questions" (her answers pasted in).
- **What it produced:** A table matching each answer to a feature, and a recommendation: a native iPhone app, because a web page cannot send reliable reminders on an iPhone and she wants reminders that escalate. It also pointed out that her "don't name my medications" request makes things simpler, since the app only needs "Morning" and "Evening".
- **What I changed and why:** I accepted the plan. I did not ask for a notes list, but I kept a small optional one because she said a record for her doctor matters (it is one button in History). I did not add sharing with family because she said no.

### Step 4: Build the logic and the screens
- **Date:** 2026-11-01
- **Tool / model:** Claude Code (Claude Sonnet 5.5)
- **Prompt:** "i changed from auto to bypass permissions on here. you could start on the app"
- **What it produced:** The `DoseCore` Swift package (schedule, dose status, reminder plan, doctor summary, saving to a file) with 12 unit tests, which pass, and the SwiftUI app (Today, History, Settings, notifications with an "I took it" button) with an XcodeGen project file. The app screens pass a type check against the macOS SDK.
- **What I changed and why:** Xcode is not installed on my Mac, so I could not build or run the app. I did not claim it works; I wrote that in the README. I replaced the first test framework (XCTest, not available without Xcode) with Swift Testing so the tests could run. I also made the design choices that protect her: an "Undo" for an accidental tap, a late dose that is recorded as "late" and not hidden, and "I took it" only opening one hour before a dose so she cannot tick tomorrow's dose by mistake.

### Step 5: Publish the repository and update the portfolio card
- **Date:** 2026-11-01
- **Tool / model:** Claude Code (Claude Sonnet 5.5)
- **Prompt:** "Yes, do it" (create the public repository, push, and update my Artifact 4 card for the Week 4 check-in).
- **What it produced:** The public repository `IbrahimCart/dose-reminder` with everything above, and an updated Artifact 4 card on my portfolio (title, link to this repository, a progress summary). The old notes repository now points here. It then checked the card against the assignment page: the card and log are in place, but the plan has no section on how collisions are avoided, `CLAUDE.md` does not state the plan itself, and the team is one person.
- **What I changed and why:** I left her health details off the public card, because she asked that her medications not be named and I want the public pages to say as little as possible. The card says plainly that the screens have not been run yet. I decided to add the collision plan and the team plan to `CLAUDE.md` before Nov 8. *Professor's reply about working alone: pending.*

### Step 6: Install Xcode and build the app
- **Date:** 2026-11-02
- **Tool / model:** Claude Code (Claude Sonnet 5.5)
- **Prompt:** "Okay lets continue with the app", then "can you do whats needed yourself? just ask me for stuff you cant access".
- **What it produced:** With Xcode 27.2 installed and its license accepted, it installed `xcodegen`, generated the Xcode project, and built the app for a real iPhone (no signing) and for the simulator. Both builds succeeded. The first build warned that the app did not declare iPad orientations, so it set the app to iPhone only. It also downloaded the iOS 27.2 simulator (8.3 GB).
- **What I changed and why:** Starting the simulator used up almost all of my Mac's free space (it fell to under 500 MB), so I stopped it. I have therefore **not yet seen the app run**, and the README says so. I need to free more disk space before trying again.

### Step 7: Run it on a real iPhone
- **Date:** 2026-11-02
- **Tool / model:** Claude Code (Claude Sonnet 5.5)
- **Prompt:** "Yes, run it", then "Real iPhone" after the simulator kept failing.
- **What it produced:** The simulator booted but never finished its first start (its data migration stalled for over 7 minutes), so no simulator run was possible. We moved Xcode's simulator, build and iPhone-support files (about 8.5 GB) to an external USB flash drive, which freed my Mac's disk, and then built the app signed with my free Apple ID and installed it on my iPhone 17 Pro Max. A screenshot from the phone shows the Today screen with Morning 8:00 AM and Evening 8:00 PM.
- **What I changed and why:** I did the parts only I could: trusting the Mac on the phone, turning on Developer Mode, signing in to Xcode, and trusting the developer profile. I did not change the app in this step. The free Apple ID install expires after 7 days, so it must be re-installed.

### Step 8: Make it a general medication app
- **Date:** 2026-11-02
- **Tool / model:** Claude Code (Claude Sonnet 5.5)
- **Prompt:** "i want the app to be a general medication app that any person can customize what they want", then "option 2 sounds good" (generalize it now, not after the deadline).
- **What it produced:** A fixed Morning/Evening schedule became a list of reminders the person can add, rename, retime, switch off or delete (up to 8, because iOS allows 64 pending notifications). A taken dose is now tied to its reminder as well as its time, so two reminders at the same time do not collide. Tests went from 12 to 17 and all pass; the app builds and installed on my phone. It also reworded the notes list to just "Notes" and the report to "my record".
- **What I changed and why:** I kept my mom's setup as the default so her version still works as before. Because a person can now type a label, I decided the app must never suggest one, I added a line in Settings that labels also show on the lock screen, and I updated the README and `CLAUDE.md` rules that said the app never stores a name. An older save file cannot be read by the new version, so it starts fresh (my phone had no real data). **Not yet tested by me on the phone:** the new Settings screens, whether reminders fire at the right times, and the notification's "I took it" button.

### Step 9: Change how it looks and add confetti
- **Date:** 2026-11-02
- **Tool / model:** Claude Code (Claude Sonnet 5.5)
- **Prompt:** "i want the back ground to be White and the buttons that are blue right now to be green. When "i took it" is clicked i want it to throw confetti to reinforce a good job", then "i want the confetti to at least cover the full screen" and "i dont want it denser i just want it to cover whole screen".
- **What it produced:** A white page with soft grey cards, one teal-green for the buttons, tabs, switches and "taken" text (dark enough for white button text), and confetti with a buzz when a dose is recorded. The app now stays in light mode. With Reduce Motion on, it only buzzes.
- **What I changed and why:** The first confetti only covered the Today screen and many pieces fell too slowly to reach the bottom. The model asked to make it denser, but I only wanted it to cover the whole screen, so the amount went back to the original. It is now drawn over the whole app, including the tab bar. I have **not seen the confetti run myself**; I checked the colors on a screenshot from my phone.

### Step 10: Type the missed-after time in hours and minutes
- **Date:** 2026-11-04
- **Tool / model:** Claude Code (Claude Sonnet 5.5)
- **Prompt:** For the web demo I asked for a small text box on "Count as missed after" where a person can type any number, keeping the up and down arrows, then "i would like a hour(s) and min(s) there". After the demo was live I said "Yes, add it" for the iPhone app.
- **What it produced:** In the iPhone app's Settings, "Count as missed after" is now two boxes (hours and minutes) plus the arrows, which move 15 minutes at a time. The limits (1 minute to 24 hours, and 90 minutes turning into 1 hour 30) are in `DoseCore` with 3 new unit tests; all 20 pass. The same row exists in the web demo on my portfolio, which has its own copy of the logic and tests (14 pass).
- **What I changed and why:** The old setting only allowed 1 to 4 whole hours. A typed time is applied when a box is left or Done is tapped, so the phone's notifications are not rescheduled on every digit. The app compiles with no warnings, but I have **not yet run this change on my phone** or tapped through the new boxes myself.

## Next

- Try the new Settings screens on my phone (add, rename, retime, delete a reminder), fix what breaks, and check a real reminder fires.
- Take clean screenshots without anything else on my phone's status bar.
- Install it on her phone, watch her use it for a few minutes, and write down where she got stuck.
- Hear back from my professor about working alone.
- Write my reflection for the portfolio card.

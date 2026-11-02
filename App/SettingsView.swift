import SwiftUI
import DoseCore

struct SettingsView: View {
    @EnvironmentObject var model: AppModel
    @State private var editing: Reminder?
    @State private var editingIsNew = false

    private var reminders: [Reminder] { model.log.schedule.reminders }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(reminders) { reminder in
                        HStack {
                            Button {
                                editingIsNew = false
                                editing = reminder
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(reminder.title).font(.headline)
                                    Text(time(of: reminder), style: .time).foregroundStyle(.secondary)
                                }
                            }
                            .foregroundStyle(.primary)
                            Spacer()
                            Toggle("\(reminder.title) reminder", isOn: enabled(reminder)).labelsHidden()
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { model.deleteReminder(id: reminders[index].id) }
                    }
                    if reminders.count < Schedule.maxReminders {
                        Button {
                            editingIsNew = true
                            editing = Reminder(title: "", time: DoseTime(hour: 12, minute: 0))
                        } label: {
                            Label("Add a reminder", systemImage: "plus")
                        }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Up to \(Schedule.maxReminders). Names you type also show in the reminder on your lock screen. Swipe a reminder to delete it; what you already recorded stays in History.")
                }
                .listRowBackground(Color.doseCard)
                Section {
                    Stepper("Repeat every \(model.log.schedule.followUpMinutes) minutes",
                            value: schedule(\.followUpMinutes), in: 5...30, step: 5)
                    Stepper("Count as missed after \(graceHours) \(graceHours == 1 ? "hour" : "hours")",
                            value: hours, in: 1...4)
                } header: {
                    Text("Repeats")
                } footer: {
                    Text("You get one gentle reminder at the set time. If you have not tapped \"I took it\", reminders repeat until you do.")
                }
                .listRowBackground(Color.doseCard)
                Section {
                    Text("Everything stays on this phone. Nothing is sent anywhere. This app is a reminder and a record only. Always follow your doctor's and pharmacist's instructions.")
                        .font(.footnote)
                }
                .listRowBackground(Color.doseCard)
            }
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .navigationTitle("Settings")
            .sheet(item: $editing) { reminder in
                ReminderEditor(reminder: reminder, isNew: editingIsNew)
            }
        }
    }

    private func time(of reminder: Reminder) -> Date {
        model.calendar.date(bySettingHour: reminder.time.hour, minute: reminder.time.minute, second: 0, of: Date()) ?? Date()
    }

    private func enabled(_ reminder: Reminder) -> Binding<Bool> {
        Binding(
            get: { reminder.isEnabled },
            set: { var r = reminder; r.isEnabled = $0; model.saveReminder(r) }
        )
    }

    private func schedule(_ keyPath: WritableKeyPath<Schedule, Int>) -> Binding<Int> {
        Binding(
            get: { model.log.schedule[keyPath: keyPath] },
            set: { var s = model.log.schedule; s[keyPath: keyPath] = $0; model.changeSchedule(s) }
        )
    }

    private var graceHours: Int { model.log.schedule.graceMinutes / 60 }

    private var hours: Binding<Int> {
        Binding(
            get: { model.log.schedule.graceMinutes / 60 },
            set: { var s = model.log.schedule; s.graceMinutes = $0 * 60; model.changeSchedule(s) }
        )
    }
}

/// Add or change one reminder. Nothing is saved until Save is tapped, so typing a name does not
/// reschedule the phone's notifications on every letter.
struct ReminderEditor: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var reminder: Reminder
    let isNew: Bool

    init(reminder: Reminder, isNew: Bool) {
        _reminder = State(initialValue: reminder)
        self.isNew = isNew
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("For example: Morning", text: $reminder.title)
                }
                .listRowBackground(Color.doseCard)
                Section {
                    DatePicker("Time", selection: time, displayedComponents: .hourAndMinute)
                }
                .listRowBackground(Color.doseCard)
                if !isNew {
                    Section {
                        Button("Delete this reminder", role: .destructive) {
                            model.deleteReminder(id: reminder.id)
                            dismiss()
                        }
                    }
                    .listRowBackground(Color.doseCard)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .navigationTitle(isNew ? "New reminder" : "Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var saved = reminder
                        let name = String(saved.title.trimmingCharacters(in: .whitespacesAndNewlines).prefix(30))
                        saved.title = name.isEmpty ? "Reminder" : name
                        model.saveReminder(saved)
                        dismiss()
                    }
                }
            }
        }
    }

    private var time: Binding<Date> {
        Binding(
            get: {
                model.calendar.date(bySettingHour: reminder.time.hour, minute: reminder.time.minute, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                let c = model.calendar.dateComponents([.hour, .minute], from: date)
                reminder.time = DoseTime(hour: c.hour ?? 8, minute: c.minute ?? 0)
            }
        )
    }
}

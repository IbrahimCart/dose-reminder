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
                    GraceTimeRow()
                } header: {
                    Text("Repeats")
                } footer: {
                    Text("You get one gentle reminder at the set time. If you have not tapped \"I took it\", reminders repeat until you do. Type hours and minutes (from 1 minute to 24 hours) for when a dose counts as missed, or use the arrows, which move 15 minutes at a time.")
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

}

/// "Count as missed after": hours and minutes typed in two boxes, or stepped with the arrows (15 minutes at a time).
/// A typed time is applied when a box is left or Done is tapped, so typing does not reschedule on every digit.
struct GraceTimeRow: View {
    @EnvironmentObject var model: AppModel
    @State private var hoursText = ""
    @State private var minutesText = ""
    @FocusState private var focus: Field?

    private enum Field { case hours, minutes }

    private var total: Int { model.log.schedule.graceMinutes }
    private var hours: Int { total / 60 }
    private var minutes: Int { total % 60 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Count as missed after")
                Spacer()
                Stepper("Count as missed after",
                        onIncrement: { model.setGraceMinutes(total + Schedule.graceStepMinutes) },
                        onDecrement: { model.setGraceMinutes(total - Schedule.graceStepMinutes) })
                    .labelsHidden()
            }
            HStack(spacing: 8) {
                box($hoursText, field: .hours, label: "Hours")
                Text(hours == 1 ? "hour" : "hours")
                box($minutesText, field: .minutes, label: "Minutes").padding(.leading, 8)
                Text(minutes == 1 ? "min" : "mins")
            }
        }
        .onAppear(perform: load)
        .onChange(of: total) { _, _ in load() }
        .onChange(of: focus) { old, _ in if old != nil { apply() } }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focus = nil }
            }
        }
    }

    private func box(_ text: Binding<String>, field: Field, label: String) -> some View {
        TextField("0", text: text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .focused($focus, equals: field)
            .frame(width: 56)
            .padding(.vertical, 6)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4)))
            .accessibilityLabel(label)
            .onChange(of: text.wrappedValue) { _, new in
                let digits = String(new.filter(\.isNumber).prefix(2))
                if digits != new { text.wrappedValue = digits }
            }
    }

    private func load() {
        hoursText = String(hours)
        minutesText = String(minutes)
    }

    /// An empty pair of boxes puts the current time back; otherwise a missing box counts as 0.
    private func apply() {
        let h = Int(hoursText), m = Int(minutesText)
        if h != nil || m != nil {
            model.setGraceMinutes(Schedule.clampedGraceMinutes(hours: h ?? 0, minutes: m ?? 0))
        }
        load()
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

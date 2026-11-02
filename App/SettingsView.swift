import SwiftUI
import DoseCore

struct SettingsView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Dose times") {
                    DatePicker("Morning", selection: binding(for: .morning), displayedComponents: .hourAndMinute)
                    DatePicker("Evening", selection: binding(for: .evening), displayedComponents: .hourAndMinute)
                }
                Section {
                    Stepper("Repeat every \(model.log.schedule.followUpMinutes) minutes",
                            value: schedule(\.followUpMinutes), in: 5...30, step: 5)
                    Stepper("Count as missed after \(model.log.schedule.graceMinutes / 60) hours",
                            value: hours, in: 1...4)
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("You get one gentle reminder at dose time. If you have not tapped \"I took it\", reminders repeat until you do.")
                }
                Section {
                    Text("This app only records times. It does not store medication names and does not send anything off your phone. Always follow your doctor's and pharmacist's instructions for your medication.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func binding(for slot: DoseSlot) -> Binding<Date> {
        Binding(
            get: {
                let t = model.log.schedule.time(for: slot)
                return model.calendar.date(bySettingHour: t.hour, minute: t.minute, second: 0, of: Date()) ?? Date()
            },
            set: { date in
                var s = model.log.schedule
                let c = model.calendar.dateComponents([.hour, .minute], from: date)
                let t = DoseTime(hour: c.hour ?? 8, minute: c.minute ?? 0)
                if slot == .morning { s.morning = t } else { s.evening = t }
                model.changeSchedule(s)
            }
        )
    }

    private func schedule(_ keyPath: WritableKeyPath<Schedule, Int>) -> Binding<Int> {
        Binding(
            get: { model.log.schedule[keyPath: keyPath] },
            set: { var s = model.log.schedule; s[keyPath: keyPath] = $0; model.changeSchedule(s) }
        )
    }

    private var hours: Binding<Int> {
        Binding(
            get: { model.log.schedule.graceMinutes / 60 },
            set: { var s = model.log.schedule; s.graceMinutes = $0 * 60; model.changeSchedule(s) }
        )
    }
}

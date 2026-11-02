import SwiftUI
import DoseCore

struct HomeView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if !model.notificationsAllowed {
                    Text("Reminders are off. Turn on notifications for this app in the iPhone Settings app.")
                        .font(.callout)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.orange.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
                }
                if model.today.isEmpty {
                    Text("No reminders yet. Add one in Settings.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                ForEach(model.today) { occ in
                    DoseCard(occurrence: occ)
                }
                LastMissedView()
            }
            .padding()
        }
        .background(Color.white)
    }
}

struct DoseCard: View {
    @EnvironmentObject var model: AppModel
    let occurrence: Occurrence

    var body: some View {
        let status = model.status(occurrence)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(occurrence.title).font(.title.bold())
                Spacer()
                Text(occurrence.dueAt, style: .time).font(.title2)
            }
            Text(statusText(status))
                .font(.title3)
                .foregroundStyle(statusColor(status))

            switch status {
            case .taken, .takenLate:
                Button("Undo", role: .destructive) { model.undoTaken(occurrence) }
                    .font(.body)
            default:
                Button {
                    model.markTaken(occurrence)
                    model.celebrate()
                } label: {
                    Text(status == .missed ? "I took it late" : "I took it")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, minHeight: 64)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!model.canMarkTaken(occurrence))
            }
        }
        .padding()
        .background(Color.doseCard, in: RoundedRectangle(cornerRadius: 16))
    }

    private func statusText(_ status: DoseStatus) -> String {
        switch status {
        case .upcoming: return "Not yet"
        case .due: return "Due now"
        case .taken(let at): return "Taken at \(at.formatted(date: .omitted, time: .shortened))"
        case .takenLate(let at): return "Taken late, at \(at.formatted(date: .omitted, time: .shortened))"
        case .missed: return "Not recorded"
        }
    }

    private func statusColor(_ status: DoseStatus) -> Color {
        switch status {
        case .taken: return .doseGreen
        case .takenLate: return .orange
        case .due, .missed: return .red
        case .upcoming: return .secondary
        }
    }
}

struct LastMissedView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Last missed or late dose").font(.headline)
            if let occ = model.lastMissedOrLate {
                Text("\(occ.title), \(occ.dueAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.title3)
            } else {
                Text("None yet").font(.title3).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.doseCard, in: RoundedRectangle(cornerRadius: 16))
    }
}

import SwiftUI
import DoseCore

struct HistoryView: View {
    @EnvironmentObject var model: AppModel
    @State private var showingSeizureSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ShareLink(item: model.report) {
                        Label("Share my record", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        showingSeizureSheet = true
                    } label: {
                        Label("Add a note", systemImage: "plus")
                    }
                }
                .listRowBackground(Color.doseCard)
                if !model.log.seizures.isEmpty {
                    Section("Notes") {
                        ForEach(model.log.seizures.sorted { $0.at > $1.at }) { s in
                            VStack(alignment: .leading) {
                                Text(s.at.formatted(date: .abbreviated, time: .shortened))
                                if !s.note.isEmpty { Text(s.note).foregroundStyle(.secondary) }
                            }
                            .swipeActions { Button("Delete", role: .destructive) { model.removeSeizure(s) } }
                        }
                    }
                    .listRowBackground(Color.doseCard)
                }
                Section("Doses") {
                    if model.history.isEmpty {
                        Text("Nothing yet. Doses show up here once they are due.").foregroundStyle(.secondary)
                    }
                    ForEach(model.history) { occ in
                        HistoryRow(occurrence: occ)
                    }
                }
                .listRowBackground(Color.doseCard)
            }
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .navigationTitle("History")
            .sheet(isPresented: $showingSeizureSheet) { SeizureSheet() }
        }
    }
}

struct HistoryRow: View {
    @EnvironmentObject var model: AppModel
    let occurrence: Occurrence

    var body: some View {
        let status = model.status(occurrence)
        HStack {
            VStack(alignment: .leading) {
                Text("\(occurrence.title), \(occurrence.dueAt.formatted(date: .abbreviated, time: .omitted))")
                Text(detail(status)).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: icon(status)).foregroundStyle(color(status))
        }
    }

    private func detail(_ s: DoseStatus) -> String {
        switch s {
        case .taken(let at): return "Taken \(at.formatted(date: .omitted, time: .shortened))"
        case .takenLate(let at): return "Late, taken \(at.formatted(date: .omitted, time: .shortened))"
        case .missed: return "Missed"
        case .due: return "Due now"
        case .upcoming: return "Not yet"
        }
    }

    private func icon(_ s: DoseStatus) -> String {
        switch s {
        case .taken: return "checkmark.circle.fill"
        case .takenLate: return "clock.badge.exclamationmark"
        case .missed: return "xmark.circle.fill"
        default: return "circle"
        }
    }

    private func color(_ s: DoseStatus) -> Color {
        switch s {
        case .taken: return .doseGreen
        case .takenLate: return .orange
        case .missed: return .red
        default: return .secondary
        }
    }
}

struct SeizureSheet: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("What happened (optional)") {
                    TextField("For example: felt dizzy after", text: $note, axis: .vertical)
                }
                .listRowBackground(Color.doseCard)
                Text("Saved with the current time.").font(.footnote).foregroundStyle(.secondary)
            }
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .navigationTitle("Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { model.addSeizure(note: note); dismiss() }
                }
            }
        }
    }
}

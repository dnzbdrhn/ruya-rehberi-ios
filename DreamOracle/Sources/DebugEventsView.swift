import SwiftUI

#if DEBUG
struct DebugEventsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var events: [AnalyticsRecord] = []

    var body: some View {
        NavigationStack {
            List(events) { event in
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline)
                    Text(Self.timestampFormatter.string(from: event.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !event.payload.isEmpty {
                        Text(event.payload.description)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Debug Events")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") {
                        events = Analytics.recentEvents(limit: 50)
                    }
                }
            }
            .onAppear {
                events = Analytics.recentEvents(limit: 50)
            }
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()
}
#endif


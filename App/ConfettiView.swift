import SwiftUI

/// Confetti that rains down across the whole screen, as a reward for recording a dose. Every piece is fast
/// enough to reach the bottom before `ConfettiView.duration` is up, when the model removes the view.
struct ConfettiView: View {
    static let duration: TimeInterval = 3.6

    private struct Piece {
        let x = Double.random(in: 0...1)
        let delay = Double.random(in: 0...0.9)
        let speed = Double.random(in: 520...950)
        let startAbove = Double.random(in: 0...160)
        let sway = Double.random(in: 1.5...4)
        let swayWidth = Double.random(in: 10...32)
        let phase = Double.random(in: 0...6.28)
        let spin = Double.random(in: -6...6)
        let width = Double.random(in: 7...12)
        let height = Double.random(in: 11...18)
        let color = [Color.doseGreen, .teal, .yellow, .pink, .blue, .orange, .purple].randomElement()!
    }

    private let pieces = (0..<90).map { _ in Piece() }
    @State private var start = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSince(start)
                for piece in pieces where t > piece.delay {
                    let age = t - piece.delay
                    let x = piece.x * size.width + sin(age * piece.sway + piece.phase) * piece.swayWidth
                    let y = -24 - piece.startAbove + age * piece.speed
                    guard y < size.height + 24 else { continue }
                    var pieceContext = context
                    pieceContext.opacity = min(1, max(0, (Self.duration - t) / 0.6))
                    pieceContext.translateBy(x: x, y: y)
                    pieceContext.rotate(by: .radians(age * piece.spin + piece.phase))
                    pieceContext.fill(
                        Path(roundedRect: CGRect(x: -piece.width / 2, y: -piece.height / 2,
                                                 width: piece.width, height: piece.height), cornerRadius: 2),
                        with: .color(piece.color)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

import SwiftUI

/// Spike measuring for gate G0. Untested by agreement; goes away at S0.4.

/// Nearest-rank percentile: the smallest sample that at least `percent`% of the samples do not
/// exceed, that is, number ceil(percent / 100 × count), counting from 1. No interpolation, so the
/// median of an even count is the lower of the two middle samples. `sorted` is in ascending order.
nonisolated func percentile(_ percent: Double, of sorted: [Double]) -> Double? {
    guard !sorted.isEmpty else { return nil }
    let rank = Int((percent * Double(sorted.count) / 100).rounded(.up))
    return sorted[min(max(rank, 1), sorted.count) - 1]
}

/// Keeps the draw times of the latest frames. Deliberately not observable: writing to it while
/// drawing must not cause another draw.
final class FrameRecorder {
    /// 60 s of drawing at 60 frames a second.
    private let capacity = 3_600
    private let clock = ContinuousClock()
    private var frames: [(end: ContinuousClock.Instant, ms: Double)] = []

    func time(_ draw: () -> Void) {
        let start = clock.now
        draw()
        let end = clock.now
        frames.append((end, (end - start) / .milliseconds(1)))
        if frames.count > capacity { frames.removeFirst(frames.count - capacity) }
    }

    func reset() {
        frames.removeAll()
    }

    var summary: String {
        let sorted = frames.map(\.ms).sorted()
        guard let median = percentile(50, of: sorted),
              let p95 = percentile(95, of: sorted),
              let max = sorted.last
        else { return "no frames yet" }
        let second = clock.now - .seconds(1)
        let fps = frames.reversed().prefix { $0.end > second }.count
        return String(format: "median %.2f  p95 %.2f  max %.2f ms\n%d frames  %d fps",
                      median, p95, max, sorted.count, fps)
    }
}

/// Draw times, refreshed twice a second. Tap to start a new measurement.
struct FrameHUD: View {
    let recorder: FrameRecorder
    var lastZoom: LastZoom?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { _ in
            Text(recorder.summary + "\n" + (lastZoom?.summary ?? "no zoom yet"))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.black)
                .padding(8)
                .background(.white.opacity(0.85), in: .rect(cornerRadius: 8))
                .onTapGesture { recorder.reset() }
        }
    }
}

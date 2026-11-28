import Foundation
import JBGeo
import Observation

/// What the touches do to the camera (Systems Detail 16.1, items 4, 5 and 8). The math is JBGeo's;
/// this keeps track of one gesture at a time and of the coast after it.
@Observable
final class GlobeMotion {
    private(set) var camera: GlobeCamera
    private(set) var coast: GlobeCoast?

    // Bookkeeping that draws nothing.
    @ObservationIgnored private var landed: ScreenPoint?
    @ObservationIgnored private var hadTwoFingers = false
    @ObservationIgnored private var grabbed: (point: ScreenPoint, fingers: Int)?
    @ObservationIgnored private var samples: [CameraSample] = []
    @ObservationIgnored private var lastFrame = Date.distantPast

    init(camera: GlobeCamera) {
        self.camera = camera
    }

    /// The first finger of a gesture is on the glass.
    func touchDown(at point: ScreenPoint) {
        coast = nil
        landed = point
        hadTwoFingers = false
        grabbed = nil
        samples = []
    }

    func secondFingerLanded() {
        hadTwoFingers = true
    }

    /// The drag is recognised, a little way from where the finger landed. `stillTime` is the last
    /// moment the finger was still there.
    func dragBegan(at point: ScreenPoint, fingers: Int, stillTime: Double, time: Double, in viewport: GlobeViewport) {
        samples = [CameraSample(timeSeconds: stillTime, centre: camera.centre)]
        // One finger takes hold of what it landed on. Two take hold where they are now.
        if fingers == 1, !hadTwoFingers, let landed {
            grabbed = (landed, 1)
        } else {
            grabbed = nil
        }
        dragMoved(to: point, fingers: fingers, time: time, in: viewport)
    }

    func dragMoved(to point: ScreenPoint, fingers: Int, time: Double, in viewport: GlobeViewport) {
        if fingers > 1 { hadTwoFingers = true }
        // A finger landing or lifting moves the midpoint; take hold again without turning.
        if let grabbed, grabbed.fingers == fingers {
            camera.grab(from: grabbed.point, to: point, in: viewport)
        }
        grabbed = (point, fingers)
        record(time)
    }

    func dragEnded(time: Double, reduceMotion: Bool, in viewport: GlobeViewport) {
        grabbed = nil
        record(time)
        guard !reduceMotion, !hadTwoFingers else { return }
        coast = GlobeCoast(samples: samples, zoom: camera.zoom, viewport: viewport)
        lastFrame = .now
    }

    /// `midpoint` is between the fingers now; `factor` is the change of their spread.
    func pinched(by factor: Double, about midpoint: ScreenPoint, in viewport: GlobeViewport) {
        hadTwoFingers = true
        // Zoom about where the drag last held, so its next step carries on from the same place.
        camera.zoom(by: factor, about: grabbed?.point ?? midpoint, in: viewport)
    }

    /// Moves the coast on to the frame at `date`.
    func frame(at date: Date) {
        guard var coasting = coast else { return }
        coasting.advance(&camera, by: max(0, date.timeIntervalSince(lastFrame)))
        lastFrame = max(date, lastFrame)
        coast = coasting.isFinished ? nil : coasting
    }

    private func record(_ time: Double) {
        samples.append(CameraSample(timeSeconds: time, centre: camera.centre))
        // The coast only looks back 80 ms; this is far more than that.
        if samples.count > 64 { samples.removeFirst(samples.count - 64) }
    }
}

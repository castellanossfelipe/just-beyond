import Foundation
import JBGeo
import Observation

/// What the touches do to the camera (Systems Detail 16.1, items 4 to 8). The math is JBGeo's;
/// this keeps track of one gesture at a time and of the movement after it.
@Observable
final class GlobeMotion {
    private(set) var camera: GlobeCamera
    private(set) var coast: GlobeCoast?
    private(set) var zooming: GlobeZoomAnimation?

    /// Whether the camera moves with no finger on it, so frames have to run.
    var isMoving: Bool { coast != nil || zooming != nil }

    /// How far the second tap's finger goes before it is a slide, not a tap, in points. [tune]
    private static let slideSlop = 10.0

    // Bookkeeping that draws nothing.
    @ObservationIgnored private var landed: ScreenPoint?
    @ObservationIgnored private var hadTwoFingers = false
    @ObservationIgnored private var grabbed: (point: ScreenPoint, fingers: Int)?
    @ObservationIgnored private var samples: [CameraSample] = []
    /// The one-handed zoom: the second tap and where the finger was last. Drags do nothing meanwhile.
    @ObservationIgnored private var slide: (about: ScreenPoint, lastY: Double, moving: Bool)?
    @ObservationIgnored private var lastFrame = Date.distantPast

    init(camera: GlobeCamera) {
        self.camera = camera
    }

    /// The first finger of a gesture is on the glass.
    func touchDown(at point: ScreenPoint) {
        coast = nil
        zooming = nil
        slide = nil
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
        guard slide == nil else { return }
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
        guard slide == nil else { return }
        if fingers > 1 { hadTwoFingers = true }
        // A finger landing or lifting moves the midpoint; take hold again without turning.
        if let grabbed, grabbed.fingers == fingers {
            camera.grab(from: grabbed.point, to: point, in: viewport)
        }
        grabbed = (point, fingers)
        record(time)
    }

    func dragEnded(time: Double, reduceMotion: Bool, in viewport: GlobeViewport) {
        guard slide == nil else { return }
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

    /// The second tap of a double-tap has landed and is still down.
    func slideBegan(at point: ScreenPoint) {
        slide = (point, point.y, false)
    }

    /// Slide up to zoom in, down to zoom out, about where the finger landed.
    func slideMoved(to point: ScreenPoint, in viewport: GlobeViewport) {
        guard !hadTwoFingers, var sliding = slide else { return }
        if sliding.moving {
            camera.zoom(by: GlobeCamera.slideZoomFactor(slidUp: sliding.lastY - point.y),
                        about: sliding.about, in: viewport)
        } else {
            // Zoom is counted from here, so crossing the slop is no jump.
            guard abs(point.y - sliding.about.y) > Self.slideSlop else { return }
            sliding.moving = true
        }
        sliding.lastY = point.y
        slide = sliding
    }

    func doubleTapped(at point: ScreenPoint, reduceMotion: Bool, in viewport: GlobeViewport) {
        // A short slide can still pass for a tap; it has zoomed already.
        guard slide?.moving != true else { return }
        zoom(by: 2, about: point, reduceMotion: reduceMotion, in: viewport)
    }

    func twoFingerTapped(at midpoint: ScreenPoint, reduceMotion: Bool, in viewport: GlobeViewport) {
        zoom(by: 0.5, about: midpoint, reduceMotion: reduceMotion, in: viewport)
    }

    /// Moves the coast or the zoom on to the frame at `date`.
    func frame(at date: Date, in viewport: GlobeViewport) {
        let seconds = max(0, date.timeIntervalSince(lastFrame))
        lastFrame = max(date, lastFrame)
        if var coasting = coast {
            coasting.advance(&camera, by: seconds)
            coast = coasting.isFinished ? nil : coasting
        }
        if var animation = zooming {
            animation.advance(&camera, by: seconds, in: viewport)
            zooming = animation.isFinished ? nil : animation
        }
    }

    private func zoom(by factor: Double, about point: ScreenPoint, reduceMotion: Bool, in viewport: GlobeViewport) {
        coast = nil
        var animation = GlobeZoomAnimation(factor: factor, about: point, from: camera)
        if reduceMotion {
            animation.advance(&camera, by: GlobeZoomAnimation.seconds, in: viewport)
        } else {
            zooming = animation
            lastFrame = .now
        }
    }

    private func record(_ time: Double) {
        samples.append(CameraSample(timeSeconds: time, centre: camera.centre))
        // The coast only looks back 80 ms; this is far more than that.
        if samples.count > 64 { samples.removeFirst(samples.count - 64) }
    }
}

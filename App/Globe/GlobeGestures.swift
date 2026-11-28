import JBGeo
import SwiftUI
import UIKit.UIGestureRecognizerSubclass

// UIKit recognizers, because SwiftUI's drag and magnify gestures report neither the midpoint of
// the touches nor how many there are (Software Design 8).

/// Begins the moment a finger lands, and reports again when another joins it. It never gets in
/// the way of the other recognizers.
final class TouchDownRecognizer: UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        state = state == .possible ? .began : .changed
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        endIfAllLifted(event)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        endIfAllLifted(event)
    }

    private func endIfAllLifted(_ event: UIEvent) {
        let down = event.touches(for: self)?.contains { $0.phase != .ended && $0.phase != .cancelled }
        if down != true { state = .ended }
    }

    override func canPrevent(_ other: UIGestureRecognizer) -> Bool { false }
    override func canBePrevented(by other: UIGestureRecognizer) -> Bool { false }
}

/// A pan that keeps the times of its touches, which the coast is worked out from.
final class TimedPanRecognizer: UIPanGestureRecognizer {
    /// When the latest touch event happened.
    private(set) var eventTime: TimeInterval = 0
    /// The last moment the first finger was still where it landed.
    private(set) var stillTime: TimeInterval = 0
    private var first: (touch: UITouch, location: CGPoint)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        eventTime = event.timestamp
        if first == nil, let touch = touches.first {
            first = (touch, touch.location(in: nil))
            stillTime = event.timestamp
        }
        super.touchesBegan(touches, with: event)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        eventTime = event.timestamp
        if state == .possible, let first {
            let now = first.touch.location(in: nil)
            if hypot(now.x - first.location.x, now.y - first.location.y) < 1 { stillTime = event.timestamp }
        }
        super.touchesMoved(touches, with: event)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        eventTime = event.timestamp
        super.touchesEnded(touches, with: event)
    }

    override func reset() {
        super.reset()
        first = nil
    }
}

/// Lets the recognizers run together.
final class SimultaneousGestures: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(_ recognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}

private func screenPoint(_ point: CGPoint) -> ScreenPoint {
    ScreenPoint(x: point.x, y: point.y)
}

struct GlobeTouchDown: UIGestureRecognizerRepresentable {
    let motion: GlobeMotion

    func makeUIGestureRecognizer(context: Context) -> TouchDownRecognizer {
        let recognizer = TouchDownRecognizer()
        recognizer.cancelsTouchesInView = false
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: TouchDownRecognizer, context: Context) {
        if recognizer.state == .began {
            motion.touchDown(at: screenPoint(context.converter.localLocation))
        }
        if recognizer.state != .ended, recognizer.numberOfTouches > 1 {
            motion.secondFingerLanded()
        }
    }
}

struct GlobeDrag: UIGestureRecognizerRepresentable {
    let motion: GlobeMotion
    let viewport: GlobeViewport
    let reduceMotion: Bool

    func makeCoordinator(converter: CoordinateSpaceConverter) -> SimultaneousGestures {
        SimultaneousGestures()
    }

    func makeUIGestureRecognizer(context: Context) -> TimedPanRecognizer {
        let recognizer = TimedPanRecognizer()
        recognizer.maximumNumberOfTouches = 2
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: TimedPanRecognizer, context: Context) {
        let midpoint = screenPoint(context.converter.localLocation)
        switch recognizer.state {
        case .began:
            motion.dragBegan(at: midpoint, fingers: recognizer.numberOfTouches,
                             stillTime: recognizer.stillTime, time: recognizer.eventTime, in: viewport)
        case .changed:
            motion.dragMoved(to: midpoint, fingers: recognizer.numberOfTouches,
                             time: recognizer.eventTime, in: viewport)
        case .ended:
            motion.dragEnded(time: recognizer.eventTime, reduceMotion: reduceMotion, in: viewport)
        default:
            break
        }
    }
}

struct GlobePinch: UIGestureRecognizerRepresentable {
    let motion: GlobeMotion
    let viewport: GlobeViewport

    func makeCoordinator(converter: CoordinateSpaceConverter) -> SimultaneousGestures {
        SimultaneousGestures()
    }

    func makeUIGestureRecognizer(context: Context) -> UIPinchGestureRecognizer {
        let recognizer = UIPinchGestureRecognizer()
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UIPinchGestureRecognizer, context: Context) {
        // With a finger lifted the midpoint jumps to the one left; there is nothing to zoom.
        guard recognizer.state == .began || recognizer.state == .changed, recognizer.numberOfTouches > 1 else { return }
        motion.pinched(by: recognizer.scale, about: screenPoint(context.converter.localLocation), in: viewport)
        // `scale` is a total; the camera wants the change since last time.
        recognizer.scale = 1
    }
}

struct GlobeDoubleTap: UIGestureRecognizerRepresentable {
    let motion: GlobeMotion
    let viewport: GlobeViewport
    let reduceMotion: Bool

    func makeCoordinator(converter: CoordinateSpaceConverter) -> SimultaneousGestures {
        SimultaneousGestures()
    }

    func makeUIGestureRecognizer(context: Context) -> UITapGestureRecognizer {
        let recognizer = UITapGestureRecognizer()
        recognizer.numberOfTapsRequired = 2
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UITapGestureRecognizer, context: Context) {
        motion.doubleTapped(at: screenPoint(context.converter.localLocation),
                            reduceMotion: reduceMotion, in: viewport)
    }
}

struct GlobeTwoFingerTap: UIGestureRecognizerRepresentable {
    let motion: GlobeMotion
    let viewport: GlobeViewport
    let reduceMotion: Bool

    func makeCoordinator(converter: CoordinateSpaceConverter) -> SimultaneousGestures {
        SimultaneousGestures()
    }

    func makeUIGestureRecognizer(context: Context) -> UITapGestureRecognizer {
        let recognizer = UITapGestureRecognizer()
        recognizer.numberOfTouchesRequired = 2
        recognizer.delegate = context.coordinator
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UITapGestureRecognizer, context: Context) {
        motion.twoFingerTapped(at: screenPoint(context.converter.localLocation),
                               reduceMotion: reduceMotion, in: viewport)
    }
}

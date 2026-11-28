import Foundation

extension GlobeCamera {
    /// A one-handed slide this long doubles or halves the zoom, in points. [tune]
    static let slidePointsPerDoubling = 100.0

    /// The zoom factor of a one-handed slide, `points` up the screen (down is negative).
    public static func slideZoomFactor(slidUp points: Double) -> Double {
        pow(2, points / slidePointsPerDoubling)
    }
}

/// The zoom after a double-tap or a two-finger tap (Systems Detail 16.1, item 6).
public struct GlobeZoomAnimation: Codable, Equatable, Sendable {
    /// [tune]
    public static let seconds = 0.3

    private let point: ScreenPoint
    private let startZoom: Double
    private let endZoom: Double
    private var elapsedSeconds = 0.0

    /// Zooms `camera` by `factor` about `point`, as far as the zoom limits let it.
    public init(factor: Double, about point: ScreenPoint, from camera: GlobeCamera) {
        self.point = point
        startZoom = camera.zoom
        var end = camera
        end.pinch(by: factor)
        endZoom = end.zoom
    }

    public var isFinished: Bool { elapsedSeconds >= Self.seconds }

    /// Moves the zoom on by the next `seconds`. Any length of step ends at the same zoom.
    public mutating func advance(_ camera: inout GlobeCamera, by seconds: Double, in viewport: GlobeViewport) {
        guard !isFinished else { return }
        elapsedSeconds = min(elapsedSeconds + seconds, Self.seconds)
        // Cubic ease-out, over the scale: each equal share of it multiplies the zoom alike.
        let left = 1 - elapsedSeconds / Self.seconds
        let zoom = startZoom * pow(endZoom / startZoom, 1 - left * left * left)
        camera.zoom(by: zoom / camera.zoom, about: point, in: viewport)
    }
}

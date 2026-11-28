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
    public init(factor: Double, about point: ScreenPoint, from camera: GlobeCamera) {}

    public var isFinished: Bool { false }

    public mutating func advance(_ camera: inout GlobeCamera, by seconds: Double, in viewport: GlobeViewport) {}
}

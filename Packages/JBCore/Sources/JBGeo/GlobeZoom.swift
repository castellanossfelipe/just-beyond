import Foundation

extension GlobeCamera {
    /// A one-handed slide this long doubles or halves the zoom, in points. [tune]
    static let slidePointsPerDoubling = 100.0

    /// The zoom factor of a one-handed slide, `points` up the screen (down is negative).
    public static func slideZoomFactor(slidUp points: Double) -> Double {
        pow(2, points / slidePointsPerDoubling)
    }
}

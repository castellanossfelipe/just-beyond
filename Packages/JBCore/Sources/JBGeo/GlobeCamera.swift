import Foundation

/// Where the globe is seen from: the place at the middle of the screen, and how close.
public struct GlobeCamera: Codable, Equatable, Sendable {
    public var centre: LatLon
    public var zoom: Double

    /// Floor on cos(latitude), so a drag near a pole can't spin the globe wildly. [tune]
    static let minParallelWidth = 0.2

    public init(centre: LatLon, zoom: Double = 1) {
        self.centre = centre
        self.zoom = zoom
    }

    /// Finger travel in screen points, x right and y down. `globeRadius` is the radius at zoom 1.
    public mutating func drag(dx: Double, dy: Double, globeRadius: Double) {
        let degreesPerPoint = 180 / .pi / (globeRadius * zoom)
        let widthOfParallel = max(cos(centre.latDeg * .pi / 180), Self.minParallelWidth)
        let lonDeg = centre.lonDeg - dx * degreesPerPoint / widthOfParallel
        centre.lonDeg = lonDeg - 360 * ((lonDeg + 180) / 360).rounded(.down)
        centre.latDeg = min(max(centre.latDeg + dy * degreesPerPoint, -90), 90)
    }

    /// `factor` is how much the finger spread changed since the last call.
    public mutating func pinch(by factor: Double) {}
}

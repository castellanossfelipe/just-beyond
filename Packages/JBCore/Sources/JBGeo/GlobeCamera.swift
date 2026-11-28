/// Where the globe is seen from: the place at the middle of the screen, and how close.
public struct GlobeCamera: Codable, Equatable, Sendable {
    public var centre: LatLon
    public var zoom: Double

    public init(centre: LatLon, zoom: Double = 1) {
        self.centre = centre
        self.zoom = zoom
    }

    /// Finger travel in screen points, x right and y down. `globeRadius` is the radius at zoom 1.
    public mutating func drag(dx: Double, dy: Double, globeRadius: Double) {
        let degreesPerPoint = 180 / .pi / globeRadius
        centre.lonDeg += dx * degreesPerPoint
        centre.latDeg += dy * degreesPerPoint
    }
}

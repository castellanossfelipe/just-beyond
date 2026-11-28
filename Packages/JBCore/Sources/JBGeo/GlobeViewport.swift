/// A place on the screen, in points: x right, y down.
public struct ScreenPoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// The view the globe is drawn in, in points. The globe sits in the middle of it.
public struct GlobeViewport: Codable, Equatable, Sendable {
    public var width: Double
    public var height: Double
    /// The globe's radius at zoom 1.
    public var globeRadius: Double

    public init(width: Double, height: Double, globeRadius: Double) {
        self.width = width
        self.height = height
        self.globeRadius = globeRadius
    }
}

extension GlobeCamera {
    /// The place seen at a screen point, or nil off the globe.
    public func place(at point: ScreenPoint, in viewport: GlobeViewport) -> LatLon? {
        let radius = viewport.globeRadius * zoom
        let x = (point.x - viewport.width / 2) / radius
        let y = (viewport.height / 2 - point.y) / radius
        guard x * x + y * y <= 1 else { return nil }
        let depth = (1 - x * x - y * y).squareRoot()
        return LatLon(centre.eastVector * x + centre.northVector * y + centre.unitVector * depth)
    }

    /// Where a place is on the screen, or nil on the far side.
    public func screenPoint(of place: LatLon, in viewport: GlobeViewport) -> ScreenPoint? {
        let radius = viewport.globeRadius * zoom
        let projected = OrthographicProjection(centre: centre).project(place)
        guard projected.depth >= 0 else { return nil }
        return ScreenPoint(x: viewport.width / 2 + projected.x * radius,
                           y: viewport.height / 2 - projected.y * radius)
    }
}

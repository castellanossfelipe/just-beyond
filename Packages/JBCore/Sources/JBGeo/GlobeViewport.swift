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
        nil
    }

    /// Where a place is on the screen, or nil on the far side.
    public func screenPoint(of place: LatLon, in viewport: GlobeViewport) -> ScreenPoint? {
        nil
    }
}

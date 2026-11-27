/// A point in the unit disc: x right, y up. Depth is positive on the near side.
public struct ProjectedPoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var depth: Double

    public init(x: Double, y: Double, depth: Double) {
        self.x = x
        self.y = y
        self.depth = depth
    }
}

/// The globe seen from far away, looking straight down at `centre`, north up.
public struct OrthographicProjection: Codable, Equatable, Sendable {
    public var centre: LatLon

    public init(centre: LatLon) {
        self.centre = centre
    }

    public func project(_ point: LatLon) -> ProjectedPoint {
        ProjectedPoint(x: 0, y: 0, depth: 0)
    }
}

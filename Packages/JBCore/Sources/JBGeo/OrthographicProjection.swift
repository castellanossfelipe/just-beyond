import Foundation

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
        let v = point.unitVector
        let lat = centre.latDeg * .pi / 180
        let lon = centre.lonDeg * .pi / 180
        // The view's three axes, in globe coordinates.
        let right = Vector3(x: -sin(lon), y: cos(lon), z: 0)
        let up = Vector3(x: -sin(lat) * cos(lon), y: -sin(lat) * sin(lon), z: cos(lat))
        let toViewer = centre.unitVector
        return ProjectedPoint(x: v.dot(right), y: v.dot(up), depth: v.dot(toViewer))
    }
}

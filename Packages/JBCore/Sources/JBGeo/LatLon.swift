/// A position on the globe, in degrees. North and east are positive.
public struct LatLon: Codable, Equatable, Sendable {
    public var latDeg: Double
    public var lonDeg: Double

    public init(latDeg: Double, lonDeg: Double) {
        self.latDeg = latDeg
        self.lonDeg = lonDeg
    }

    public var unitVector: Vector3 {
        Vector3(x: 1, y: 0, z: 0)
    }
}

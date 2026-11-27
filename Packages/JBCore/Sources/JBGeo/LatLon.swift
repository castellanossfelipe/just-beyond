import Foundation

/// A position on the globe, in degrees. North and east are positive.
public struct LatLon: Codable, Equatable, Sendable {
    public var latDeg: Double
    public var lonDeg: Double

    public init(latDeg: Double, lonDeg: Double) {
        self.latDeg = latDeg
        self.lonDeg = lonDeg
    }

    public init(_ vector: Vector3) {
        self.init(
            latDeg: atan2(vector.z, hypot(vector.x, vector.y)) * 180 / .pi,
            lonDeg: atan2(vector.y, vector.x) * 180 / .pi)
    }

    public var unitVector: Vector3 {
        let lon = lonDeg * .pi / 180
        let lat = latDeg * .pi / 180
        return Vector3(x: cos(lat) * cos(lon), y: cos(lat) * sin(lon), z: sin(lat))
    }
}

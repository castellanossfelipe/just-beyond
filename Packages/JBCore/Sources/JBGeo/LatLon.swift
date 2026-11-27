import Foundation

/// A position on the globe, in degrees. North and east are positive.
public struct LatLon: Codable, Equatable, Sendable {
    public var latDeg: Double
    public var lonDeg: Double

    public init(latDeg: Double, lonDeg: Double) {
        self.latDeg = latDeg
        self.lonDeg = lonDeg
    }

    public var unitVector: Vector3 {
        let lon = lonDeg * .pi / 180
        return Vector3(x: cos(lon), y: sin(lon), z: 0)
    }
}

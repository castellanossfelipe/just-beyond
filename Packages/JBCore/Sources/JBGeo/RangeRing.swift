import Foundation

/// The places a given distance from a centre.
public enum RangeRing {
    /// Bearing between two points of a ring. [tune]
    static let bearingStepDeg = 2.0

    /// Points clockwise from due north of `centre`.
    public static func points(around centre: LatLon, radiusKm: Double) -> [Vector3] {
        let lat = centre.latDeg * .pi / 180
        let lon = centre.lonDeg * .pi / 180
        let north = Vector3(x: -sin(lat) * cos(lon), y: -sin(lat) * sin(lon), z: cos(lat))
        let east = Vector3(x: -sin(lon), y: cos(lon), z: 0)
        let middle = centre.unitVector
        let angle = radiusKm / Earth.radiusKm
        return stride(from: 0.0, through: 360, by: bearingStepDeg).map { bearingDeg in
            let bearing = bearingDeg * .pi / 180
            let heading = north * cos(bearing) + east * sin(bearing)
            return middle * cos(angle) + heading * sin(angle)
        }
    }
}

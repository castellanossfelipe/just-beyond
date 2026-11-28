import Foundation

/// The places a given distance from a centre.
public enum RangeRing {
    /// Bearing between two points of a ring. [tune]
    static let bearingStepDeg = 2.0

    /// Points clockwise from due north of `centre`.
    public static func points(around centre: LatLon, radiusKm: Double) -> [Vector3] {
        if radiusKm == 0 { return [centre.unitVector] }
        let lat = centre.latDeg * .pi / 180
        let lon = centre.lonDeg * .pi / 180
        let north = Vector3(x: -sin(lat) * cos(lon), y: -sin(lat) * sin(lon), z: cos(lat))
        let east = Vector3(x: -sin(lon), y: cos(lon), z: 0)
        let middle = centre.unitVector
        let angle = radiusKm / Earth.radiusKm
        let points = stride(from: 0.0, to: 360, by: bearingStepDeg).map { bearingDeg in
            let bearing = bearingDeg * .pi / 180
            let heading = north * cos(bearing) + east * sin(bearing)
            return middle * cos(angle) + heading * sin(angle)
        }
        // Repeat the first point, not bearing 360, so the ends match exactly.
        return points + points.prefix(1)
    }
}

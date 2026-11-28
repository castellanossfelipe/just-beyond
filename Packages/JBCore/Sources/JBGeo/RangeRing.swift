import Foundation

/// The places a given distance from a centre.
public enum RangeRing {
    public static func points(around centre: LatLon, radiusKm: Double) -> [Vector3] {
        let lat = centre.latDeg * .pi / 180
        let lon = centre.lonDeg * .pi / 180
        let north = Vector3(x: -sin(lat) * cos(lon), y: -sin(lat) * sin(lon), z: cos(lat))
        let angle = radiusKm / Earth.radiusKm
        return [centre.unitVector * cos(angle) + north * sin(angle)]
    }
}

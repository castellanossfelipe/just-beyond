/// The shortest path over the sphere between two places.
public enum GreatCircle {
    public static func arc(from start: LatLon, to end: LatLon) -> [Vector3] {
        let a = start.unitVector
        let b = end.unitVector
        return [a, (a + b).normalized, b]
    }
}

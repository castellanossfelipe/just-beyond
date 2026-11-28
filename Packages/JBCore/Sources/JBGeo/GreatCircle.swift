/// The shortest path over the sphere between two places.
public enum GreatCircle {
    public static func arc(from start: LatLon, to end: LatLon) -> [Vector3] {
        [start.unitVector, end.unitVector]
    }
}

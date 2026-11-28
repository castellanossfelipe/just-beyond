import Foundation

/// The shortest path over the sphere between two places.
public enum GreatCircle {
    /// Longest step between two points of an arc. [tune]
    static let maxStepDeg = 1.0

    /// Evenly spaced points from `start` to `end`, both included.
    public static func arc(from start: LatLon, to end: LatLon) -> [Vector3] {
        let a = start.unitVector
        let b = end.unitVector
        let total = atan2(a.cross(b).length, a.dot(b))
        if total == 0 { return [a] }
        let count = Int((total / (maxStepDeg * .pi / 180)).rounded(.up))
        // `towards` is the direction at `a`, a quarter turn along the path to `b`.
        let towards = (b - a * a.dot(b)).normalized
        let middle = (1..<count).map { i in
            let turned = total * Double(i) / Double(count)
            return a * cos(turned) + towards * sin(turned)
        }
        return [a] + middle + [b]
    }
}

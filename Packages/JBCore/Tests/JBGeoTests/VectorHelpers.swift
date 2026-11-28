import Foundation
import JBGeo

func length(_ v: Vector3) -> Double {
    (v.x * v.x + v.y * v.y + v.z * v.z).squareRoot()
}

/// The angle between two points on the unit sphere, in radians.
func angle(_ a: Vector3, _ b: Vector3) -> Double {
    let cross = Vector3(x: a.y * b.z - a.z * b.y, y: a.z * b.x - a.x * b.z, z: a.x * b.y - a.y * b.x)
    return atan2(length(cross), a.x * b.x + a.y * b.y + a.z * b.z)
}

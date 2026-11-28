/// x is 0°N 0°E, y is 0°N 90°E, z is the north pole.
public struct Vector3: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double
    public var z: Double

    public init(x: Double, y: Double, z: Double) {
        self.x = x
        self.y = y
        self.z = z
    }

    func dot(_ other: Vector3) -> Double {
        x * other.x + y * other.y + z * other.z
    }

    func cross(_ o: Vector3) -> Vector3 {
        Vector3(x: y * o.z - z * o.y, y: z * o.x - x * o.z, z: x * o.y - y * o.x)
    }

    var length: Double {
        dot(self).squareRoot()
    }

    var normalized: Vector3 {
        self * (1 / length)
    }

    static func + (a: Vector3, b: Vector3) -> Vector3 {
        Vector3(x: a.x + b.x, y: a.y + b.y, z: a.z + b.z)
    }

    static func - (a: Vector3, b: Vector3) -> Vector3 {
        Vector3(x: a.x - b.x, y: a.y - b.y, z: a.z - b.z)
    }

    static func * (a: Vector3, k: Double) -> Vector3 {
        Vector3(x: a.x * k, y: a.y * k, z: a.z * k)
    }
}

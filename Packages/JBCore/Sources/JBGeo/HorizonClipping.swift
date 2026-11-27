import Foundation

extension OrthographicProjection {
    /// The parts of a polyline on the near side, projected.
    public func visiblePieces(of line: [Vector3]) -> [[ProjectedPoint]] {
        var piece: [ProjectedPoint] = []
        var previous: (vector: Vector3, point: ProjectedPoint)?
        for vector in line {
            let point = project(vector)
            if point.depth >= 0 {
                piece.append(point)
            } else {
                if let previous, previous.point.depth >= 0 {
                    piece.append(limbCrossing(previous.vector, previous.point.depth, vector, point.depth))
                }
                break
            }
            previous = (vector, point)
        }
        return piece.isEmpty ? [] : [piece]
    }

    /// Where the segment from `a` to `b` meets the horizon. Their depths have opposite signs.
    private func limbCrossing(_ a: Vector3, _ depthA: Double, _ b: Vector3, _ depthB: Double) -> ProjectedPoint {
        // Depth is linear along the chord; pushing the chord point out to the sphere keeps depth zero.
        let t = depthA / (depthA - depthB)
        let x = a.x + (b.x - a.x) * t
        let y = a.y + (b.y - a.y) * t
        let z = a.z + (b.z - a.z) * t
        let length = (x * x + y * y + z * z).squareRoot()
        return project(Vector3(x: x / length, y: y / length, z: z / length))
    }
}

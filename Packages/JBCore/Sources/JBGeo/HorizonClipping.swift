extension OrthographicProjection {
    /// The parts of a polyline on the near side, projected. A piece that is cut ends on the limb.
    public func visiblePieces(of line: [Vector3]) -> [[ProjectedPoint]] {
        guard line.count >= 2 else { return [] }

        var pieces: [[ProjectedPoint]] = []
        var piece: [ProjectedPoint] = []
        var previous: (vector: Vector3, point: ProjectedPoint)?

        for vector in line {
            let point = project(vector)
            let isVisible = point.depth >= 0
            if let previous, isVisible != (previous.point.depth >= 0) {
                piece.append(limbCrossing(previous.vector, previous.point.depth, vector, point.depth))
            }
            if isVisible {
                piece.append(point)
            } else if !piece.isEmpty {
                pieces.append(piece)
                piece = []
            }
            previous = (vector, point)
        }
        if !piece.isEmpty { pieces.append(piece) }
        return pieces
    }

    /// Where the segment from `a` to `b` meets the horizon. One end is near side, the other far.
    private func limbCrossing(_ a: Vector3, _ depthA: Double, _ b: Vector3, _ depthB: Double) -> ProjectedPoint {
        // Depth is linear along the chord, and pushing the point out to the sphere keeps it zero.
        let t = depthA / (depthA - depthB)
        return project((a + (b - a) * t).normalized)
    }
}

extension OrthographicProjection {
    /// The parts of a polyline on the near side, projected.
    public func visiblePieces(of line: [Vector3]) -> [[ProjectedPoint]] {
        let points = line.map { project($0) }
        guard points.allSatisfy({ $0.depth >= 0 }) else { return [] }
        return [points]
    }
}

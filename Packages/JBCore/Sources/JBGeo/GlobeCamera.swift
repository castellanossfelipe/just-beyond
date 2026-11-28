import Foundation

/// Where the globe is seen from: the place at the middle of the screen, and how close.
public struct GlobeCamera: Codable, Equatable, Sendable {
    public var centre: LatLon
    public var zoom: Double

    /// [tune]
    public static let zoomRange = 1.0...8.0

    /// Floor on cos(latitude), so a drag near a pole can't spin the globe wildly. [tune]
    static let minParallelWidth = 0.2

    public init(centre: LatLon, zoom: Double = 1) {
        self.centre = centre
        self.zoom = zoom
    }

    /// Finger travel in screen points, x right and y down. `globeRadius` is the radius at zoom 1.
    public mutating func drag(dx: Double, dy: Double, globeRadius: Double) {
        let degreesPerPoint = 180 / .pi / (globeRadius * zoom)
        let widthOfParallel = max(cos(centre.latDeg * .pi / 180), Self.minParallelWidth)
        let lonDeg = centre.lonDeg - dx * degreesPerPoint / widthOfParallel
        centre.lonDeg = lonDeg - 360 * ((lonDeg + 180) / 360).rounded(.down)
        centre.latDeg = min(max(centre.latDeg + dy * degreesPerPoint, -90), 90)
    }

    /// The camera turns no faster than one over this, in radians per globe radius of finger travel.
    /// σc in Systems Detail 16.1. [tune]
    static let dampingFloor = 0.25

    /// The longest finger travel solved in one go, in points. [tune]
    static let longestGrabStep = 2.0

    /// Turns the globe so the place under `from` goes to `to` (Systems Detail 16.1, item 1).
    public mutating func grab(from: ScreenPoint, to: ScreenPoint, in viewport: GlobeViewport) {
        let length = hypot(to.x - from.x, to.y - from.y)
        // The margin stops rounding noise splitting a step that is exactly the longest.
        let steps = max(1, Int((length / Self.longestGrabStep - 1e-9).rounded(.up)))
        var previous = from
        for step in 1...steps {
            let t = Double(step) / Double(steps)
            let next = ScreenPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t)
            grabStep(from: previous, to: next, in: viewport)
            previous = next
        }
    }

    private mutating func grabStep(from: ScreenPoint, to: ScreenPoint, in viewport: GlobeViewport) {
        let radius = viewport.globeRadius * zoom
        let from = viewport.clampedToRim(from, radius: radius)
        let to = viewport.clampedToRim(to, radius: radius)
        guard let place = place(at: from, in: viewport) else { return }
        // In unit-disc coordinates the screen's y points up.
        let target = (x: (to.x - viewport.width / 2) / radius, y: (viewport.height / 2 - to.y) / radius)
        let before = centre
        // One solve is only linear, and the misses add up over a drag. Where it was undamped, a
        // second solve toward the same point removes what is left.
        if !step(place, toward: target) {
            step(place, toward: target)
            limitTurn(since: before, to: hypot(to.x - from.x, to.y - from.y) / radius / Self.dampingFloor)
        }
    }

    /// Shortens the turn made since `before` to at most `limit` radians, keeping its direction.
    private mutating func limitTurn(since before: LatLon, to limit: Double) {
        let latTurn = centre.latDeg - before.latDeg
        let lonTurn = remainder(centre.lonDeg - before.lonDeg, 360)
        let turn = hypot(latTurn, lonTurn) * .pi / 180
        guard turn > limit else { return }
        centre = before
        move(latDeg: latTurn * limit / turn, lonDeg: lonTurn * limit / turn)
    }

    /// Latitude stops at the poles; longitude wraps.
    private mutating func move(latDeg: Double, lonDeg: Double) {
        centre.latDeg = min(max(centre.latDeg + latDeg, -90), 90)
        let lon = centre.lonDeg + lonDeg
        centre.lonDeg = lon - 360 * ((lon + 180) / 360).rounded(.down)
    }

    /// One damped least-squares step that moves `place` toward `target` on the unit disc. Returns
    /// whether it had to be damped.
    @discardableResult
    private mutating func step(_ place: LatLon, toward target: (x: Double, y: Double)) -> Bool {
        let lat = place.latDeg * .pi / 180
        let centreLat = centre.latDeg * .pi / 180
        let lonOffset = (place.lonDeg - centre.lonDeg) * .pi / 180
        let now = OrthographicProjection(centre: centre).project(place)
        let depth = now.depth
        let fingerStep = (x: target.x - now.x, y: target.y - now.y)

        // J = ∂(x, y)/∂(centre latitude, centre longitude) = [[0, b], [c, d]].
        let b = -cos(lat) * cos(lonOffset)
        let c = -depth
        let d = -cos(lat) * sin(centreLat) * sin(lonOffset)

        // JᵀJ = [[m11, m12], [m12, m22]], damped only where its smallest eigenvalue is below σc².
        var m11 = c * c
        let m12 = c * d
        var m22 = b * b + d * d
        let smallest = (m11 + m22) / 2 - hypot((m11 - m22) / 2, m12)
        let damping = max(0, Self.dampingFloor * Self.dampingFloor - smallest)
        m11 += damping
        m22 += damping

        // (JᵀJ + μ²I)⁻¹ Jᵀ fingerStep
        let g1 = c * fingerStep.y
        let g2 = b * fingerStep.x + d * fingerStep.y
        let determinant = m11 * m22 - m12 * m12
        let latStep = (m22 * g1 - m12 * g2) / determinant
        let lonStep = (m11 * g2 - m12 * g1) / determinant

        move(latDeg: latStep * 180 / .pi, lonDeg: lonStep * 180 / .pi)
        return damping > 0
    }

    /// Zooms by `factor`, keeping the place under `point` where it is.
    public mutating func zoom(by factor: Double, about point: ScreenPoint, in viewport: GlobeViewport) {
    }

    /// `factor` is how much the finger spread changed since the last call.
    public mutating func pinch(by factor: Double) {
        zoom = min(max(zoom * factor, Self.zoomRange.lowerBound), Self.zoomRange.upperBound)
    }
}

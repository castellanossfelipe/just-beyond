/// Where the camera was at one touch update, at the touch's own time.
public struct CameraSample: Codable, Equatable, Sendable {
    public var timeSeconds: Double
    public var centre: LatLon

    public init(timeSeconds: Double, centre: LatLon) {
        self.timeSeconds = timeSeconds
        self.centre = centre
    }
}

/// The globe turning on after the finger lifts (Systems Detail 16.1, item 5).
public struct GlobeCoast: Codable, Equatable, Sendable {
    /// How fast the camera centre is turning.
    public private(set) var latDegPerSecond: Double
    public private(set) var lonDegPerSecond: Double

    /// How far back from the lift the turning is measured. [tune]
    static let windowSeconds = 0.08

    /// `samples` are in time order; the last one is the lift. Nil if the globe does not coast.
    public init?(samples: [CameraSample], zoom: Double, viewport: GlobeViewport) {
        guard let lift = samples.last,
              let reference = samples.last(where: { $0.timeSeconds <= lift.timeSeconds - Self.windowSeconds })
        else { return nil }
        let seconds = lift.timeSeconds - reference.timeSeconds
        latDegPerSecond = (lift.centre.latDeg - reference.centre.latDeg) / seconds
        lonDegPerSecond = (lift.centre.lonDeg - reference.centre.lonDeg) / seconds
    }

    /// Turns the camera on by the next `seconds` of the coast.
    public mutating func advance(_ camera: inout GlobeCamera, by seconds: Double) {}
}

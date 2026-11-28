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

    /// `samples` are in time order; the last one is the lift. Nil if the globe does not coast.
    public init?(samples: [CameraSample], zoom: Double, viewport: GlobeViewport) {
        return nil
    }
}

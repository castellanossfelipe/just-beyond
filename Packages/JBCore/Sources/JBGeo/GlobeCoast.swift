import Foundation

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
    /// How far back from the lift the turning is measured. [tune]
    static let windowSeconds = 0.08

    /// The share of its speed the coast keeps each millisecond, as an iOS scroll view does.
    static let keptPerMillisecond = 0.998

    /// The coast ends when the screen middle moves slower than this, in points a second. [tune]
    static let slowestSpeed = 10.0

    /// No coast from a release slower than this, in points a second. [tune]
    static let slowestRelease = 100.0

    /// A faster release coasts as if it were this fast, in points a second. [tune]
    static let fastestRelease = 4_000.0

    /// How fast the speed falls: speed = start × e^(−decay × seconds).
    private static var decayPerSecond: Double { -1000 * log(keptPerMillisecond) }

    private let startLatDegPerSecond: Double
    private let startLonDegPerSecond: Double
    /// Fixed at the lift, so frames of any length end the coast at the same place.
    private let endSeconds: Double
    private var elapsedSeconds = 0.0

    /// `samples` are in time order; the last one is the lift. Nil if the globe does not coast.
    public init?(samples: [CameraSample], zoom: Double, viewport: GlobeViewport) {
        guard let lift = samples.last,
              let reference = samples.last(where: { $0.timeSeconds <= lift.timeSeconds - Self.windowSeconds })
        else { return nil }
        let seconds = lift.timeSeconds - reference.timeSeconds
        let latRate = (lift.centre.latDeg - reference.centre.latDeg) / seconds
        let lonRate = (lift.centre.lonDeg - reference.centre.lonDeg) / seconds

        // How fast the screen middle moves, in points a second.
        let alongParallel = cos(lift.centre.latDeg * .pi / 180) * lonRate
        let speed = viewport.globeRadius * zoom * hypot(latRate, alongParallel) * .pi / 180
        guard speed >= Self.slowestRelease else { return nil }

        let capped = min(speed, Self.fastestRelease)
        startLatDegPerSecond = latRate * capped / speed
        startLonDegPerSecond = lonRate * capped / speed
        endSeconds = log(capped / Self.slowestSpeed) / Self.decayPerSecond
    }

    /// How fast the camera centre is turning now.
    public var latDegPerSecond: Double { startLatDegPerSecond * speedLeft }
    public var lonDegPerSecond: Double { startLonDegPerSecond * speedLeft }

    public var isFinished: Bool { elapsedSeconds >= endSeconds }

    private var speedLeft: Double { exp(-Self.decayPerSecond * elapsedSeconds) }

    /// Turns the camera on by the next `seconds` of the coast.
    public mutating func advance(_ camera: inout GlobeCamera, by seconds: Double) {
        let before = speedLeft
        elapsedSeconds = min(elapsedSeconds + seconds, endSeconds)
        // The turn made is the speed lost over the rate of losing it, so one long step equals many.
        let turned = (before - speedLeft) / Self.decayPerSecond
        camera.move(latDeg: startLatDegPerSecond * turned, lonDeg: startLonDegPerSecond * turned)
    }
}

import JBGeo
import SwiftUI

/// What to draw, in globe coordinates. No drawing types, so another renderer can take it.
struct GlobeScene: Equatable, Sendable {
    struct Arc: Equatable, Sendable {
        var from: LatLon
        var to: LatLon
    }

    struct Ring: Equatable, Sendable {
        var centre: LatLon
        var radiusKm: Double
    }

    var coastlines: [[LatLon]]
    var arcs: [Arc] = []
    var rings: [Ring] = []
}

/// Draws a scene as seen by `camera`. Canvas first; Metal is gate G0's fallback.
protocol GlobeRenderer {
    associatedtype Body: View

    /// The globe's radius in points at zoom 1, in a view of this size. Drags are measured against it.
    func globeRadius(in size: CGSize) -> Double

    func view(of scene: GlobeScene, camera: GlobeCamera, recorder: FrameRecorder) -> Body
}

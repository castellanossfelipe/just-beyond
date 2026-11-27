import JBGeo
import SwiftUI

/// What to draw, in globe coordinates. No drawing types, so another renderer can take it.
struct GlobeScene: Equatable, Sendable {
    var coastlines: [[LatLon]]
}

/// Draws a scene as seen from above `centre`. Canvas first; Metal is gate G0's fallback.
protocol GlobeRenderer {
    associatedtype Body: View

    func view(of scene: GlobeScene, centre: LatLon) -> Body
}

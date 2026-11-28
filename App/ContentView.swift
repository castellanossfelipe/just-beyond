import JBGeo
import SwiftUI

struct ContentView: View {
    @State private var scene = ContentView.spikeScene()

    var body: some View {
        GlobeView(scene: scene, camera: GlobeCamera(centre: LatLon(latDeg: 40, lonDeg: -40)))
    }

    /// Scene B of the frame-time protocol (issue #3).
    private static func spikeScene() -> GlobeScene {
        let newYork = LatLon(latDeg: 40.71, lonDeg: -74.01)
        let london = LatLon(latDeg: 51.51, lonDeg: -0.13)
        return GlobeScene(
            coastlines: Coastlines.load(),
            arcs: [.init(from: newYork, to: london)],
            // A placeholder radius, not a game number.
            rings: [.init(centre: newYork, radiusKm: 2_500)])
    }
}

#Preview {
    ContentView()
}

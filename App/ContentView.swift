import JBGeo
import SwiftUI

struct ContentView: View {
    @State private var scene = GlobeScene(coastlines: Coastlines.load())
    private let renderer = CanvasGlobeRenderer()

    var body: some View {
        // A fixed view over the North Atlantic until the camera arrives (S0.2b).
        renderer.view(of: scene, centre: LatLon(latDeg: 30, lonDeg: -40))
            .background(.white)
            .ignoresSafeArea()
            .accessibilityLabel("Globe")
    }
}

#Preview {
    ContentView()
}

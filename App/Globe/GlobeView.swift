import JBGeo
import SwiftUI

/// The turning globe: the place under your finger stays under it, it coasts when you let go, and taps zoom.
struct GlobeView: View {
    let scene: GlobeScene
    @State private var motion: GlobeMotion
    @State private var recorder = FrameRecorder()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let renderer = CanvasGlobeRenderer()

    init(scene: GlobeScene, camera: GlobeCamera) {
        self.scene = scene
        _motion = State(initialValue: GlobeMotion(camera: camera))
    }

    var body: some View {
        GeometryReader { geometry in
            let viewport = viewport(of: geometry.size)
            // Frames run only while the globe moves by itself.
            TimelineView(.animation(paused: !motion.isMoving)) { timeline in
                renderer.view(of: scene, camera: motion.camera, recorder: recorder)
                    .onChange(of: timeline.date) { _, date in motion.frame(at: date, in: viewport) }
            }
            .contentShape(.rect)
            .gesture(GlobeTouchDown(motion: motion))
            .gesture(GlobeDrag(motion: motion, viewport: viewport, reduceMotion: reduceMotion))
            .gesture(GlobePinch(motion: motion, viewport: viewport))
            .gesture(GlobeDoubleTap(motion: motion, viewport: viewport, reduceMotion: reduceMotion))
            .gesture(GlobeTwoFingerTap(motion: motion, viewport: viewport, reduceMotion: reduceMotion))
        }
        .background(.white)
        .ignoresSafeArea()
        .accessibilityLabel("Globe")
        .overlay(alignment: .bottom) {
            FrameHUD(recorder: recorder)
                .padding(.bottom, 24)
        }
    }

    private func viewport(of size: CGSize) -> GlobeViewport {
        GlobeViewport(width: size.width, height: size.height, globeRadius: renderer.globeRadius(in: size))
    }
}

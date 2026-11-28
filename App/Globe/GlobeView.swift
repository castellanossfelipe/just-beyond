import JBGeo
import SwiftUI

/// The turning globe: drag to rotate, pinch to zoom.
struct GlobeView: View {
    let scene: GlobeScene
    @State private var camera: GlobeCamera
    @State private var recorder = FrameRecorder()
    // Gestures report totals since they began; the camera wants the change since last time.
    @State private var lastDrag: (start: CGPoint, translation: CGSize)?
    @State private var lastPinch: (start: CGPoint, magnification: CGFloat)?
    private let renderer = CanvasGlobeRenderer()

    init(scene: GlobeScene, camera: GlobeCamera) {
        self.scene = scene
        _camera = State(initialValue: camera)
    }

    var body: some View {
        GeometryReader { geometry in
            renderer.view(of: scene, camera: camera, recorder: recorder)
                .contentShape(.rect)
                .gesture(drag(globeRadius: renderer.globeRadius(in: geometry.size))
                    .simultaneously(with: pinch))
        }
        .background(.white)
        .ignoresSafeArea()
        .accessibilityLabel("Globe")
        .overlay(alignment: .bottom) {
            FrameHUD(recorder: recorder)
                .padding(.bottom, 24)
        }
    }

    private func drag(globeRadius: Double) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let before = lastDrag?.start == value.startLocation ? lastDrag?.translation ?? .zero : .zero
                camera.drag(dx: value.translation.width - before.width,
                            dy: value.translation.height - before.height,
                            globeRadius: globeRadius)
                lastDrag = (value.startLocation, value.translation)
            }
            .onEnded { _ in lastDrag = nil }
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let before = lastPinch?.start == value.startLocation ? lastPinch?.magnification ?? 1 : 1
                camera.pinch(by: value.magnification / before)
                lastPinch = (value.startLocation, value.magnification)
            }
            .onEnded { _ in lastPinch = nil }
    }
}

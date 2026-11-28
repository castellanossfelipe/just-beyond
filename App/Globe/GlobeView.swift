import JBGeo
import SwiftUI

/// The turning globe: drag to rotate, pinch to zoom.
struct GlobeView: View {
    let scene: GlobeScene
    @State private var camera: GlobeCamera
    @State private var recorder = FrameRecorder()
    // Gestures report totals or the latest position; the camera wants the change since last time.
    @State private var lastDrag: (start: CGPoint, location: CGPoint)?
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
                .gesture(drag(in: viewport(of: geometry.size))
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

    private func viewport(of size: CGSize) -> GlobeViewport {
        GlobeViewport(width: size.width, height: size.height, globeRadius: renderer.globeRadius(in: size))
    }

    private func drag(in viewport: GlobeViewport) -> some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { value in
                let before = lastDrag?.start == value.startLocation ? lastDrag?.location : nil
                camera.grab(from: screenPoint(before ?? value.startLocation),
                            to: screenPoint(value.location), in: viewport)
                lastDrag = (value.startLocation, value.location)
            }
            .onEnded { _ in lastDrag = nil }
    }

    private func screenPoint(_ point: CGPoint) -> ScreenPoint {
        ScreenPoint(x: point.x, y: point.y)
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

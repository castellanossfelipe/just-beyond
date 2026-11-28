import JBGeo
import SwiftUI

/// The globe as a flat disc drawn with SwiftUI `Canvas`.
struct CanvasGlobeRenderer: GlobeRenderer {
    func globeRadius(in size: CGSize) -> Double {
        max(1, min(size.width, size.height) / 2 - 8)
    }

    func view(of scene: GlobeScene, camera: GlobeCamera, recorder: FrameRecorder) -> some View {
        Canvas { context, size in
            // Everything done per frame is inside the timing, so the HUD sees all of it.
            recorder.time {
                draw(scene, camera: camera, in: &context, size: size)
            }
        }
    }

    private func draw(_ scene: GlobeScene, camera: GlobeCamera, in context: inout GraphicsContext, size: CGSize) {
        let projection = OrthographicProjection(centre: camera.centre)
        let radius = globeRadius(in: size) * camera.zoom
        let middle = CGPoint(x: size.width / 2, y: size.height / 2)

        /// The near-side parts of some lines, as one screen path.
        func path(_ lines: [[Vector3]]) -> Path {
            var path = Path()
            for line in lines {
                for piece in projection.visiblePieces(of: line) {
                    // The projection has y up; the screen has y down.
                    path.addLines(piece.map {
                        CGPoint(x: middle.x + $0.x * radius, y: middle.y - $0.y * radius)
                    })
                }
            }
            return path
        }

        let disc = CGRect(x: middle.x - radius, y: middle.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: disc), with: .color(Color(white: 0.92)))
        context.stroke(path(scene.coastlines.map { $0.map(\.unitVector) }),
                       with: .color(Color(white: 0.25)), lineWidth: 1)
        context.stroke(path(scene.rings.map { RangeRing.points(around: $0.centre, radiusKm: $0.radiusKm) }),
                       with: .color(.blue), lineWidth: 1.5)
        context.stroke(path(scene.arcs.map { GreatCircle.arc(from: $0.from, to: $0.to) }),
                       with: .color(.red), lineWidth: 2)
    }
}

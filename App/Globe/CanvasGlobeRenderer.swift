import JBGeo
import SwiftUI

/// The globe as a flat disc drawn with SwiftUI `Canvas`.
struct CanvasGlobeRenderer: GlobeRenderer {
    func view(of scene: GlobeScene, centre: LatLon) -> some View {
        let projection = OrthographicProjection(centre: centre)
        let lines = scene.coastlines.map { line in line.map(\.unitVector) }

        return Canvas { context, size in
            let radius = max(0, min(size.width, size.height) / 2 - 8)
            let middle = CGPoint(x: size.width / 2, y: size.height / 2)
            let disc = CGRect(x: middle.x - radius, y: middle.y - radius,
                              width: radius * 2, height: radius * 2)
            context.fill(Path(ellipseIn: disc), with: .color(Color(white: 0.92)))

            var coast = Path()
            for line in lines {
                for piece in projection.visiblePieces(of: line) {
                    // The projection has y up; the screen has y down.
                    coast.addLines(piece.map {
                        CGPoint(x: middle.x + $0.x * radius, y: middle.y - $0.y * radius)
                    })
                }
            }
            context.stroke(coast, with: .color(Color(white: 0.25)), lineWidth: 1)
        }
    }
}

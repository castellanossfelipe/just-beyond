import Foundation
import Testing
import JBGeo

/// An iPhone 13 in portrait.
private let viewport = GlobeViewport(width: 390, height: 844, globeRadius: 187)

/// Zoom at the tap, the factor asked for and the zoom it ends at: in, out, and into the limit.
@Test(arguments: [(1.0, 2.0, 2.0), (4, 0.5, 2), (6, 2, 10)])
func doubleTapZoomEasesOutToTwice(start: Double, factor: Double, end: Double) throws {
    var view = GlobeCamera(centre: LatLon(latDeg: 30, lonDeg: -40), zoom: start)
    let tap = ScreenPoint(x: 195 + 90, y: 422 - 40)
    let tapped = try #require(view.place(at: tap, in: viewport))
    var zooming = GlobeZoomAnimation(factor: factor, about: tap, from: view)

    // Half way through the 0.3 s, a cubic ease-out has made 7/8 of the change of scale.
    zooming.advance(&view, by: 0.15, in: viewport)
    #expect(abs(view.zoom - start * pow(end / start, 0.875)) < 1e-9)
    #expect(!zooming.isFinished)

    zooming.advance(&view, by: 0.15, in: viewport)
    #expect(abs(view.zoom - end) < 1e-9)
    #expect(zooming.isFinished)

    let now = try #require(view.screenPoint(of: tapped, in: viewport))
    #expect(hypot(now.x - tap.x, now.y - tap.y) <= 0.5)
}

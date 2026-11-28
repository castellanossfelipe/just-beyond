import Foundation
import Testing
import JBGeo

/// An iPhone 13 in portrait.
private let viewport = GlobeViewport(width: 390, height: 844, globeRadius: 187)

@Test func slideZoomDoublesEveryHundredPoints() {
    #expect(abs(GlobeCamera.slideZoomFactor(slidUp: 100) - 2) < 1e-12)
    #expect(abs(GlobeCamera.slideZoomFactor(slidUp: 200) - 4) < 1e-12)
    #expect(abs(GlobeCamera.slideZoomFactor(slidUp: -100) - 0.5) < 1e-12)
    #expect(GlobeCamera.slideZoomFactor(slidUp: 0) == 1)
    // Touch updates multiply up to the same zoom as one long slide.
    let inSteps = (1...50).reduce(1.0) { zoom, _ in zoom * GlobeCamera.slideZoomFactor(slidUp: 2) }
    #expect(abs(inSteps - 2) < 1e-9)
}

import Foundation
import Testing
import JBGeo

private func camera(lat: Double = 0, lon: Double = 0, zoom: Double = 1) -> GlobeCamera {
    GlobeCamera(centre: LatLon(latDeg: lat, lonDeg: lon), zoom: zoom)
}

private let radius = 200.0
private let oneRadianDeg = 180 / Double.pi

@Test func dragAtCentreTurnsOneRadianPerRadiusOfFingerTravel() {
    var across = camera()
    across.drag(dx: radius, dy: 0, globeRadius: radius)
    #expect(abs(abs(across.centre.lonDeg) - oneRadianDeg) < 1e-9)
    #expect(across.centre.latDeg == 0)

    var down = camera()
    down.drag(dx: 0, dy: radius, globeRadius: radius)
    #expect(abs(abs(down.centre.latDeg) - oneRadianDeg) < 1e-9)
    #expect(down.centre.lonDeg == 0)
}

/// An iPhone 13 in portrait, and its screen middle.
private let viewport = GlobeViewport(width: 390, height: 844, globeRadius: 187)
private let middle = ScreenPoint(x: 195, y: 422)

@Test func dragRightBringsWestIntoView() {
    var view = camera(lat: 30, lon: -40)
    view.grab(from: middle, to: ScreenPoint(x: middle.x + 50, y: middle.y), in: viewport)
    #expect(view.centre.lonDeg < -40)
}

@Test func dragDownBringsNorthIntoView() {
    var view = camera(lat: 30, lon: -40)
    view.grab(from: middle, to: ScreenPoint(x: middle.x, y: middle.y + 50), in: viewport)
    #expect(view.centre.latDeg > 30)
}

/// Drags a finger in a straight line, one touch update every `stepLength` points.
private func drag(_ camera: inout GlobeCamera, from start: ScreenPoint, to end: ScreenPoint, stepLength: Double = 2) {
    let steps = Int((hypot(end.x - start.x, end.y - start.y) / stepLength).rounded())
    var previous = start
    for step in 1...steps {
        let t = Double(step) / Double(steps)
        let next = ScreenPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t)
        camera.grab(from: previous, to: next, in: viewport)
        previous = next
    }
}

private func distance(_ a: ScreenPoint, _ b: ScreenPoint) -> Double {
    hypot(a.x - b.x, a.y - b.y)
}

/// Golden (Systems Detail 16.1). Grabs at the middle and halfway out to each side, 40 pt drags
/// in eight directions.
@Test(arguments: [0.0, 45, -45], [1.0, 4, 8])
func placeUnderFingerStaysUnderFinger(lat: Double, zoom: Double) throws {
    var worst = 0.0
    for offset in [0, -viewport.globeRadius / 2, viewport.globeRadius / 2] {
        for eighth in 0..<8 {
            var view = camera(lat: lat, zoom: zoom)
            let start = ScreenPoint(x: middle.x + offset, y: middle.y)
            let angle = Double(eighth) * .pi / 4
            let end = ScreenPoint(x: start.x + 40 * cos(angle), y: start.y + 40 * sin(angle))
            let grabbed = try #require(view.place(at: start, in: viewport))
            drag(&view, from: start, to: end)
            let now = try #require(view.screenPoint(of: grabbed, in: viewport))
            worst = max(worst, distance(now, end))
        }
    }
    #expect(worst <= 0.5)
}

/// Camera latitude and grab point: one where the grab is exact, and the place at 80° N seen from
/// 50° N, which a sideways drag can't keep up with, so the path taken matters.
private let longSteps: [(Double, ScreenPoint)] = [
    (45, ScreenPoint(x: middle.x + viewport.globeRadius / 2, y: middle.y)),
    (50, ScreenPoint(x: middle.x, y: middle.y - viewport.globeRadius / 2)),
]

@Test(arguments: longSteps)
func longTouchStepIsSplit(lat: Double, start: ScreenPoint) throws {
    let end = ScreenPoint(x: start.x + 40, y: start.y)
    var once = camera(lat: lat)
    var often = camera(lat: lat)
    let grabbed = try #require(once.place(at: start, in: viewport))
    once.grab(from: start, to: end, in: viewport)
    drag(&often, from: start, to: end)
    let oncePoint = try #require(once.screenPoint(of: grabbed, in: viewport))
    let oftenPoint = try #require(often.screenPoint(of: grabbed, in: viewport))
    #expect(distance(oncePoint, oftenPoint) <= 0.5)
}

@Test func dragTurnsLessWhenZoomedIn() {
    var far = camera()
    var near = camera(zoom: 4)
    far.drag(dx: 40, dy: 40, globeRadius: radius)
    near.drag(dx: 40, dy: 40, globeRadius: radius)
    #expect(abs(near.centre.lonDeg - far.centre.lonDeg / 4) < 1e-9)
    #expect(abs(near.centre.latDeg - far.centre.latDeg / 4) < 1e-9)
}

@Test(arguments: [(45.0, 0.707_106_781_186_547_6), (60, 0.5), (-60, 0.5), (85, 0.2), (90, 0.2)])
func dragAtHighLatitudeStillFollowsTheFinger(lat: Double, widthOfParallel: Double) {
    var view = camera(lat: lat)
    view.drag(dx: 20, dy: 0, globeRadius: radius)
    // A narrower parallel needs more longitude for the same travel, down to a floor near the poles.
    #expect(abs(view.centre.lonDeg - -(0.1 * oneRadianDeg / widthOfParallel)) < 1e-9)
}

@Test(arguments: [(1.0, 90.0), (-1, -90)])
func latitudeStopsAtThePoles(direction: Double, pole: Double) {
    var view = camera(lat: 80 * direction)
    view.drag(dx: 0, dy: 1_000 * direction, globeRadius: radius)
    #expect(view.centre.latDeg == pole)
}

/// Start longitude and finger travel: across the antimeridian each way, and many times round.
private let longDrags: [(Double, Double)] = [(179, -10), (-179, 10), (0, 20 * 2 * Double.pi * radius + 1)]

@Test(arguments: longDrags)
func longitudeWrapsAtTheAntimeridian(startLon: Double, travel: Double) {
    var view = camera(lon: startLon)
    view.drag(dx: travel, dy: 0, globeRadius: radius)
    #expect(view.centre.lonDeg >= -180 && view.centre.lonDeg < 180)
    let expected = startLon - travel / radius * oneRadianDeg
    #expect(abs(remainder(view.centre.lonDeg - expected, 360)) < 1e-9)
}

@Test func pinchScalesZoomByTheFingerSpread() {
    var view = camera(zoom: 2)
    view.pinch(by: 1.5)
    #expect(view.zoom == 3)
    view.pinch(by: 0.5)
    #expect(view.zoom == 1.5)
}

@Test(arguments: [(100.0, 8.0), (0.001, 1), (0, 1)])
func pinchStaysInsideZoomLimits(factor: Double, limit: Double) {
    var view = camera(zoom: 2)
    view.pinch(by: factor)
    #expect(view.zoom == limit)
}

import Foundation
import Testing
import JBGeo

private func camera(lat: Double = 0, lon: Double = 0, zoom: Double = 1) -> GlobeCamera {
    GlobeCamera(centre: LatLon(latDeg: lat, lonDeg: lon), zoom: zoom)
}

private let oneRadianDeg = 180 / Double.pi

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
@Test(arguments: [0.0, 45, -45], [1.0, 4, 8, 10])
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

/// Camera latitude, and where the finger lands as an offset from the screen middle in globe
/// radii: near both poles, across them, and out at the rim.
private let jumpyDrags: [(Double, Double, Double)] = [
    (85, 0, 0), (-85, 0, 0), (89.9, 0.1, 0.1), (-89.9, -0.1, -0.1), (90, 0, 0.3), (-90, 0.3, 0),
    (50, 0, 0.5), (-50, 0, -0.5),
    (0, 0.99, 0), (0, 0, -0.99), (45, -0.7, 0.7), (-45, 0.7, -0.7),
]

@Test(arguments: jumpyDrags, [1.0, 8, 10])
func dragNeverJumps(drag: (Double, Double, Double), zoom: Double) {
    let (lat, right, up) = drag
    let radius = viewport.globeRadius * zoom
    let start = ScreenPoint(x: middle.x + right * radius, y: middle.y - up * radius)
    // No step may turn further than its own length in globe radii over σc = 0.25, in radians.
    let limit = 2 / radius / 0.25 * 180 / .pi * (1 + 1e-9)
    var worst = 0.0
    for eighth in 0..<8 {
        var view = camera(lat: lat, zoom: zoom)
        let angle = Double(eighth) * .pi / 4
        var previous = start
        for step in 1...100 {
            let travel = 2 * Double(step)
            let next = ScreenPoint(x: start.x + travel * cos(angle), y: start.y + travel * sin(angle))
            let before = view.centre
            view.grab(from: previous, to: next, in: viewport)
            #expect(view.centre.latDeg.isFinite && view.centre.lonDeg.isFinite)
            worst = max(worst, abs(view.centre.latDeg - before.latDeg),
                        abs(remainder(view.centre.lonDeg - before.lonDeg, 360)))
            previous = next
        }
    }
    #expect(worst <= limit)
}

/// Single steps just inside where the damping starts (0.968 of the radius), found by a sweep:
/// camera latitude, grab radius, which way out the grab is and which way the finger goes, in
/// degrees anticlockwise from screen right. The first solve there uses almost the whole limit,
/// so the corrector must not add past it.
private let edgeSteps: [(Double, Double, Double, Double)] = [
    (0, 0.968, 0, 0),
    (45, 0.9665325, 255, 260),
]

@Test(arguments: edgeSteps, [1.0, 4, 8])
func correctedDragNeverJumps(step: (Double, Double, Double, Double), zoom: Double) {
    let (lat, r, spoke, heading) = step
    let radius = viewport.globeRadius * zoom
    let out = spoke * .pi / 180
    let along = heading * .pi / 180
    let from = ScreenPoint(x: middle.x + r * cos(out) * radius, y: middle.y - r * sin(out) * radius)
    let to = ScreenPoint(x: from.x + 2 * cos(along), y: from.y - 2 * sin(along))
    var view = camera(lat: lat, zoom: zoom)
    view.grab(from: from, to: to, in: viewport)
    let limit = 2 / radius / 0.25 * 180 / .pi * (1 + 1e-9)
    #expect(abs(view.centre.latDeg - lat) <= limit)
    #expect(abs(view.centre.lonDeg) <= limit)
}

/// The nearest point of the rim, at 0.999 of the radius, for a point beyond it.
private func rim(_ point: ScreenPoint) -> ScreenPoint {
    let dx = point.x - middle.x
    let dy = point.y - middle.y
    let r = hypot(dx, dy) / viewport.globeRadius
    guard r > 0.999 else { return point }
    return ScreenPoint(x: middle.x + dx * 0.999 / r, y: middle.y + dy * 0.999 / r)
}

/// Where the finger starts, as an offset from the screen middle in points, and its travel: off to
/// one side, out in a corner, and from on the globe to off it.
private let outsideDrags: [(Double, Double, Double, Double)] = [
    (192, 0, 0, 40), (-180, -380, 60, 0), (170, 0, 40, -30),
]

@Test(arguments: outsideDrags)
func dragFromOutsideTheGlobeGrabsTheRim(x: Double, y: Double, dx: Double, dy: Double) {
    var outside = camera(lat: 20)
    var onRim = camera(lat: 20)
    var previous = ScreenPoint(x: middle.x + x, y: middle.y + y)
    for step in 1...40 {
        let t = Double(step) / 40
        let next = ScreenPoint(x: middle.x + x + dx * t, y: middle.y + y + dy * t)
        outside.grab(from: previous, to: next, in: viewport)
        onRim.grab(from: rim(previous), to: rim(next), in: viewport)
        previous = next
    }
    #expect(onRim != camera(lat: 20))
    #expect(abs(outside.centre.latDeg - onRim.centre.latDeg) < 1e-9)
    #expect(abs(outside.centre.lonDeg - onRim.centre.lonDeg) < 1e-9)
}

@Test func zoomedInDragTurnsLess() {
    let end = ScreenPoint(x: middle.x + 40, y: middle.y)
    var far = camera()
    var near = camera(zoom: 4)
    drag(&far, from: middle, to: end)
    drag(&near, from: middle, to: end)
    #expect(abs(near.centre.lonDeg / far.centre.lonDeg - 0.25) < 0.25 * 0.01)
}

/// A finger dragged from the middle, toward the near pole's far side and a little sideways.
@Test(arguments: [(1.0, 0.0), (-1, 0), (1, 30), (-1, -30)])
func dragPastThePoleStopsAtThePole(direction: Double, sideways: Double) {
    var view = camera(lat: 80 * direction)
    drag(&view, from: middle, to: ScreenPoint(x: middle.x + sideways, y: middle.y + 150 * direction))
    #expect(view.centre.latDeg * direction <= 90)
    #expect(view.centre.latDeg * direction > 89)
    #expect(view.centre.lonDeg >= -180 && view.centre.lonDeg < 180)
}

/// Camera at 50° N, grabbing the place at 80° N on the middle meridian: its parallel is too narrow
/// on screen to follow the finger, which has to slip while the globe keeps turning.
@Test(arguments: [150.0, -150])
func sidewaysDragNearPoleDoesNotFreeze(travel: Double) throws {
    var view = camera(lat: 50)
    let start = try #require(view.screenPoint(of: LatLon(latDeg: 80, lonDeg: 0), in: viewport))
    drag(&view, from: start, to: ScreenPoint(x: start.x + travel, y: start.y))
    #expect(abs(view.centre.lonDeg) >= 20)
}

/// Start longitude, finger travel from the middle, and how many such drags: across the
/// antimeridian each way, and nearly three times round.
private let wrappingDrags: [(Double, Double, Int)] = [(179, -50, 1), (-179, 50, 1), (0, 100, 30)]

@Test(arguments: wrappingDrags)
func longitudeWrapsAtTheAntimeridian(startLon: Double, travel: Double, drags: Int) {
    var view = camera(lon: startLon)
    for _ in 0..<drags {
        drag(&view, from: middle, to: ScreenPoint(x: middle.x + travel, y: middle.y))
    }
    #expect(view.centre.lonDeg >= -180 && view.centre.lonDeg < 180)
    // On the equator, the place at the middle ends `travel` to the side of the new middle.
    let expected = startLon - Double(drags) * asin(travel / viewport.globeRadius) * oneRadianDeg
    #expect(abs(remainder(view.centre.lonDeg - expected, 360)) < 0.01)
}

/// Starting at zoom 2, so that halving it is not stopped by the zoom limit.
@Test(arguments: [0.0, 45, -45], [0.5, 1.5, 2])
func zoomAboutPointKeepsThatPlaceStill(lat: Double, factor: Double) throws {
    for offset in [0, -viewport.globeRadius / 2, viewport.globeRadius / 2] {
        var view = camera(lat: lat, zoom: 2)
        let point = ScreenPoint(x: middle.x + offset, y: middle.y)
        let held = try #require(view.place(at: point, in: viewport))
        view.zoom(by: factor, about: point, in: viewport)
        #expect(view.zoom == 2 * factor)
        let now = try #require(view.screenPoint(of: held, in: viewport))
        #expect(distance(now, point) <= 0.5)
    }
}

@Test func pinchScalesZoomByTheFingerSpread() {
    var view = camera(zoom: 2)
    view.pinch(by: 1.5)
    #expect(view.zoom == 3)
    view.pinch(by: 0.5)
    #expect(view.zoom == 1.5)
}

@Test(arguments: [(100.0, 10.0), (0.001, 1), (0, 1)])
func pinchStaysInsideZoomLimits(factor: Double, limit: Double) {
    var view = camera(zoom: 2)
    view.pinch(by: factor)
    #expect(view.zoom == limit)
}

import Foundation
import Testing
import JBGeo

private let newYork = LatLon(latDeg: 40.71, lonDeg: -74.01)
private let london = LatLon(latDeg: 51.51, lonDeg: -0.13)

@Test func arcEndpointsAreExact() {
    let arc = GreatCircle.arc(from: newYork, to: london)
    #expect(arc.first == newYork.unitVector)
    #expect(arc.last == london.unitVector)
}

@Test func arcPointsAreUnitVectors() {
    for v in GreatCircle.arc(from: newYork, to: london) {
        #expect(abs(length(v) - 1) < 1e-12)
    }
}

private func length(_ v: Vector3) -> Double {
    (v.x * v.x + v.y * v.y + v.z * v.z).squareRoot()
}

/// The angle between two points on the unit sphere, in radians.
private func angle(_ a: Vector3, _ b: Vector3) -> Double {
    let cross = Vector3(x: a.y * b.z - a.z * b.y, y: a.z * b.x - a.x * b.z, z: a.x * b.y - a.y * b.x)
    return atan2(length(cross), a.x * b.x + a.y * b.y + a.z * b.z)
}

private func steps(_ arc: [Vector3]) -> [Double] {
    zip(arc, arc.dropFirst()).map { angle($0, $1) }
}

@Test func arcSpacingIsEven() throws {
    let steps = steps(GreatCircle.arc(from: newYork, to: london))
    try #require(steps.count > 1)
    for step in steps {
        #expect(abs(step - steps[0]) < 1e-9)
    }
}

@Test(arguments: [
    (newYork, london),
    (LatLon(latDeg: 0, lonDeg: 0), LatLon(latDeg: 0, lonDeg: 90)),
    (LatLon(latDeg: -34, lonDeg: 151), LatLon(latDeg: 34, lonDeg: -118)),
])
func arcStepsAreAtMostOneDegree(start: LatLon, end: LatLon) {
    for step in steps(GreatCircle.arc(from: start, to: end)) {
        #expect(step <= .pi / 180 + 1e-12)
    }
}

@Test func arcMidpointOfEquatorQuarterIsFortyFiveDegrees() {
    let arc = GreatCircle.arc(from: LatLon(latDeg: 0, lonDeg: 0), to: LatLon(latDeg: 0, lonDeg: 90))
    let middle = LatLon(arc[arc.count / 2])
    #expect(arc.count % 2 == 1)
    #expect(abs(middle.latDeg) < 1e-9)
    #expect(abs(middle.lonDeg - 45) < 1e-9)
}

@Test func arcOfIdenticalPointsIsThatPoint() {
    #expect(GreatCircle.arc(from: london, to: london) == [london.unitVector])
}

@Test(arguments: [
    (LatLon(latDeg: 0, lonDeg: 0), LatLon(latDeg: 0, lonDeg: 180)),
    (LatLon(latDeg: 90, lonDeg: 0), LatLon(latDeg: -90, lonDeg: 0)),
    (newYork, LatLon(latDeg: -40.71, lonDeg: 105.99)),
])
func arcOfAntipodesNeverReturnsNaN(start: LatLon, end: LatLon) {
    let arc = GreatCircle.arc(from: start, to: end)
    #expect(arc.first == start.unitVector)
    #expect(arc.last == end.unitVector)
    #expect(arc.allSatisfy { abs(length($0) - 1) < 1e-9 })
    // Half way round, with no jumps.
    #expect(steps(arc).allSatisfy { $0 <= .pi / 180 + 1e-9 })
}

@Test func newYorkLondonArcBulgesNorthOfBothEnds() {
    let arc = GreatCircle.arc(from: newYork, to: london)
    let middle = LatLon(arc[arc.count / 2])
    #expect(middle.latDeg > newYork.latDeg)
    #expect(middle.latDeg > london.latDeg)
}

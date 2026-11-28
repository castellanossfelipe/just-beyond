import Foundation
import Testing
import JBGeo

private let newYork = LatLon(latDeg: 40.71, lonDeg: -74.01)

@Test(arguments: [100.0, 2_500, 12_000])
func everyRingPointIsTheSameAngleFromCentre(radiusKm: Double) {
    let ring = RangeRing.points(around: newYork, radiusKm: radiusKm)
    #expect(!ring.isEmpty)
    for point in ring {
        #expect(abs(angle(newYork.unitVector, point) - radiusKm / 6_371) < 1e-9)
    }
}

@Test func ringSamplesEveryTwoDegreesOfBearing() throws {
    // From 0°N 0°E, the bearing of a point is the angle from the z axis towards the y axis.
    let ring = RangeRing.points(around: LatLon(latDeg: 0, lonDeg: 0), radiusKm: 2_500)
    try #require(ring.count == 181)
    for (i, point) in ring.dropLast().enumerated() {
        let bearingDeg = (atan2(point.y, point.z) * 180 / .pi + 360).truncatingRemainder(dividingBy: 360)
        #expect(abs(bearingDeg - Double(i) * 2) < 1e-9)
    }
}

@Test func ringOfZeroRadiusIsTheCentre() {
    #expect(RangeRing.points(around: newYork, radiusKm: 0) == [newYork.unitVector])
}

@Test(arguments: [newYork, LatLon(latDeg: 0, lonDeg: 180), LatLon(latDeg: 90, lonDeg: 0)])
func ringIsClosed(centre: LatLon) {
    let ring = RangeRing.points(around: centre, radiusKm: 2_500)
    #expect(ring.count > 2)
    #expect(ring.first == ring.last)
}

@Test func ringOverTheNorthPoleStaysEquidistant() {
    // 80°N is 1,112 km from the pole, so a 2,500 km ring goes well past it.
    let centre = LatLon(latDeg: 80, lonDeg: 20)
    let ring = RangeRing.points(around: centre, radiusKm: 2_500)
    for point in ring {
        #expect(abs(angle(centre.unitVector, point) - 2_500 / 6_371) < 1e-9)
    }
    // Due north from the centre carries on down the far side.
    #expect(abs(LatLon(ring[0]).lonDeg - -160) < 1e-9)
}

@Test(arguments: [20_100.0, 40_000, 1_000_000])
func ringLargerThanHalfTheEarthIsClampedNotBroken(radiusKm: Double) {
    let antipode = LatLon(latDeg: -40.71, lonDeg: 105.99).unitVector
    let ring = RangeRing.points(around: newYork, radiusKm: radiusKm)
    #expect(!ring.isEmpty)
    #expect(ring.allSatisfy { angle(antipode, $0) < 1e-9 })
}

@Test func ringOfNegativeRadiusIsTheCentre() {
    #expect(RangeRing.points(around: newYork, radiusKm: -500) == [newYork.unitVector])
}

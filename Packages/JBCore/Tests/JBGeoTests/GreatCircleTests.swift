import Testing
import JBGeo

private let newYork = LatLon(latDeg: 40.71, lonDeg: -74.01)
private let london = LatLon(latDeg: 51.51, lonDeg: -0.13)

@Test func arcEndpointsAreExact() {
    let arc = GreatCircle.arc(from: newYork, to: london)
    #expect(arc.first == newYork.unitVector)
    #expect(arc.last == london.unitVector)
}

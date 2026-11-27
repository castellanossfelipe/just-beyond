import Foundation
import JBGeo

/// Reads the bundled `coastlines.json`, built by `tools/build_coastlines.py`.
enum Coastlines {
    private struct File: Decodable {
        var lines: [[[Double]]]
    }

    static func load(from bundle: Bundle = .main) -> [[LatLon]] {
        guard let url = bundle.url(forResource: "coastlines", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let file = try? JSONDecoder().decode(File.self, from: data)
        else {
            assertionFailure("coastlines.json is missing from the app or unreadable")
            return []
        }
        // Each point is [lon, lat].
        return file.lines.map { line in
            line.compactMap { $0.count == 2 ? LatLon(latDeg: $0[1], lonDeg: $0[0]) : nil }
        }
    }
}

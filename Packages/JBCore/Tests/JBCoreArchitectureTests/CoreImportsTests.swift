import Foundation
import Testing

/// The core must stay free of UI frameworks (CLAUDE.md, architecture rules).
@Test func coreSourcesNeverImportUIFrameworks() throws {
    let sources = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()  // JBCoreArchitectureTests
        .deletingLastPathComponent()  // Tests
        .deletingLastPathComponent()  // JBCore
        .appendingPathComponent("Sources")
    let walker = try #require(FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil))
    let banned = try NSRegularExpression(
        pattern: #"^\s*(?:@\w+\s+)*(?:(?:public|package|internal|private|fileprivate)\s+)?import\s+(?:(?:struct|class|enum|protocol|func|var|let|typealias)\s+)?(SwiftUI|UIKit|RealityKit)\b"#,
        options: [.anchorsMatchLines])

    var scanned = 0
    var violations: [String] = []
    for case let url as URL in walker where url.pathExtension == "swift" {
        scanned += 1
        let text = try String(contentsOf: url, encoding: .utf8)
        let range = NSRange(text.startIndex..., in: text)
        if banned.firstMatch(in: text, range: range) != nil {
            violations.append(url.lastPathComponent)
        }
    }
    #expect(scanned >= 6, "found only \(scanned) source files; is the Sources path right?")
    #expect(violations.isEmpty, "UI framework imported in: \(violations)")
}

import ArgumentParser
import Foundation

let sourceURL = Bundle.module.url(forResource: "VerizonMock", withExtension: "txt")!

@main
struct FeatureFiller: ParsableCommand {
    @Argument var theoFrameworkPlistPath: String
    @Argument var outputPath: String

    func run() throws {
        let theoInfoPlistURL = URL(fileURLWithPath: theoFrameworkPlistPath)
        let theoInfoPlistData = try Data(contentsOf: theoInfoPlistURL)
        let theoInfoPlist = try PropertyListDecoder().decode(TheoFrameworkPlist.self, from: theoInfoPlistData)
                
        if FileManager.default.fileExists(atPath: outputPath) {
            try FileManager.default.removeItem(atPath: outputPath)
        }
        let outputURL = URL(fileURLWithPath: outputPath)
        if theoInfoPlist.buildInfo.features.contains("verizonmedia") {
            try Data().write(to: outputURL)
        } else {
            try FileManager.default.copyItem(at: sourceURL, to: outputURL)
        }
    }
}

//
//  Plugin.swift
//  
//
//  Created by Damiaan Dufaux on 28/09/2022.
//

import PackagePlugin

@main struct TheoFeaturesPlugin: BuildToolPlugin {
    func createBuildCommands(context: PackagePlugin.PluginContext, target: PackagePlugin.Target) async throws -> [PackagePlugin.Command] {
        let theoDependency = context.package.dependencies.first { $0.package.displayName == "THEOplayerSDK" }
        let theoTarget = theoDependency?.package.targets.first { $0 is BinaryArtifactTarget } as? BinaryArtifactTarget
        let theoFrameworkPath = theoTarget?.artifact
        if let theoInfoPlistPath = theoFrameworkPath?.appending(["ios-arm64", "THEOplayerSDK.framework", "Info.plist"]) {
            let outputPath = context.pluginWorkDirectory.appending(["VerizonMocks.swift"])
            return [
                .buildCommand(
                    displayName: "Running Theo Feature detecor plugin",
                    executable: try context.tool(named: "FeatureMocker").path,
                    arguments: [theoInfoPlistPath.string, outputPath.string],
                    inputFiles: [theoInfoPlistPath],
                    outputFiles: [outputPath]
                )
            ]
        } else {
            return []
        }
    }
}

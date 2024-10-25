public class VersionHelper {
    private static func podBundlePath(_ bundleName: String) -> String? {
        return Bundle(for: VersionHelper.self).path(
            forResource: bundleName,
            ofType: "bundle"
        )
    }
    
    private static func podBundle(_ bundleName: String) -> Bundle? {
        guard let podBundlePath = podBundlePath(bundleName) else {
            return nil
        }
        return Bundle(path: podBundlePath)
    }
    
    public static func version(_ bundleName: String) -> String {
        if let versionPath = VersionHelper.podBundle(bundleName)?.url(forResource: "version", withExtension: "json") {
            do {
                let data = try Data(contentsOf: versionPath, options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? [String:String],
                   let major_minor = jsonResult["major_minor"],
                   let patch = jsonResult["patch"]{
                    return major_minor + "." + patch
                }
            } catch {
                print("Version for \(bundleName) is not in the correct format.")
            }
        }
        print("Could not load version for \(bundleName).")
        return "?.?.?"
    }
}

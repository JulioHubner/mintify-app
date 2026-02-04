import Foundation

private var bundleKey: UInt8 = 0

/// Custom bundle class that overrides localization lookup
class BundleEx: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// Sets the app language at runtime by swapping the bundle
    static func setLanguage(_ language: String) {
        defer { object_setClass(Bundle.main, BundleEx.self) }
        
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            // Fallback to base if language not found
            if let basePath = Bundle.main.path(forResource: "Base", ofType: "lproj"),
               let baseBundle = Bundle(path: basePath) {
                objc_setAssociatedObject(Bundle.main, &bundleKey, baseBundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return
        }
        
        objc_setAssociatedObject(Bundle.main, &bundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

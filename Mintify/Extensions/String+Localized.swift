import Foundation

extension String {
    /// Returns the localized string for this key
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /// Returns the localized string with format arguments
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    /// Returns the localized string with a single argument
    func localized(_ arg: CVarArg) -> String {
        return String(format: self.localized, arg)
    }
    
    /// Returns the localized string with two arguments
    func localized(_ arg1: CVarArg, _ arg2: CVarArg) -> String {
        return String(format: self.localized, arg1, arg2)
    }
}

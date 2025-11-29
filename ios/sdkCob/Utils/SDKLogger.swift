import Foundation

public class SDKLogger {
    public static var isEnabled: Bool = true
    
    public static func log(_ message: String) {
        if isEnabled {
            print("🔵 COB SDK: \(message)")
        }
    }
    
    public static func error(_ message: String) {
        if isEnabled {
            print("🔴 COB SDK ERROR: \(message)")
        }
    }
    
    public static func info(_ message: String) {
        if isEnabled {
            print("ℹ️ COB SDK INFO: \(message)")
        }
    }
    
    public static func debug(_ message: String) {
        if isEnabled {
            print("🟡 COB SDK DEBUG: \(message)")
        }
    }
}
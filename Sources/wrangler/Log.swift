import Foundation

enum Log {
    static func error(_ value: String, prefix _prefix: String? = nil) {
        let redANSI = "\u{001B}[0;31m"
        let resetANSI = "\u{001B}[0;0m"
        var prefix = ""
        
        if let _prefix = _prefix {
            prefix += redANSI + _prefix + resetANSI + ": "
        }
        
        fputs(prefix + value + "\n", stderr)
    }
    
    static func error(_ error: Error, prefix: String? = nil) {
        Log.error(error.localizedDescription, prefix: prefix)
    }
    
    static func info(_ value: String, prefix _prefix: String? = nil) {
        let greenANSI = "\u{001B}[0;32m"
        let resetANSI = "\u{001B}[0;0m"
        
        var prefix = ""
        
        if let _prefix = _prefix {
            prefix += greenANSI + _prefix + resetANSI + ": "
        }
        
        fputs(prefix + value + "\n", stdout)
    }
}

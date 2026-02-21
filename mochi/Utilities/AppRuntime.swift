import Foundation

enum AppRuntime {
    static var isRunningTests: Bool {
        let environment = ProcessInfo.processInfo.environment
        if environment["MOCHI_RUNNING_TESTS"] == "1" { return true }
        if environment["XCTestConfigurationFilePath"] != nil { return true }
        if NSClassFromString("XCTestCase") != nil { return true }
        return false
    }
}

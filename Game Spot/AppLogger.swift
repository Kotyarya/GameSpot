import Foundation

enum AppLogger {

    static func info(
        _ message: String
    ) {

        #if DEBUG
        print("ℹ️ \(message)")
        #endif
    }

    static func success(
        _ message: String
    ) {

        #if DEBUG
        print("✅ \(message)")
        #endif
    }

    static func warning(
        _ message: String
    ) {

        #if DEBUG
        print("⚠️ \(message)")
        #endif
    }

    static func error(
        _ message: String,
        error: Error? = nil
    ) {

        #if DEBUG

        if let error {

            print("❌ \(message)")
            print("❌ Error:", error)

        } else {

            print("❌ \(message)")
        }

        #endif
    }
}

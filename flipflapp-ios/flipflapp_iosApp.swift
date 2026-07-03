import SwiftUI
import HotwireNative

@main
struct flipflapp_iosApp: App {
    init() {
        Hotwire.config.applicationUserAgentPrefix = "Flipflapp;"
        Hotwire.config.backButtonDisplayMode = .minimal
        Hotwire.config.showDoneButtonOnModals = true

        #if DEBUG
        Hotwire.config.debugLoggingEnabled = true
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

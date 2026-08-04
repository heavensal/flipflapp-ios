import SwiftUI

@main
struct flipflapp_iosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var container = AppContainer()
    @State private var deepLinkRouter = AppDeepLinkRouter()

    var body: some Scene {
        WindowGroup {
            ContentView(container: container, deepLinkRouter: deepLinkRouter)
                .onOpenURL { url in
                    deepLinkRouter.handle(url: url)
                }
        }
    }
}

import SwiftUI
import UIKit
import HotwireNative

struct HotwireRootView: UIViewControllerRepresentable {
    private let rootURL = URL(string: "https://flipflapp.fr")!

    func makeUIViewController(context: Context) -> UINavigationController {
        let navigator = Navigator(
            configuration: .init(
                name: "main",
                startLocation: rootURL
            ),
            delegate: context.coordinator
        )

        context.coordinator.navigator = navigator
        navigator.start()

        return navigator.rootViewController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, NavigatorDelegate {
        var navigator: Navigator?

        func handle(proposal: VisitProposal, from navigator: Navigator) -> ProposalResult {
            .accept
        }
    }
}

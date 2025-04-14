import SwiftUI

extension View {
    func replaceRootView<NewRootView: View>(with newRootView: NewRootView) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController = UIHostingController(rootView: newRootView)
            window.makeKeyAndVisible()
        }
    }
}

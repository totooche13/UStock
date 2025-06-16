import SwiftUI
import UIKit

extension View {
    func replaceRootView<NewRootView: View>(with newRootView: NewRootView) {
        // S'assurer que nous sommes sur le thread principal
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                print("❌ Impossible de trouver la fenêtre principale")
                return
            }
            
            print("🔄 Remplacement de la vue racine...")
            
            // Créer le nouveau contrôleur
            let newViewController = UIHostingController(rootView: newRootView)
            
            // Animation douce pour la transition
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = newViewController
            }, completion: { _ in
                print("✅ Transition vers la nouvelle vue terminée")
            })
            
            window.makeKeyAndVisible()
        }
    }
    
    // Version alternative avec callback de completion
    func replaceRootView<NewRootView: View>(with newRootView: NewRootView, completion: @escaping () -> Void = {}) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                print("❌ Impossible de trouver la fenêtre principale")
                completion()
                return
            }
            
            let newViewController = UIHostingController(rootView: newRootView)
            
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = newViewController
            }, completion: { _ in
                window.makeKeyAndVisible()
                completion()
            })
        }
    }
    
    // Version sans animation pour les cas d'urgence
    func replaceRootViewImmediate<NewRootView: View>(with newRootView: NewRootView) {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(rootView: newRootView)
                window.makeKeyAndVisible()
            }
        }
    }
}

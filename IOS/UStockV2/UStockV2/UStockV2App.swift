import SwiftUI

@main
struct UStockV2App: App {
    @State private var isAuthenticated = false
    @State private var isChecking = true
    
    var body: some Scene {
        WindowGroup {
            if isChecking {
                // Écran de chargement pendant la vérification
                ProgressView("Vérification...")
                    .onAppear {
                        checkAuthentication()
                    }
            } else {
                if isAuthenticated {
                    InventaireView()
                } else {
                    WelcomeView()
                }
            }
        }
    }
    
    private func checkAuthentication() {
        AuthManager.shared.validateToken { isValid in
            isAuthenticated = isValid
            isChecking = false
        }
    }
}

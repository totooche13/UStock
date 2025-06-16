import SwiftUI

@main
struct UStockV2App: App {
    @State private var isAuthenticated = false
    @State private var isChecking = true
    @State private var showNetworkError = false
    @State private var authError: String?
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if isChecking {
                    // Écran de chargement pendant la vérification
                    SplashView()
                        .onAppear {
                            checkAuthentication()
                        }
                } else {
                    if isAuthenticated {
                        InventaireView()
                            .transition(.opacity.combined(with: .scale))
                    } else {
                        WelcomeView()
                            .transition(.opacity.combined(with: .scale))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.5), value: isChecking)
            .animation(.easeInOut(duration: 0.5), value: isAuthenticated)
            .alert("Erreur de connexion", isPresented: $showNetworkError) {
                Button("Réessayer") {
                    checkAuthentication()
                }
                Button("Continuer hors ligne") {
                    isChecking = false
                    isAuthenticated = false
                }
            } message: {
                Text(authError ?? "Impossible de vérifier votre authentification. Vérifiez votre connexion internet.")
            }
        }
    }
    
    private func checkAuthentication() {
        print("🔄 Vérification de l'authentification...")
        
        // Réinitialiser les états
        isChecking = true
        showNetworkError = false
        authError = nil
        
        // Vérifier si un token existe d'abord
        guard AuthManager.shared.isLoggedIn() else {
            print("❌ Aucun token trouvé, redirection vers WelcomeView")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.isChecking = false
                self.isAuthenticated = false
            }
            return
        }
        
        // Valider le token avec timeout
        let timeoutWorkItem = DispatchWorkItem {
            DispatchQueue.main.async {
                if self.isChecking {
                    print("⏰ Timeout de validation du token")
                    self.authError = "La vérification de l'authentification a pris trop de temps."
                    self.showNetworkError = true
                    self.isChecking = false
                    self.isAuthenticated = false
                }
            }
        }
        
        // Démarrer le timeout (10 secondes)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: timeoutWorkItem)
        
        AuthManager.shared.validateToken { isValid in
            // Annuler le timeout si on reçoit une réponse
            timeoutWorkItem.cancel()
            
            DispatchQueue.main.async {
                self.isChecking = false
                self.isAuthenticated = isValid
                
                if isValid {
                    print("✅ Token valide, redirection vers InventaireView")
                } else {
                    print("❌ Token invalide, redirection vers WelcomeView")
                    // Nettoyer le token invalide
                    AuthManager.shared.removeToken()
                }
            }
        }
    }
}

// Vue de splash/chargement améliorée
struct SplashView: View {
    @State private var isAnimating = false
    @State private var showProgress = false
    
    var body: some View {
        ZStack {
            Color(hex: "C0DDF9")
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Logo avec animation
                Image("ustock_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                // Titre
                Text("UStock")
                    .font(.custom("ChauPhilomeneOne-Regular", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .opacity(isAnimating ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isAnimating)
                
                // Indicateur de progression après 2 secondes
                if showProgress {
                    VStack(spacing: 15) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "156585")))
                            .scaleEffect(1.2)
                        
                        Text("Vérification de l'authentification...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
            
            // Afficher le progress après 2 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showProgress = true
                }
            }
        }
    }
}

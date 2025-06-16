import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @State private var username = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var navigateToInventory = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "C0DDF9")
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Text("Bienvenue sur UStock")
                        .font(.custom("ChauPhilomeneOne-Regular", size: 24))
                        .fontWeight(.bold)
                        .padding(.top, 10)
                        .foregroundColor(Color(.black))

                    Image("ustock_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)

                    HStack(spacing: 10) {
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(Color(hex: "156585"))
                            .frame(maxWidth: .infinity)

                        Text("CONNEXION")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 30))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "156585"))
                            .fixedSize(horizontal: true, vertical: false)
                            .padding(.horizontal, 10)

                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(Color(hex: "156585"))
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 30)

                    CustomTextField(placeholder: "Identifiant de connexion*", text: $username)
                        .disabled(viewModel.isLoading) // Désactiver pendant le chargement
                    
                    CustomSecureField(placeholder: "Mot de passe*", text: $password, isPasswordVisible: $isPasswordVisible)
                        .disabled(viewModel.isLoading) // Désactiver pendant le chargement

                    Button(action: {
                        print("Mot de passe oublié ?")
                    }) {
                        Text("Mot de passe oublié ?")
                            .foregroundColor(.blue)
                            .underline()
                            .padding(.top, 10)
                    }
                    .disabled(viewModel.isLoading) // Désactiver pendant le chargement

                    Spacer()

                    // 🔹 Bouton CONTINUER amélioré
                    Button(action: {
                        // Empêcher les clics multiples pendant le chargement
                        guard !viewModel.isLoading else {
                            print("⚠️ Bouton déjà en cours de traitement")
                            return
                        }
                        
                        // Validation côté client
                        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
                        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        guard !trimmedUsername.isEmpty, !trimmedPassword.isEmpty else {
                            viewModel.errorMessage = "Veuillez remplir tous les champs"
                            viewModel.showErrorAlert = true
                            return
                        }
                        
                        print("🔄 Tentative de connexion...")
                        
                        viewModel.login(username: trimmedUsername, password: trimmedPassword) { success in
                            DispatchQueue.main.async {
                                if success {
                                    print("✅ Connexion réussie, redirection vers l'inventaire")
                                    self.replaceRootView(with: InventaireView())
                                } else {
                                    print("❌ Échec de la connexion")
                                }
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 8)
                            }
                            
                            Text(viewModel.isLoading ? "CONNEXION..." : "CONTINUER")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 28))
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.isLoading ?
                                Color(hex: "689FA7").opacity(0.7) :
                                Color(hex: "689FA7")
                        )
                        .foregroundColor(.black)
                        .cornerRadius(20)
                        .shadow(radius: viewModel.isLoading ? 2 : 5)
                        .scaleEffect(viewModel.isLoading ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
                    }
                    .disabled(viewModel.isLoading)  // Désactiver pendant le chargement
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)
                }
            }
            
            // Alertes d'erreur améliorées
            .alert("Erreur de connexion", isPresented: $viewModel.showErrorAlert, actions: {
                Button("Réessayer", role: .cancel) {
                    viewModel.resetState()
                }
                
                if viewModel.errorMessage?.contains("internet") == true ||
                   viewModel.errorMessage?.contains("réseau") == true {
                    Button("Paramètres réseau") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }, message: {
                Text(viewModel.errorMessage ?? "Une erreur est survenue lors de la connexion")
            })
            
            // Gestion du clavier
            .onTapGesture {
                hideKeyboard()
            }
            
            // Nettoyage en cas de disparition de la vue
            .onDisappear {
                viewModel.resetState()
            }
        }
        .hideKeyboardOnTap()
    }
    
    // Fonction pour masquer le clavier
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    LoginView()
}

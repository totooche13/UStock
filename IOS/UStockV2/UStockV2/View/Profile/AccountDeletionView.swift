//
//  AccountDeletionView.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 12/06/2025.
//


import SwiftUI

struct AccountDeletionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var confirmationText = ""
    @State private var showFinalConfirmation = false
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private let requiredText = "SUPPRIMER MON COMPTE"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 🔹 Icône d'avertissement
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.red)
                            .padding(.top, 20)
                        
                        // 🔹 Titre principal
                        Text("Supprimer mon compte")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                        
                        // 🔹 Avertissements
                        VStack(alignment: .leading, spacing: 15) {
                            Text("⚠️ Cette action est irréversible")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text("En supprimant votre compte, vous perdrez définitivement :")
                                .font(.subheadline)
                                .foregroundColor(.black)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                warningItem("• Tout votre inventaire de produits")
                                warningItem("• Vos statistiques de consommation")
                                warningItem("• Votre historique de gaspillage")
                                warningItem("• Vos listes de courses")
                                warningItem("• Toutes vos données personnelles")
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // 🔹 Alternatives
                        VStack(alignment: .leading, spacing: 10) {
                            Text("💡 Alternatives à considérer :")
                                .font(.headline)
                                .foregroundColor(Color(hex: "156585"))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                alternativeItem("• Vider votre inventaire plutôt que supprimer le compte")
                                alternativeItem("• Changer votre mot de passe si vous avez des problèmes de sécurité")
                                alternativeItem("• Nous contacter pour résoudre un problème")
                            }
                        }
                        .padding()
                        .background(Color(hex: "156585").opacity(0.1))
                        .cornerRadius(15)
                        .padding(.horizontal)
                        
                        // 🔹 Confirmation par saisie
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Pour confirmer, tapez exactement :")
                                .font(.subheadline)
                                .foregroundColor(.black)
                            
                            Text(requiredText)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(.red)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            
                            TextField("Tapez ici", text: $confirmationText)
                                .padding(15)
                                .background(Color.white)
                                .cornerRadius(10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(confirmationText == requiredText ? Color.red : Color.gray.opacity(0.3), lineWidth: 2)
                                )
                        }
                        .padding(.horizontal)
                        
                        // 🔹 Boutons d'action
                        VStack(spacing: 15) {
                            // Bouton de suppression
                            Button(action: {
                                showFinalConfirmation = true
                            }) {
                                HStack {
                                    if isDeleting {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .padding(.trailing, 5)
                                    }
                                    
                                    Text(isDeleting ? "SUPPRESSION EN COURS..." : "SUPPRIMER DÉFINITIVEMENT")
                                        .font(.custom("ChauPhilomeneOne-Regular", size: 18))
                                        .fontWeight(.bold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(confirmationText == requiredText ? Color.red : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(radius: confirmationText == requiredText ? 5 : 0)
                            }
                            .disabled(confirmationText != requiredText || isDeleting)
                            .padding(.horizontal)
                            
                            // Bouton d'annulation
                            Button(action: {
                                dismiss()
                            }) {
                                Text("ANNULER")
                                    .font(.custom("ChauPhilomeneOne-Regular", size: 18))
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "689FA7"))
                                    .foregroundColor(.black)
                                    .cornerRadius(15)
                                    .shadow(radius: 3)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Suppression de compte")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Dernière confirmation", isPresented: $showFinalConfirmation) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer définitivement", role: .destructive) {
                    deleteAccount()
                }
            } message: {
                Text("Êtes-vous absolument certain de vouloir supprimer votre compte ? Cette action ne peut pas être annulée.")
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // 🔹 Fonction de suppression de compte
    private func deleteAccount() {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            errorMessage = "Erreur d'authentification"
            showError = true
            return
        }
        
        isDeleting = true
        
        // URL de l'API pour supprimer le compte
        let url = URL(string: "https://api.ustock.pro/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                self.isDeleting = false
                
                if let error = error {
                    self.errorMessage = "Erreur réseau : \(error.localizedDescription)"
                    self.showError = true
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        // Suppression réussie
                        AuthManager.shared.removeToken()
                        
                        // Rediriger vers l'écran de bienvenue
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController = UIHostingController(rootView: WelcomeView())
                            window.makeKeyAndVisible()
                        }
                    } else {
                        self.errorMessage = "Erreur lors de la suppression du compte (Code: \(httpResponse.statusCode))"
                        self.showError = true
                    }
                }
            }
        }.resume()
    }
    
    // 🔹 Composants helper
    private func warningItem(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.black)
    }
    
    private func alternativeItem(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(Color(hex: "156585"))
    }
}

#Preview {
    AccountDeletionView()
}
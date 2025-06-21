import SwiftUI

struct WelcomeView: View {
    @State private var showAccountOptions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "C0DDF9")
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()

                    // Logo
                    Image("ustock_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)


                    Spacer()

                    // 📌 BOUTON PRINCIPAL : Scanner directement (pas de compte requis)
                    NavigationLink(destination: GuestScannerView()) {
                        Text("SCANNER UN PRODUIT")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 28))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "22C55E"))
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 30)
                    
                    // 📌 Texte explicatif
                    Text("Scannez gratuitement vos produits pour découvrir leurs informations nutritionnelles")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 10)

                    Spacer()
                    
                    // 📌 Bouton secondaire pour les options de compte (discret)
                    Button(action: {
                        showAccountOptions.toggle()
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                                .font(.system(size: 20))
                            Text("Options de compte")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(Color(hex: "156585"))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(25)
                        .shadow(radius: 2)
                    }
                    .padding(.bottom, 30)
                }
            }
            .sheet(isPresented: $showAccountOptions) {
                AccountOptionsView()
            }
        }
    }
}

// 📌 Vue séparée pour les options de compte (dans une sheet)
struct AccountOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "C0DDF9").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("Options de compte")
                        .font(.custom("ChauPhilomeneOne-Regular", size: 24))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 20)
                    
                    Text("Créez un compte pour sauvegarder vos produits et gérer votre inventaire complet")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Bouton Créer un compte
                    NavigationLink(destination: RegisterView()) {
                        Text("CRÉER UN COMPTE")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 24))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "689FA7"))
                            .foregroundColor(.black)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 30)
                    
                    // Bouton J'ai déjà un compte
                    NavigationLink(destination: LoginView()) {
                        Text("J'AI DÉJÀ UN COMPTE")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 24))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "C4D3D5"))
                            .foregroundColor(Color(hex: "156585"))
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    Button("Continuer sans compte") {
                        dismiss()
                    }
                    .foregroundColor(.gray)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WelcomeView()
}


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
                    CustomSecureField(placeholder: "Mot de passe*", text: $password, isPasswordVisible: $isPasswordVisible)

                    Button(action: {
                        print("Mot de passe oublié ?")
                    }) {
                        Text("Mot de passe oublié ?")
                            .foregroundColor(.blue)
                            .underline()
                            .padding(.top, 10)
                    }

                    Spacer()

                    // 🔹 Bouton CONTINUER
                    Button(action: {
                        viewModel.login(username: username, password: password) { success in
                            if success {
                                replaceRootView(with: InventaireView())
                            }
                        }
                    }) {
                        Text("CONTINUER")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 28))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "689FA7"))
                            .foregroundColor(.black)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 30)

                }
            }
            
            .alert("Erreur", isPresented: $viewModel.showErrorAlert, actions: {
                Button("OK", role: .cancel) {}
            }, message: {
                Text(viewModel.errorMessage ?? "Une erreur est survenue")
            })
            
        }
        .hideKeyboardOnTap()
    }
}




#Preview {
    LoginView()
}

import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var birthDate = Date()
    @State private var selectedGender = "Homme"
    @State private var isPasswordVisible = false
    @State private var navigateToInventory = false

    let genders = ["Homme", "Femme", "Autres"]

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

                        Text("INSCRIPTION")
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

                    HStack(spacing: 10) { // 🔹 Espacement ajusté pour un meilleur rendu
                        CustomTextField(placeholder: "Nom*", text: $lastName)
                            .frame(maxWidth: .infinity) // 🔹 Prend toute la largeur disponible
                        
                        
                        CustomTextField(placeholder: "Prénom*", text: $firstName)
                            .frame(maxWidth: .infinity) // 🔹 Prend toute la largeur disponible
                    }
                    


                    CustomTextField(placeholder: "Email*", text: $email)
                    CustomSecureField(placeholder: "Mot de passe*", text: $password, isPasswordVisible: $isPasswordVisible)
                    CustomTextField(placeholder: "Identifiant de connexion*", text: $username)
                        .padding(.bottom, 8)
                    CustomDatePicker(placeholder: "Date de Naissance*", date: $birthDate)
                        .padding(.bottom, 10) // 🔹 Garde un espace en bas

 


                    // 🔹 Sélection du genre
                    HStack {
                        ForEach(genders, id: \.self) { gender in
                            Button(action: {
                                selectedGender = gender
                            }) {
                                HStack {
                                    Circle()
                                        .strokeBorder(Color.black, lineWidth: 2)
                                        .background(Circle().fill(selectedGender == gender ? Color.black : Color.clear))
                                        .frame(width: 20, height: 20)
                                    Text(gender)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)

                    Spacer()

                    // 🔹 Bouton CONTINUER
                    Button(action: {
                        viewModel.register(firstName: firstName, lastName: lastName, email: email, username: username, password: password, birthDate: birthDate, gender: selectedGender) { success in
                            if success {
                                navigateToInventory = true
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
            .navigationDestination(isPresented: $navigateToInventory) {
                InventaireView()
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
    RegisterView()
}

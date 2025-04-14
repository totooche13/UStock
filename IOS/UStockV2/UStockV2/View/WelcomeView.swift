import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "C0DDF9")
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    Spacer()
                    Spacer()

                    // Logo
                    Image("ustock_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)

                    Spacer()
                    Spacer()

                    // 📌 Bouton "C'EST PARTI !"
                    NavigationLink(destination: RegisterView()) {
                        Text("C'EST PARTI !")
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

                    // 📌 Bouton "J'AI DÉJÀ UN COMPTE" avec NavigationLink
                    NavigationLink(destination: LoginView()) {
                        Text("J'AI DÉJÀ UN COMPTE")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 28))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "C4D3D5"))
                            .foregroundColor(Color(hex: "156585"))
                            .cornerRadius(20)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 10)

                    Spacer()
                        .frame(height: 30)
                }
            }
        }
    }
}


#Preview {
    WelcomeView()
}

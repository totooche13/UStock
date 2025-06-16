import SwiftUI

struct CustomSecureField: View {
    var placeholder: String
    @Binding var text: String
    @Binding var isPasswordVisible: Bool
    var isDisabled: Bool = false

    var body: some View {
        HStack {
            if isPasswordVisible {
                TextField(placeholder, text: $text)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
            } else {
                SecureField(placeholder, text: $text)
            }

            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPasswordVisible.toggle()
                }
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(isDisabled ? .gray : .black)
                    .font(.title2)
                    .opacity(isDisabled ? 0.5 : 1.0)
            }
            .disabled(isDisabled)
        }
        .padding(15)
        .background(
            isDisabled ?
                Color(hex: "689FA7").opacity(0.5) :
                Color(hex: "689FA7")
        )
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.clear, lineWidth: 1)
        )
        .foregroundColor(isDisabled ? .gray : .black)
        .padding(.horizontal, 30)
        .disabled(isDisabled)
    }
}

// Version avec validation de mot de passe
struct ValidatedCustomSecureField: View {
    var placeholder: String
    @Binding var text: String
    @Binding var isPasswordVisible: Bool
    var isDisabled: Bool = false
    var validation: (String) -> Bool = { _ in true }
    var errorMessage: String = ""
    
    @State private var isValid = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                if isPasswordVisible {
                    TextField(placeholder, text: $text)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField(placeholder, text: $text)
                }

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPasswordVisible.toggle()
                    }
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(isDisabled ? .gray : .black)
                        .font(.title2)
                        .opacity(isDisabled ? 0.5 : 1.0)
                }
                .disabled(isDisabled)
            }
            .padding(15)
            .background(
                isDisabled ?
                    Color(hex: "689FA7").opacity(0.5) :
                    (isValid ? Color(hex: "689FA7") : Color.red.opacity(0.1))
            )
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        isValid ? Color.clear : Color.red.opacity(0.5),
                        lineWidth: 1
                    )
            )
            .foregroundColor(isDisabled ? .gray : .black)
            .padding(.horizontal, 30)
            .disabled(isDisabled)
            .onChange(of: text) { _, newValue in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isValid = validation(newValue)
                }
            }
            
            if !isValid && !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 35)
                    .transition(.opacity)
            }
            
            // Indicateur de force du mot de passe (optionnel)
            if !text.isEmpty && placeholder.lowercased().contains("mot de passe") {
                PasswordStrengthIndicator(password: text)
                    .padding(.horizontal, 35)
            }
        }
    }
}

// Composant d'indicateur de force du mot de passe
struct PasswordStrengthIndicator: View {
    let password: String
    
    private var strength: PasswordStrength {
        return evaluatePasswordStrength(password)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                ForEach(0..<4) { index in
                    Rectangle()
                        .frame(height: 3)
                        .foregroundColor(
                            index < strength.level ? strength.color : Color.gray.opacity(0.3)
                        )
                }
            }
            
            Text(strength.description)
                .font(.caption2)
                .foregroundColor(strength.color)
        }
        .animation(.easeInOut(duration: 0.3), value: strength.level)
    }
    
    private func evaluatePasswordStrength(_ password: String) -> PasswordStrength {
        let length = password.count
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasNumbers = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChars = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
        var score = 0
        
        if length >= 8 { score += 1 }
        if hasLowercase && hasUppercase { score += 1 }
        if hasNumbers { score += 1 }
        if hasSpecialChars { score += 1 }
        
        switch score {
        case 0...1:
            return PasswordStrength(level: 1, color: .red, description: "Faible")
        case 2:
            return PasswordStrength(level: 2, color: .orange, description: "Moyen")
        case 3:
            return PasswordStrength(level: 3, color: .yellow, description: "Bon")
        case 4:
            return PasswordStrength(level: 4, color: .green, description: "Fort")
        default:
            return PasswordStrength(level: 0, color: .gray, description: "")
        }
    }
}

struct PasswordStrength {
    let level: Int
    let color: Color
    let description: String
}

#Preview {
    VStack {
        CustomSecureField(
            placeholder: "Mot de passe",
            text: .constant("password123"),
            isPasswordVisible: .constant(false)
        )
        
        CustomSecureField(
            placeholder: "Disabled",
            text: .constant(""),
            isPasswordVisible: .constant(false),
            isDisabled: true
        )
        
        ValidatedCustomSecureField(
            placeholder: "Mot de passe avec validation",
            text: .constant("Test123!"),
            isPasswordVisible: .constant(false),
            validation: { password in
                password.count >= 8
            },
            errorMessage: "Le mot de passe doit contenir au moins 8 caractères"
        )
    }
    .padding()
}

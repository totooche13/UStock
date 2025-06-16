import SwiftUI

struct CustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isDisabled: Bool = false
    
    var body: some View {
        TextField(placeholder, text: $text)
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
            .autocapitalization(.none)  // Éviter la capitalisation automatique
            .disableAutocorrection(true)  // Désactiver l'autocorrection
            .textInputAutocapitalization(.never)  // iOS 15+
    }
}

// Version avec validation en temps réel
struct ValidatedCustomTextField: View {
    var placeholder: String
    @Binding var text: String
    var isDisabled: Bool = false
    var validation: (String) -> Bool = { _ in true }
    var errorMessage: String = ""
    
    @State private var isValid = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            TextField(placeholder, text: $text)
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
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
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
        }
    }
}

#Preview {
    VStack {
        CustomTextField(placeholder: "Email", text: .constant(""))
        CustomTextField(placeholder: "Disabled", text: .constant(""), isDisabled: true)
        
        ValidatedCustomTextField(
            placeholder: "Email avec validation",
            text: .constant("test@example.com"),
            validation: { email in
                email.contains("@") && email.contains(".")
            },
            errorMessage: "Format d'email invalide"
        )
    }
    .padding()
}

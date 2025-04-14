import SwiftUI

extension View {
    /// Permet de cacher le clavier en cliquant en dehors des champs de texte
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}


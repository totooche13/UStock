import SwiftUI

class RegisterViewModel: ObservableObject {
    @Published var isRegistered = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    

    func register(firstName: String, lastName: String, email: String, username: String, password: String, birthDate: Date, gender: String, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://api.ustock.pro:8443/users/register")!
        /// let url = URL(string: "https://apiustock.ddnsfree.com:8443/users/register")!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let formattedBirthDate = formatter.string(from: birthDate)
        
        let body: [String: Any?] = [
            "first_name": firstName,
            "last_name": lastName,
            "email": email,
            "username": username,
            "birth_date": formattedBirthDate,
            "gender": gender,
            "password": password,
            "family_id": nil // 🔹 Ajout de family_id à NULL
        ]
        
        print("📡 Envoi de la requête avec les données suivantes :")
        print("first_name: \(firstName), last_name: \(lastName), email: \(email)")
        print("username: \(username), password: \(password)")
        print("birth_date: \(birthDate), gender: \(gender), family_id: nil")


        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            DispatchQueue.main.async {
                self.errorMessage = "Erreur de format des données"
                self.showErrorAlert = true
                completion(false)
            }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Erreur réseau : \(error.localizedDescription)"
                    self.showErrorAlert = true
                    completion(false)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Réponse HTTP : \(httpResponse.statusCode)")

                    if let data = data, let responseBody = String(data: data, encoding: .utf8) {
                        print("📡 Réponse du serveur : \(responseBody)")
                    }

                    if httpResponse.statusCode == 200 {
                        self.isRegistered = true
                        completion(true)
                    } else {
                        self.errorMessage = "Erreur lors de l'inscription"
                        self.showErrorAlert = true
                        completion(false)
                    }
                }
            }
        }.resume()

    }
}

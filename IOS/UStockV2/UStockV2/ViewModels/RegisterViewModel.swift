import SwiftUI

class RegisterViewModel: ObservableObject {
    @Published var isRegistered = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    

    func register(firstName: String, lastName: String, email: String, username: String, password: String, gender: String, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://api.ustock.pro/users/register")!
        
        // 🔹 MODIFICATION : Suppression de birth_date
        let body: [String: Any?] = [
            "first_name": firstName,
            "last_name": lastName,
            "email": email,
            "username": username,
            "gender": gender,
            "password": password,
            "family_id": nil
        ]
        
        print("📡 Envoi de la requête avec les données suivantes :")
        print("first_name: \(firstName), last_name: \(lastName), email: \(email)")
        print("username: \(username), password: \(password)")
        print("gender: \(gender), family_id: nil")

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
                        print("✅ Inscription réussie, connexion automatique en cours...")
                        // Connexion automatique après inscription
                        self.autoLogin(username: username, password: password, completion: completion)
                    } else {
                        self.errorMessage = "Erreur lors de l'inscription"
                        self.showErrorAlert = true
                        completion(false)
                    }
                }
            }
        }.resume()
    }
    
    // Connexion automatique après inscription
    private func autoLogin(username: String, password: String, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://api.ustock.pro/users/login")!
        let body: [String: String] = ["username": username, "password": password]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            DispatchQueue.main.async {
                self.errorMessage = "Erreur de format des données de connexion"
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
                    print("❌ Erreur lors de la connexion automatique : \(error.localizedDescription)")
                    self.errorMessage = "Inscription réussie mais erreur de connexion automatique"
                    self.showErrorAlert = true
                    completion(false)
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    if let data = data {
                        do {
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("📡 Réponse connexion automatique : \(responseString)")
                            }
                            
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let accessToken = json["access_token"] as? String,
                               let tokenType = json["token_type"] as? String {
                                
                                let fullToken = "\(tokenType) \(accessToken)"
                                AuthManager.shared.saveToken(fullToken)
                                
                                print("✅ Connexion automatique réussie, token sauvegardé")
                                self.isRegistered = true
                                self.errorMessage = nil
                                completion(true)
                            } else {
                                print("❌ Impossible de récupérer le token lors de la connexion automatique")
                                self.errorMessage = "Inscription réussie mais impossible de vous connecter automatiquement"
                                self.showErrorAlert = true
                                completion(false)
                            }
                        } catch {
                            print("❌ Erreur de désérialisation lors de la connexion automatique : \(error)")
                            self.errorMessage = "Inscription réussie mais erreur de connexion automatique"
                            self.showErrorAlert = true
                            completion(false)
                        }
                    } else {
                        print("❌ Aucune donnée reçue lors de la connexion automatique")
                        self.errorMessage = "Inscription réussie mais erreur de connexion automatique"
                        self.showErrorAlert = true
                        completion(false)
                    }
                } else {
                    print("❌ Erreur HTTP lors de la connexion automatique")
                    self.errorMessage = "Inscription réussie mais erreur de connexion automatique"
                    self.showErrorAlert = true
                    completion(false)
                }
            }
        }.resume()
    }
}

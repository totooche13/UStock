import SwiftUI

class LoginViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    
    func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
        let url = URL(string: "https://api.ustock.totooche.fr:8443/users/login")!
        let body: [String: String] = ["username": username, "password": password]

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

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    // Traiter la réponse JSON pour obtenir le token
                    if let data = data {
                        do {
                            // Affichage des données brutes pour le débogage
                            if let responseString = String(data: data, encoding: .utf8) {
                                print("Réponse brute du serveur : \(responseString)")
                            }
                            
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let accessToken = json["access_token"] as? String,
                               let tokenType = json["token_type"] as? String {
                                
                                // Stocker le token via AuthManager
                                let fullToken = "\(tokenType) \(accessToken)"
                                AuthManager.shared.saveToken(fullToken)
                                
                                self.isAuthenticated = true
                                self.errorMessage = nil
                                completion(true)
                            } else {
                                self.errorMessage = "Authentification réussie mais impossible de récupérer le token"
                                self.showErrorAlert = true
                                completion(false)
                            }
                        } catch {
                            print("Erreur de désérialisation : \(error)")
                            self.errorMessage = "Erreur lors de la lecture de la réponse"
                            self.showErrorAlert = true
                            completion(false)
                        }
                    } else {
                        self.errorMessage = "Aucune donnée reçue du serveur"
                        self.showErrorAlert = true
                        completion(false)
                    }
                } else {
                    self.errorMessage = "Identifiants incorrects"
                    self.showErrorAlert = true
                    completion(false)
                }
            }
        }.resume()
    }
}

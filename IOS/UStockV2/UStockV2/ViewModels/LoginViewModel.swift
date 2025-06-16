import SwiftUI
import Foundation

class LoginViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    @Published var isLoading = false  // Nouveau: indicateur de chargement
    
    // URLSession avec configuration personnalisée pour timeout
    private var urlSession: URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }
    
    func login(username: String, password: String, completion: @escaping (Bool) -> Void) {
        // Éviter les appels multiples
        guard !isLoading else {
            print("⚠️ Tentative de connexion déjà en cours, ignorer")
            return
        }
        
        // Validation des entrées
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            DispatchQueue.main.async {
                self.errorMessage = "Veuillez remplir tous les champs"
                self.showErrorAlert = true
                completion(false)
            }
            return
        }
        
        // Démarrer le chargement
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
            self.showErrorAlert = false
        }
        
        print("🚀 Début de la tentative de connexion pour: \(username)")
        
        let url = URL(string: "https://api.ustock.pro:8443/users/login")!
        let body: [String: String] = [
            "username": username.trimmingCharacters(in: .whitespacesAndNewlines),
            "password": password
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            DispatchQueue.main.async {
                self.isLoading = false
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
        request.timeoutInterval = 30.0

        print("📡 Envoi de la requête vers: \(url)")

        urlSession.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false  // Toujours remettre à false
            }
            
            // Gestion détaillée des erreurs réseau
            if let error = error {
                let nsError = error as NSError
                print("❌ Erreur réseau détaillée: \(error)")
                print("❌ Code d'erreur: \(nsError.code)")
                print("❌ Domaine: \(nsError.domain)")
                
                DispatchQueue.main.async {
                    switch nsError.code {
                    case NSURLErrorTimedOut:
                        self.errorMessage = "La connexion a expiré. Vérifiez votre connexion internet."
                    case NSURLErrorNotConnectedToInternet:
                        self.errorMessage = "Aucune connexion internet détectée."
                    case NSURLErrorNetworkConnectionLost:
                        self.errorMessage = "Connexion réseau perdue."
                    case NSURLErrorCannotFindHost:
                        self.errorMessage = "Impossible de joindre le serveur."
                    case NSURLErrorCannotConnectToHost:
                        self.errorMessage = "Impossible de se connecter au serveur."
                    case NSURLErrorSecureConnectionFailed:
                        self.errorMessage = "Erreur de sécurité de la connexion."
                    default:
                        self.errorMessage = "Erreur réseau : \(error.localizedDescription)"
                    }
                    
                    self.showErrorAlert = true
                    completion(false)
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Réponse HTTP invalide")
                DispatchQueue.main.async {
                    self.errorMessage = "Réponse serveur invalide"
                    self.showErrorAlert = true
                    completion(false)
                }
                return
            }

            guard let data = data else {
                print("❌ Aucune donnée reçue")
                DispatchQueue.main.async {
                    self.errorMessage = "Aucune donnée reçue du serveur"
                    self.showErrorAlert = true
                    completion(false)
                }
                return
            }

            // Log pour debug
            if let responseString = String(data: data, encoding: .utf8) {
                print("📦 Réponse serveur (status \(httpResponse.statusCode)): \(responseString)")
            }

            DispatchQueue.main.async {
                self.handleResponse(httpResponse: httpResponse, data: data, completion: completion)
            }
        }.resume()
    }
    
    private func handleResponse(httpResponse: HTTPURLResponse, data: Data, completion: @escaping (Bool) -> Void) {
        switch httpResponse.statusCode {
        case 200:
            // Succès
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accessToken = json["access_token"] as? String,
                   let tokenType = json["token_type"] as? String {
                    
                    let fullToken = "\(tokenType) \(accessToken)"
                    AuthManager.shared.saveToken(fullToken)
                    
                    print("✅ Connexion réussie, token sauvegardé")
                    
                    self.isAuthenticated = true
                    self.errorMessage = nil
                    completion(true)
                } else {
                    print("❌ Format de réponse JSON invalide")
                    self.errorMessage = "Format de réponse invalide"
                    self.showErrorAlert = true
                    completion(false)
                }
            } catch {
                print("❌ Erreur parsing JSON: \(error)")
                self.errorMessage = "Erreur lors de l'analyse de la réponse"
                self.showErrorAlert = true
                completion(false)
            }
            
        case 401:
            // Identifiants incorrects
            print("❌ Identifiants incorrects (401)")
            self.errorMessage = "Identifiants incorrects"
            self.showErrorAlert = true
            completion(false)
            
        case 422:
            // Erreur de validation
            print("❌ Erreur de validation (422)")
            self.errorMessage = "Données de connexion invalides"
            self.showErrorAlert = true
            completion(false)
            
        case 500...599:
            // Erreur serveur
            print("❌ Erreur serveur (\(httpResponse.statusCode))")
            self.errorMessage = "Le serveur rencontre des difficultés. Réessayez plus tard."
            self.showErrorAlert = true
            completion(false)
            
        default:
            // Autres erreurs
            print("❌ Erreur HTTP non gérée: \(httpResponse.statusCode)")
            self.errorMessage = "Erreur inattendue (Code: \(httpResponse.statusCode))"
            self.showErrorAlert = true
            completion(false)
        }
    }
    
    func resetState() {
        isLoading = false
        errorMessage = nil
        showErrorAlert = false
        isAuthenticated = false
    }
}

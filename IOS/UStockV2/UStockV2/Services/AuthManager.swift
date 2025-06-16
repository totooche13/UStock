import Foundation
import Network

class AuthManager {
    static let shared = AuthManager()
    
    private let tokenKey = "authToken"
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "AuthManager")
    
    // État de la connexion réseau
    @Published var isConnected = true
    
    private init() {
        startNetworkMonitoring()
    }
    
    // MARK: - Gestion du token
    
    // Sauvegarder le token avec validation
    func saveToken(_ token: String) {
        guard !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ Tentative de sauvegarde d'un token vide")
            return
        }
        
        UserDefaults.standard.set(token, forKey: tokenKey)
        print("✅ Token sauvegardé avec succès")
        
        // Synchroniser immédiatement
        UserDefaults.standard.synchronize()
    }
    
    // Récupérer le token avec validation
    func getToken() -> String? {
        let token = UserDefaults.standard.string(forKey: tokenKey)
        
        // Vérifier que le token n'est pas vide
        if let token = token, !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return token
        }
        
        return nil
    }
    
    // Supprimer le token (déconnexion)
    func removeToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.synchronize()
        print("🗑️ Token supprimé")
    }
    
    // MARK: - Validation du token
    
    // Vérifier si le token est valide avec timeout et retry
    func validateToken(completion: @escaping (Bool) -> Void) {
        guard let token = getToken() else {
            print("❌ Aucun token trouvé")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        // Vérifier la connexion réseau d'abord
        guard isConnected else {
            print("❌ Pas de connexion réseau pour valider le token")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        validateTokenWithRetry(token: token, retryCount: 3, completion: completion)
    }
    
    private func validateTokenWithRetry(token: String, retryCount: Int, completion: @escaping (Bool) -> Void) {
        guard retryCount > 0 else {
            print("❌ Échec de validation du token après toutes les tentatives")
            DispatchQueue.main.async {
                completion(false)
            }
            return
        }
        
        let url = URL(string: "https://api.ustock.pro:8443/users/me")!
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15.0
        
        print("🔍 Validation du token (tentative \(4 - retryCount))")
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        let session = URLSession(configuration: config)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                let nsError = error as NSError
                print("❌ Erreur lors de la validation: \(error.localizedDescription)")
                
                // Retry pour certaines erreurs réseau
                if nsError.code == NSURLErrorTimedOut ||
                   nsError.code == NSURLErrorNetworkConnectionLost ||
                   nsError.code == NSURLErrorNotConnectedToInternet {
                    
                    DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                        self?.validateTokenWithRetry(token: token, retryCount: retryCount - 1, completion: completion)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Réponse HTTP invalide lors de la validation")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            let isValid = httpResponse.statusCode == 200
            print(isValid ? "✅ Token valide" : "❌ Token invalide (status: \(httpResponse.statusCode))")
            
            // Si le token est invalide (401, 403), le supprimer
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                self?.removeToken()
            }
            
            DispatchQueue.main.async {
                completion(isValid)
            }
        }.resume()
    }
    
    // MARK: - Monitoring réseau
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                print("🌐 État réseau: \(path.status == .satisfied ? "Connecté" : "Déconnecté")")
            }
        }
        monitor.start(queue: queue)
    }
    
    // MARK: - Utilitaires
    
    // Vérifier si l'utilisateur est connecté (token présent et potentiellement valide)
    func isLoggedIn() -> Bool {
        return getToken() != nil
    }
    
    // Nettoyer toutes les données d'authentification
    func clearAllAuthData() {
        removeToken()
        // Ici vous pourriez ajouter d'autres nettoyages si nécessaire
        print("🧹 Toutes les données d'authentification supprimées")
    }
    
    // Rafraîchir le token (si votre API le supporte)
    func refreshToken(completion: @escaping (Bool) -> Void) {
        // Cette méthode peut être implémentée si votre API supporte le refresh des tokens
        // Pour l'instant, on validate simplement le token existant
        validateToken(completion: completion)
    }
}

// MARK: - Extensions pour faciliter l'utilisation

extension AuthManager {
    // Méthode pratique pour les vues SwiftUI
    func validateTokenAsync() async -> Bool {
        await withCheckedContinuation { continuation in
            validateToken { isValid in
                continuation.resume(returning: isValid)
            }
        }
    }
}

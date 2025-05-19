//
//  AuthManager.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 18/04/2025.
//


import Foundation

class AuthManager {
    static let shared = AuthManager()
    
    private let tokenKey = "authToken"
    
    // Sauvegarder le token
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    // Récupérer le token
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    // Supprimer le token (déconnexion)
    func removeToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
    
    // Vérifier si le token est valide
    func validateToken(completion: @escaping (Bool) -> Void) {
        guard let token = getToken() else {
            completion(false)
            return
        }
        
        let url = URL(string: "https://api.ustock.totooche.fr:8443/users/me")!
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { _, response, _ in
            let isValid = (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async {
                completion(isValid)
            }
        }.resume()
    }
}
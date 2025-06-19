import Foundation
import Combine

class ProductService {
    static let shared = ProductService()
    
    private let baseURL = "https://api.ustock.pro:8443/products/"
    private let stockURL = "https://api.ustock.pro:8443/stocks/"
    
    private init() {}
    
    // MARK: - Fetch Product by Barcode
    
    func fetchProduct(barcode: String, completion: @escaping (Product?) -> Void) {
        guard let url = URL(string: "\(baseURL)\(barcode)") else {
            print("❌ Erreur : URL invalide")
            completion(nil)
            return
        }

        print("🔍 Recherche du produit avec code-barres: \(barcode)")
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("❌ Erreur requête GET : \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                print("❌ Aucune réponse du serveur")
                completion(nil)
                return
            }

            if httpResponse.statusCode == 404 {
                print("🔍 Produit non trouvé (404)")
                completion(nil)
                return
            }

            if httpResponse.statusCode != 200 {
                print("❌ Erreur serveur: \(httpResponse.statusCode)")
                completion(nil)
                return
            }

            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 Données reçues: \(responseString)")
                }
                
                let product = try JSONDecoder().decode(Product.self, from: data)
                print("✅ Produit trouvé: \(product.product_name)")
                DispatchQueue.main.async {
                    completion(product)
                }
            } catch {
                print("❌ Erreur de parsing JSON : \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    // MARK: - Create Product
    
    func createProduct(barcode: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)?barcode=\(barcode)") else {
            print("❌ Erreur : URL invalide pour création produit")
            completion(false)
            return
        }

        print("📝 Création d'un nouveau produit avec code-barres: \(barcode)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur création produit : \(error.localizedDescription)")
                completion(false)
                return
            }

            guard let data = data, let httpResponse = response as? HTTPURLResponse else {
                print("❌ Aucune réponse du serveur pour création")
                completion(false)
                return
            }

            if httpResponse.statusCode == 200 {
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 Réponse création produit: \(responseString)")
                }
                print("✅ Produit créé avec succès")
                completion(true)
            } else {
                print("❌ Échec création produit, code HTTP : \(httpResponse.statusCode)")
                completion(false)
            }
        }
        task.resume()
    }
    
    // MARK: - Add Product to Stock
    
    // Dans ProductService.swift - Méthode addProductToStock mise à jour

    func addProductToStock(productId: Int, quantity: Int, expirationDate: Date, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: stockURL) else {
            print("❌ Erreur : URL invalide pour ajout au stock")
            completion(false)
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("❌ Erreur : Token d'authentification manquant")
            completion(false)
            return
        }
        
        print("📌 Ajout d'un produit (ID: \(productId)) au stock")
        print("🔑 Token utilisé: \(token)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        // 🔹 NOUVEAU : Utilisation du formatter API pour envoyer la date
        let formattedDate = expirationDate.apiString
        
        let body: [String: Any] = [
            "product_id": productId,
            "quantity": quantity,
            "expiration_date": formattedDate // Format yyyy-MM-dd pour l'API
        ]
        
        print("📦 Données à envoyer: \(body)")
        print("📅 Date formatée pour l'API: \(formattedDate)")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            print("❌ Erreur sérialisation JSON : \(error.localizedDescription)")
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau ajout stock : \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Aucune réponse du serveur pour ajout stock")
                completion(false)
                return
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("📦 Réponse ajout stock: \(responseString)")
            }
            
            if httpResponse.statusCode == 200 {
                print("✅ Produit ajouté au stock avec succès")
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                print("❌ Échec ajout stock, code HTTP : \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
        task.resume()
    }
    
    // MARK: - Convenience method to fetch or create product
    
    func fetchOrCreateProduct(barcode: String, completion: @escaping (Result<Product, Error>) -> Void) {
        print("🔄 Début du processus fetch-or-create pour code-barres: \(barcode)")
        
        // Étape 1: Essayer de récupérer le produit
        fetchProduct(barcode: barcode) { product in
            if let product = product {
                // Produit trouvé, on le retourne
                print("✅ Produit existant trouvé directement")
                completion(.success(product))
            } else {
                // Produit non trouvé, on essaie de le créer
                print("🔍 Produit non trouvé, tentative de création...")
                
                // Étape 2: Créer le produit
                self.createProduct(barcode: barcode) { success in
                    if success {
                        print("✅ Produit créé, récupération des informations complètes...")
                        
                        // Étape 3: Récupérer le produit nouvellement créé
                        self.fetchProduct(barcode: barcode) { newProduct in
                            if let newProduct = newProduct {
                                print("✅ Nouveau produit récupéré avec succès")
                                completion(.success(newProduct))
                            } else {
                                print("❌ Impossible de récupérer le produit créé")
                                let error = NSError(domain: "ProductService", code: 500,
                                                  userInfo: [NSLocalizedDescriptionKey: "Impossible de récupérer le produit après création"])
                                completion(.failure(error))
                            }
                        }
                    } else {
                        print("❌ Échec de la création du produit")
                        let error = NSError(domain: "ProductService", code: 500,
                                          userInfo: [NSLocalizedDescriptionKey: "Échec de la création du produit"])
                        completion(.failure(error))
                    }
                }
            }
        }
    }
}

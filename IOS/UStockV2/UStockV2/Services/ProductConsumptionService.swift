import Foundation

enum ProductStatus: String, Codable {
    case consumed = "consumed"
    case wasted = "wasted"
}

struct ConsumptionRequest: Codable {
    let stock_id: Int
    let quantity: Int
    let status: String
}

struct ConsumptionStatTotal: Codable {
    let consumed_count: Int
    let wasted_count: Int
    let total_count: Int
    let waste_rate: Double
}

struct ConsumptionStats: Codable {
    let total: ConsumptionStatTotal
    let current_month: ConsumptionStatTotal
}

class ProductConsumptionService {
    static let shared = ProductConsumptionService()
    
    private let baseURL = "https://api.ustock.totooche.fr:8443/consumption/"
    
    private init() {}
    
    func markProductStatus(stockId: Int, quantity: Int, status: ProductStatus, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: baseURL) else {
            print("❌ Erreur : URL invalide")
            completion(false)
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("❌ Erreur : Token d'authentification manquant")
            completion(false)
            return
        }
        
        print("📤 Envoi de la requête - stockId: \(stockId), quantity: \(quantity), status: \(status.rawValue)")
        
        let request = ConsumptionRequest(
            stock_id: stockId,
            quantity: quantity,
            status: status.rawValue
        )
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(token, forHTTPHeaderField: "Authorization")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            print("❌ Erreur d'encodage JSON : \(error.localizedDescription)")
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            if let error = error {
                print("❌ Erreur réseau : \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Aucune réponse du serveur")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            if httpResponse.statusCode == 200 {
                print("✅ Produit marqué comme \(status.rawValue) avec succès")
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                print("❌ Échec du marquage du produit, code HTTP : \(httpResponse.statusCode)")
                if let data = data, let errorString = String(data: data, encoding: .utf8) {
                    print("Détails de l'erreur : \(errorString)")
                }
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }.resume()
    }
    
    func getStats(completion: @escaping (Result<ConsumptionStats, Error>) -> Void) {
        guard let url = URL(string: baseURL + "stats") else {
            completion(.failure(NSError(domain: "ProductConsumptionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL invalide"])))
            return
        }
        
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            completion(.failure(NSError(domain: "ProductConsumptionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Token d'authentification manquant"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "ProductConsumptionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Aucune donnée reçue"])))
                }
                return
            }
            
            do {
                let stats = try JSONDecoder().decode(ConsumptionStats.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(stats))
                }
            } catch {
                print("❌ Erreur de décodage : \(error)")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Réponse du serveur : \(responseString)")
                }
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}

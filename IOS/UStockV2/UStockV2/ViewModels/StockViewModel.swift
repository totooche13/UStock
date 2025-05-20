import SwiftUI
import Combine

// Structure pour parser les données du produit
struct ProductDTO: Codable {
    let id: Int
    let barcode: String
    let product_name: String
    let brand: String?
    let content_size: String?
    let nutriscore: String?
    let image_url: String?
}

// Structure pour parser les données du stock
struct StockDTO: Codable, Identifiable {
    let id: Int
    let quantity: Int
    let expiration_date: String
    let product: ProductDTO
}

class StockViewModel: ObservableObject {
    @Published var stocks: [Produit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showErrorAlert = false
    @Published var showSuccessMessage = false
    @Published var successMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    // Token d'authentification
    var authToken: String?
    
    init() {
        // Récupérer le token depuis UserDefaults
        self.authToken = UserDefaults.standard.string(forKey: "authToken")
        print("Token récupéré dans StockViewModel : \(String(describing: authToken))")
    }
    
    func fetchStocks() {
        guard let token = authToken else {
            self.errorMessage = "Vous devez être connecté pour accéder à cette fonctionnalité"
            self.showErrorAlert = true
            return
        }
        
        isLoading = true
        
        let url = URL(string: "https://api.ustock.pro:8443/stocks/")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        print("🔄 Récupération des stocks avec token: \(token)")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ Erreur réseau : \(error.localizedDescription)")
                    self.errorMessage = "Erreur lors de la récupération des produits: \(error.localizedDescription)"
                    self.showErrorAlert = true
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Pas de réponse HTTP")
                    self.errorMessage = "Pas de réponse du serveur"
                    self.showErrorAlert = true
                    return
                }
                
                guard let data = data else {
                    print("❌ Données vides")
                    self.errorMessage = "Aucune donnée reçue"
                    self.showErrorAlert = true
                    return
                }
                
                // Log des données brutes
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📦 Données reçues: \(responseString)")
                }
                
                if httpResponse.statusCode == 200 {
                    do {
                        let decoder = JSONDecoder()
                        let stocksDTO = try decoder.decode([StockDTO].self, from: data)
                        
                        print("✅ \(stocksDTO.count) produits dans le stock")
                        
                        let produits = stocksDTO.map { stockDTO -> Produit in
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd"
                            
                            // Calculer les jours restants
                            let expirationDate = dateFormatter.date(from: stockDTO.expiration_date) ?? Date()
                            let joursRestants = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                            
                            // Formater la date pour l'affichage
                            dateFormatter.dateFormat = "dd-MM-yy"
                            let formattedDate = dateFormatter.string(from: expirationDate)
                            
                            return Produit(
                                nom: stockDTO.product.product_name,
                                peremption: formattedDate,
                                joursRestants: joursRestants,
                                quantite: stockDTO.quantity,
                                image: "",  // Champ vide car nous utilisons directement l'URL d'image
                                stockId: stockDTO.id,
                                productDetails: ProductDetails(
                                    barcode: stockDTO.product.barcode,
                                    brand: stockDTO.product.brand ?? "",
                                    contentSize: stockDTO.product.content_size ?? "",
                                    nutriscore: stockDTO.product.nutriscore ?? "",
                                    imageUrl: stockDTO.product.image_url ?? ""
                                )
                            )
                        }
                        
                        self.stocks = produits
                    } catch {
                        print("❌ Erreur décodage JSON : \(error)")
                        self.errorMessage = "Erreur lors de la récupération des produits: \(error.localizedDescription)"
                        self.showErrorAlert = true
                    }
                } else {
                    print("❌ Mauvais code HTTP: \(httpResponse.statusCode)")
                    self.errorMessage = "Erreur serveur: \(httpResponse.statusCode)"
                    self.showErrorAlert = true
                }
            }
        }.resume()
    }
    
    // Nouvelle méthode pour supprimer un produit
    func deleteProduct(stockId: Int, completion: @escaping (Bool) -> Void) {
        guard let token = authToken else {
            self.errorMessage = "Vous devez être connecté pour supprimer un produit"
            self.showErrorAlert = true
            completion(false)
            return
        }
        
        isLoading = true
        
        let url = URL(string: "https://api.ustock.pro:8443/stocks/\(stockId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        print("🗑️ Suppression du produit avec stockId: \(stockId)")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let error = error {
                    print("❌ Erreur réseau : \(error.localizedDescription)")
                    self.errorMessage = "Erreur lors de la suppression du produit: \(error.localizedDescription)"
                    self.showErrorAlert = true
                    completion(false)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ Pas de réponse HTTP")
                    self.errorMessage = "Pas de réponse du serveur"
                    self.showErrorAlert = true
                    completion(false)
                    return
                }
                
                // Log du statut
                print("🔄 Statut de la réponse: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    // Si la suppression est réussie, on rafraîchit la liste des stocks
                    print("✅ Produit supprimé avec succès!")
                    
                    // Retirer le produit de la liste locale
                    if let index = self.stocks.firstIndex(where: { $0.stockId == stockId }) {
                        self.stocks.remove(at: index)
                    }
                    
                    self.successMessage = "Produit supprimé avec succès"
                    self.showSuccessMessage = true
                    completion(true)
                } else {
                    print("❌ Échec de la suppression, code HTTP: \(httpResponse.statusCode)")
                    
                    if let data = data, let responseString = String(data: data, encoding: .utf8) {
                        print("📦 Réponse d'erreur: \(responseString)")
                    }
                    
                    self.errorMessage = "Erreur lors de la suppression: Code \(httpResponse.statusCode)"
                    self.showErrorAlert = true
                    completion(false)
                }
            }
        }.resume()
    }
}

import Foundation
import SwiftUI

class ScannerViewModel: ObservableObject {
    @Published var scannedCode: String? = nil
    @Published var scannedProduct: Product? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showError = false
    
    // Initialisation standard
    init() {}
    
    // Initialisation avec un produit préchargé
    init(preloadedProduct: Product) {
        self.scannedProduct = preloadedProduct
    }
    
    func fetchProductInfo(barcode: String) {
        isLoading = true
        errorMessage = nil
        
        ProductService.shared.fetchOrCreateProduct(barcode: barcode) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let product):
                    self.scannedProduct = product
                    // 🔹 NOUVEAU : Son de succès lors de la récupération du produit
                    SoundManager.shared.playSuccessSound()
                    SoundManager.shared.triggerSuccessHaptic()
                    print("✅ Produit trouvé avec succès: \(product.product_name)")
                    
                case .failure(let error):
                    self.errorMessage = "Erreur: \(error.localizedDescription)"
                    self.showError = true
                    // 🔹 NOUVEAU : Son d'erreur lors de l'échec
                    SoundManager.shared.playErrorSound()
                    SoundManager.shared.triggerErrorHaptic()
                    print("❌ Erreur lors de la récupération du produit: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func addProductToStock(quantity: Int, expirationDate: Date, completion: @escaping (Bool) -> Void) {
        guard let product = scannedProduct else {
            errorMessage = "Aucun produit scanné"
            showError = true
            // Son d'erreur
            SoundManager.shared.playErrorSound()
            SoundManager.shared.triggerErrorHaptic()
            completion(false)
            return
        }
        
        isLoading = true
        
        ProductService.shared.addProductToStock(
            productId: product.id,
            quantity: quantity,
            expirationDate: expirationDate
        ) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    // 🔹 NOUVEAU : Son de succès lors de l'ajout au stock
                    SoundManager.shared.playSuccessSound()
                    SoundManager.shared.triggerSuccessHaptic()
                    print("✅ Produit ajouté au stock avec succès")
                    completion(true)
                } else {
                    self.errorMessage = "Erreur lors de l'ajout au stock"
                    self.showError = true
                    // 🔹 NOUVEAU : Son d'erreur lors de l'échec d'ajout
                    SoundManager.shared.playErrorSound()
                    SoundManager.shared.triggerErrorHaptic()
                    print("❌ Erreur lors de l'ajout au stock")
                    completion(false)
                }
            }
        }
    }
    
    func nutriscoreColor(_ score: String?) -> Color {
        guard let score = score?.lowercased() else { return .gray }
        
        switch score {
        case "a": return Color(hex: "418241") // Vert foncé
        case "b": return Color(hex: "86BC2B") // Vert clair
        case "c": return Color(hex: "FECB02") // Jaune
        case "d": return Color(hex: "EF8200") // Orange
        case "e": return Color(hex: "E63E11") // Rouge
        default: return .gray
        }
    }
    
    func reset() {
        scannedCode = nil
        scannedProduct = nil
        errorMessage = nil
        showError = false
    }
}

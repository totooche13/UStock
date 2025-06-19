import SwiftUI

struct ProductDetailView: View {
    let produit: Produit
    @State private var quantity: Int
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showDeleteSuccess = false
    
    // Pour le popup de sélection de quantité
    @State private var showQuantityPopup = false
    @State private var selectedAction: String = ""  // "consumed" ou "wasted"
    @State private var popupQuantity: Int = 1
    @State private var showErrorAlert = false
    @State private var errorMessage: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    // ViewModel pour gérer les interactions avec l'API
    @StateObject private var stockViewModel = StockViewModel()
    
    // Initialisation avec la quantité actuelle du produit
    init(produit: Produit) {
        self.produit = produit
        _quantity = State(initialValue: produit.quantite)
    }
    
    var body: some View {
        ZStack {
            // Fond d'écran bleu clair
            Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 15) {
                // Image du produit
                productImageView
                
                // Titre et marque
                VStack(spacing: 5) {
                    Text(produit.nom)
                        .font(.custom("ChauPhilomeneOne-Regular", size: 34))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text("Marque : \(produitBrand)")
                        .font(.title3)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 10)
                
                // Indicateur Nutriscore
                nutriScoreView
                    .padding(.vertical, 10)
                
                // Contrôle de quantité
                quantityControlView
                    .padding(.top, 20)
                
                Spacer()
                
                // Boutons d'action (seulement Jeté/Consommé)
                HStack(spacing: 0) {
                    Button(action: {
                        showDiscardPopup()
                    }) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.title3)
                            Text("JETÉ")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 22))
                                .fontWeight(.bold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.black)
                    }
                    
                    Button(action: {
                        showConsumePopup()
                    }) {
                        HStack {
                            Image(systemName: "fork.knife")
                                .font(.title3)
                            Text("CONSOMMÉ")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 22))
                                .fontWeight(.bold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.black)
                    }
                }
                .cornerRadius(30)
                .shadow(radius: 3)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("Détails du produit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Supprimer de l'inventaire", systemImage: "trash")
                    }
                    .disabled(isDeleting)
                    
                    Button(action: {
                        // Action future pour d'autres options
                    }) {
                        Label("Modifier les détails", systemImage: "pencil")
                    }
                    .disabled(true) // Pour l'instant désactivé
                    
                } label: {
                    ZStack {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "156585")))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(Color(hex: "156585"))
                        }
                    }
                }
                .disabled(isDeleting)
            }
        }
        .alert("Supprimer le produit", isPresented: $showDeleteConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                deleteProduct()
            }
        } message: {
            Text("Voulez-vous vraiment supprimer ce produit de votre inventaire ? Cette action est irréversible.")
        }
        .alert("Produit supprimé", isPresented: $showDeleteSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Le produit a été retiré de votre inventaire avec succès.")
        }
        .alert("Erreur", isPresented: $stockViewModel.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(stockViewModel.errorMessage ?? "Une erreur est survenue")
        }
        .sheet(isPresented: $showQuantityPopup) {
            ZStack {
                // Fond d'écran
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // Titre simple
                    Text(selectedAction == "consumed" ? "Quantité consommée" : "Quantité jetée")
                        .font(.custom("ChauPhilomeneOne-Regular", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 50)
                    
                    // Contrôle de quantité simplifié
                    HStack(spacing: 40) {
                        Button(action: {
                            if popupQuantity > 1 {
                                popupQuantity -= 1
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "689FA7"))
                                    .frame(width: 70, height: 70)
                                
                                Text("-")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        
                        Text("\(popupQuantity)")
                            .font(.system(size: 60, weight: .bold))
                            .frame(minWidth: 80)
                            .foregroundColor(.black)
                        
                        Button(action: {
                            if popupQuantity < produit.quantite {
                                popupQuantity += 1
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "689FA7"))
                                    .frame(width: 70, height: 70)
                                
                                Text("+")
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.vertical, 30)
                    
                    // Quantité disponible (en petit)
                    Text("Disponible: \(produit.quantite)")
                        .font(.system(size: 18))
                        .foregroundColor(.gray)
                        .padding(.bottom, 20)
                    
                    // Boutons d'action
                    HStack(spacing: 20) {
                        Button(action: {
                            showQuantityPopup = false
                        }) {
                            Text("Annuler")
                                .font(.system(size: 22, weight: .medium))
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.black)
                                .cornerRadius(20)
                        }
                        
                        Button(action: {
                            showQuantityPopup = false
                            processAction()
                        }) {
                            Text("Confirmer")
                                .font(.system(size: 22, weight: .medium))
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: "689FA7"))
                                .foregroundColor(.white)
                                .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
                .padding(.horizontal, 30)
            }
            .presentationDetents([.medium])
            .presentationBackground(Color(hex: "C1DDF9"))
            .presentationCornerRadius(25)
        }
    }
    
    // MARK: - Composants de vue
    
    // Vue pour l'image du produit
    private var productImageView: some View {
        Group {
            if let productDetails = produit.productDetails,
               !productDetails.imageUrl.isEmpty,
               let url = URL(string: productDetails.imageUrl) {
                
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 150, height: 150)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                    case .failure:
                        defaultProductImage
                    @unknown default:
                        defaultProductImage
                    }
                }
            } else {
                defaultProductImage
            }
        }
        .padding(.top, 20)
    }
    
    // Image par défaut si aucune image n'est disponible
    private var defaultProductImage: some View {
        Image(systemName: "photo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 150)
            .foregroundColor(.gray)
    }
    
    // Indicateur Nutri-Score
    private var nutriScoreView: some View {
        HStack(spacing: 0) {
            ForEach(["A", "B", "C", "D", "E"], id: \.self) { score in
                // 🔹 CORRIGÉ : Logique de sélection simplifiée
                let isSelected: Bool = {
                    if let details = produit.productDetails,
                       !details.nutriscore.isEmpty {
                        return details.nutriscore.uppercased() == score
                    }
                    return false
                }()
                
                let color: Color = {
                    switch score {
                    case "A": return Color(hex: "4A8E38") // Vert foncé
                    case "B": return Color(hex: "85BB2F") // Vert clair
                    case "C": return Color(hex: "FFCC00") // Jaune
                    case "D": return Color(hex: "EF8200") // Orange
                    case "E": return Color(hex: "E63E11") // Rouge
                    default: return .gray
                    }
                }()
                
                VStack(spacing: 0) {
                    // 🔹 NOUVEAU : Triangle au-dessus si sélectionné
                    if isSelected {
                        Triangle()
                            .fill(color)
                            .frame(width: 20, height: 10)
                    } else {
                        Spacer()
                            .frame(height: 10)
                    }
                    
                    // Rectangle avec la lettre
                    ZStack {
                        Rectangle()
                            .fill(color)
                            .frame(width: 50, height: 50)
                        
                        Text(score)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .cornerRadius(8)
    }
    
    // Contrôle de quantité
    private var quantityControlView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(Color.white.opacity(0.7))
                .shadow(radius: 3)
            
            HStack(spacing: 30) {
                Text("Quantité:")
                    .font(.custom("ChauPhilomeneOne-Regular", size: 26))
                    .foregroundColor(.black)
                
                Button(action: {
                    if quantity > 1 {
                        quantity -= 1
                    }
                }) {
                    Text("-")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.black)
                }
                
                Text("\(quantity)")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.black)
                    .frame(minWidth: 40)
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    if quantity < produit.quantite {
                        quantity += 1
                    }
                }) {
                    Text("+")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
        }
        .frame(height: 70)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Propriétés calculées
    
    private var produitBrand: String {
        return produit.productDetails?.brand ?? "Inconnue"
    }
    
    // MARK: - Méthodes
    
    // Méthode pour afficher le popup pour jeter
    private func showDiscardPopup() {
        selectedAction = "wasted"
        popupQuantity = 1
        showQuantityPopup = true
    }

    // Méthode pour afficher le popup pour consommer
    private func showConsumePopup() {
        selectedAction = "consumed"
        popupQuantity = 1
        showQuantityPopup = true
    }

    // Méthode pour traiter l'action après sélection de la quantité
    private func processAction() {
        guard let stockId = produit.stockId else {
            errorMessage = "Erreur: identifiant de stock manquant"
            showErrorAlert = true
            return
        }
        
        // Vérifier que la quantité est valide
        if popupQuantity > produit.quantite {
            errorMessage = "Erreur: Vous ne pouvez pas sélectionner plus de produits que disponibles"
            showErrorAlert = true
            return
        }
        
        let status: ProductStatus = selectedAction == "consumed" ? .consumed : .wasted
        let finalQuantity = popupQuantity
        
        // Fermer la vue immédiatement
        dismiss()
        
        // Envoyer la requête en arrière-plan
        ProductConsumptionService.shared.markProductStatus(
            stockId: stockId,
            quantity: finalQuantity,
            status: status
        ) { success in
            if success {
                print("✅ Produit marqué comme \(status.rawValue): \(finalQuantity) unités")
            } else {
                print("❌ Erreur lors du marquage du produit")
            }
        }
    }
    
    // Méthode pour supprimer le produit
    private func deleteProduct() {
        guard let stockId = produit.stockId else {
            print("❌ Impossible de supprimer : stockId manquant")
            return
        }
        
        isDeleting = true
        
        stockViewModel.deleteProduct(stockId: stockId) { success in
            isDeleting = false
            
            if success {
                print("✅ Suppression réussie !")
                showDeleteSuccess = true
            }
        }
    }
}

// Forme de triangle pour l'indicateur de Nutri-Score
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

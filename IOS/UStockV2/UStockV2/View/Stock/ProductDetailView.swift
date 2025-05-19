import SwiftUI

struct ProductDetailView: View {
    let produit: Produit
    @State private var quantity: Int
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var showDeleteSuccess = false
    @Environment(\.dismiss) private var dismiss
    
    // ViewModel pour gérer les interactions avec l'API
    @StateObject private var stockViewModel = StockViewModel()
    
    // État pour le test de notification
    @State private var notificationAuthorized = false
    @State private var showingPermissionAlert = false
    @State private var notificationSent = false
    
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
                
                // BOUTON DE TEST DE NOTIFICATION
                Button(action: {
                    testNotification()
                }) {
                    HStack {
                        Image(systemName: "bell.badge")
                            .font(.title3)
                        Text("TESTER NOTIFICATION")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 20))
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(30)
                    .shadow(radius: 3)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                // Message de confirmation
                if notificationSent {
                    Text("Notification envoyée ! Vérifiez votre centre de notifications dans 5 secondes.")
                        .font(.footnote)
                        .foregroundColor(.purple)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Boutons d'action
                VStack(spacing: 15) {
                    // Boutons Jeté/Consommé
                    HStack(spacing: 0) {
                        Button(action: {
                            markAsDiscarded()
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
                            markAsConsumed()
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
                    
                    // Bouton Suppression
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            if isDeleting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 5)
                            }
                            
                            Text("SUPPRESSION")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 22))
                                .fontWeight(.bold)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .shadow(radius: 3)
                    }
                    .disabled(isDeleting)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Détails du produit")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(trailing: Button(action: {
            // Action pour le bouton d'engrenage (paramètres)
        }) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
        })
        .alert("Supprimer le produit", isPresented: $showDeleteConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Supprimer", role: .destructive) {
                deleteProduct()
            }
        } message: {
            Text("Voulez-vous vraiment supprimer ce produit de votre inventaire ?")
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
        .alert("Autorisation de notification requise", isPresented: $showingPermissionAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Ouvrir les Réglages") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Pour recevoir des notifications sur les produits qui périment bientôt, veuillez autoriser les notifications dans les réglages.")
        }
        .onAppear {
            // Vérifier l'autorisation de notification lors de l'apparition de la vue
            TestNotificationService.shared.checkNotificationSettings { authorized in
                self.notificationAuthorized = authorized
            }
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
                // Correction ici pour éviter l'utilisation de ? sur nutriscore
                let isSelected = if let details = produit.productDetails,
                                  !details.nutriscore.isEmpty {
                                    details.nutriscore.uppercased() == score
                                  } else {
                                    false
                                  }
                
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
                
                ZStack {
                    Rectangle()
                        .fill(color)
                        .frame(width: 50, height: 50)
                    
                    Text(score)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                }
                .overlay(
                    isSelected ?
                        Triangle()
                            .fill(color)
                            .frame(width: 20, height: 10)
                            .offset(y: -30)
                        : nil
                )
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
                        updateQuantity()
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
                    quantity += 1
                    updateQuantity()
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
    
    // Test de notification
    private func testNotification() {
        TestNotificationService.shared.checkNotificationSettings { authorized in
            if authorized {
                // Envoyer la notification de test
                TestNotificationService.shared.sendTestNotification(for: produit)
                notificationSent = true
                
                // Masquer le message après 5 secondes
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    notificationSent = false
                }
            } else {
                // Demander l'autorisation si ce n'est pas déjà autorisé
                TestNotificationService.shared.requestAuthorization { granted in
                    if granted {
                        // Autorisation accordée, envoyer la notification
                        TestNotificationService.shared.sendTestNotification(for: produit)
                        notificationSent = true
                        
                        // Masquer le message après 5 secondes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            notificationSent = false
                        }
                    } else {
                        // Afficher une alerte pour demander à l'utilisateur d'autoriser les notifications
                        showingPermissionAlert = true
                    }
                }
            }
        }
    }
    
    // Méthode pour mettre à jour la quantité
    private func updateQuantity() {
        // Cette fonction sera implémentée plus tard pour appeler l'API
        print("Mettre à jour la quantité : \(quantity)")
    }
    
    // Méthode pour marquer le produit comme jeté
    private func markAsDiscarded() {
        // Cette fonction sera implémentée plus tard
        print("Produit marqué comme jeté")
        dismiss()
    }
    
    // Méthode pour marquer le produit comme consommé
    private func markAsConsumed() {
        // Cette fonction sera implémentée plus tard
        print("Produit marqué comme consommé")
        dismiss()
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
            // En cas d'échec, l'alerte d'erreur sera affichée automatiquement par le ViewModel
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

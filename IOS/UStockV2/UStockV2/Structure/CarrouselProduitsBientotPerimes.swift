import SwiftUI

struct CarrouselProduitsBientotPerimes: View {
    let produits: [Produit]
    @State private var currentIndex = 0
    @State private var productImages: [Int: UIImage] = [:]
    
    // 🔹 NOUVELLE LOGIQUE : Produits qui expirent dans 3 jours ou moins (mais pas encore périmés)
    var produitsQuiExpirentBientot: [Produit] {
        produits.filter { $0.joursRestants >= 0 && $0.joursRestants <= 3 }
    }
    
    var body: some View {
        if produitsQuiExpirentBientot.isEmpty {
            Text("Aucun produit n'expire bientôt")
                .padding()
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "679FA7"))
                .cornerRadius(20)
                .padding(.horizontal)
        } else {
            VStack(spacing: 10) {
                // 🔹 CARROUSEL SIMPLE AVEC TABVIEW
                ZStack(alignment: .topTrailing) {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(produitsQuiExpirentBientot.enumerated()), id: \.offset) { index, produit in
                            NavigationLink(destination: ProductDetailView(produit: produit)) {
                                CarrouselCard(
                                    produit: produit,
                                    image: productImages[produit.stockId ?? 0],
                                    onImageLoad: {
                                        loadImage(for: produit)
                                    }
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 150)
                    
                    // Bouton X
                    
                    .padding([.top, .trailing], 10)
                }
                
                // 🔹 INDICATEURS PERSONNALISÉS
                HStack(spacing: 6) {
                    ForEach(0..<produitsQuiExpirentBientot.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                currentIndex = index
                            }
                        }) {
                            Circle()
                                .fill(index == currentIndex ? Color.black : Color.gray.opacity(0.5))
                                .frame(width: index == currentIndex ? 8 : 6, height: index == currentIndex ? 8 : 6)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.bottom, 5)
            }
            .padding(.horizontal, 15)
            .onAppear {
                // Charger toutes les images au démarrage
                for produit in produitsQuiExpirentBientot {
                    loadImage(for: produit)
                }
            }
        }
    }
    
    // Fonction pour charger l'image depuis l'URL
    private func loadImage(for produit: Produit) {
        guard let productDetails = produit.productDetails,
              let stockId = produit.stockId,
              let url = URL(string: productDetails.imageUrl),
              !productDetails.imageUrl.isEmpty,
              productImages[stockId] == nil else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let downloadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.productImages[stockId] = downloadedImage
                }
            }
        }.resume()
    }
}

// 🔹 COMPOSANT CARTE CORRIGÉ
struct CarrouselCard: View {
    let produit: Produit
    let image: UIImage?
    let onImageLoad: () -> Void
    
    var body: some View {
        HStack {
            // Image du produit à gauche
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                } else {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.gray)
                        .onAppear {
                            onImageLoad()
                        }
                }
            }
            .padding(.leading, 15)
            
            // Informations du produit à droite
            VStack(alignment: .leading, spacing: 4) {
                Text("PÉRIME BIENTÔT :")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 8)
                
                Text(produit.nom)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                
                Text("Périme le \(produit.peremption)")
                    .foregroundColor(getExpirationColor(for: produit))
                    .font(.system(size: 15, weight: .semibold))
                
                Text(getExpirationText(for: produit))
                    .foregroundColor(getExpirationColor(for: produit))
                    .font(.system(size: 13, weight: .medium))
                
                Text("Quantité : \(produit.quantite)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.bottom, 8)
            }
            .padding(.trailing, 15)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 130, maxHeight: 130)
        .background(Color(hex: "679FA7"))
        .cornerRadius(20)
        .shadow(radius: 3)
        .padding(.horizontal, 5) // Petit padding pour éviter que ça touche les bords
    }
    
    // Fonctions helper
    private func getExpirationColor(for produit: Produit) -> Color {
        if produit.joursRestants < 0 {
            return .red
        } else if produit.joursRestants <= 1 {
            return .red
        } else if produit.joursRestants <= 3 {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getExpirationText(for produit: Produit) -> String {
        if produit.joursRestants < 0 {
            let daysPassed = abs(produit.joursRestants)
            return daysPassed == 1 ? "Périmé depuis 1 jour" : "Périmé depuis \(daysPassed) jours"
        } else if produit.joursRestants == 0 {
            return "Expire aujourd'hui"
        } else if produit.joursRestants == 1 {
            return "Expire demain"
        } else {
            return "Expire dans \(produit.joursRestants) jours"
        }
    }
}

import SwiftUI

struct CarrouselProduitsBientotPerimes: View {
    let produits: [Produit]
    @State private var currentIndex = 0
    @State private var offset: CGFloat = 0
    @State private var productImages: [Int: UIImage] = [:]
    
    var produitsQuiExpirentBientot: [Produit] {
        produits.filter { $0.joursRestants <= 3 }
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
            ZStack(alignment: .topTrailing) {
                // Contenu principal
                HStack {
                    // Image du produit à gauche
                    if let stockId = produitsQuiExpirentBientot[currentIndex].stockId,
                       let image = productImages[stockId] {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .padding(.leading, 15)
                            .transition(.opacity)
                            .id("image-\(currentIndex)")
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                            .padding(.leading, 15)
                            .onAppear {
                                loadImage(for: currentIndex)
                            }
                    }
                    
                    // Informations du produit à droite
                    VStack(alignment: .leading, spacing: 4) {
                        // En-tête "PÉRIME BIENTÔT :"
                        Text("PÉRIME BIENTÔT :")
                            .font(.system(size: 14, weight: .bold))
                            .padding(.top, 8)
                        
                        // Nom du produit en gras et plus grand
                        Text(produitsQuiExpirentBientot[currentIndex].nom)
                            .font(.system(size: 24, weight: .bold))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .id("nom-\(currentIndex)")
                        
                        // Date de péremption en rouge
                        Text("Périme le \(produitsQuiExpirentBientot[currentIndex].peremption)")
                            .foregroundColor(.red)
                            .font(.system(size: 16, weight: .semibold))
                            .transition(.opacity)
                            .id("date-\(currentIndex)")
                        
                        // Quantité
                        Text("Quantité : \(produitsQuiExpirentBientot[currentIndex].quantite)")
                            .font(.system(size: 18, weight: .bold))
                            .padding(.bottom, 8)
                            .transition(.opacity)
                            .id("quantite-\(currentIndex)")
                    }
                    .padding(.trailing, 35)
                    
                    Spacer()
                }
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "679FA7"))
                .cornerRadius(20)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // Effet de drag en temps réel (léger)
                            offset = value.translation.width / 10
                        }
                        .onEnded { value in
                            // Réinitialiser l'offset
                            offset = 0
                            
                            if value.translation.width < -50 && currentIndex < produitsQuiExpirentBientot.count - 1 {
                                // Swipe gauche → produit suivant
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    currentIndex += 1
                                }
                                loadImage(for: currentIndex)
                            } else if value.translation.width > 50 && currentIndex > 0 {
                                // Swipe droite → produit précédent
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    currentIndex -= 1
                                }
                                loadImage(for: currentIndex)
                            }
                        }
                )
                .offset(x: offset) // Appliquer le décalage pendant le drag
                
                // Bouton X dans un cercle noir
                Button(action: {
                    // Action à exécuter quand on clique sur le X
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 35, height: 35)
                        
                        Text("✕")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                .padding([.top, .trailing], 8)
                
                // Indicateurs de pagination en bas du cadre (mais à l'intérieur)
                HStack(spacing: 5) {
                    ForEach(0..<produitsQuiExpirentBientot.count, id: \.self) { i in
                        Circle()
                            .fill(i == currentIndex ? Color.black : Color.gray)
                            .frame(width: i == currentIndex ? 8 : 5, height: i == currentIndex ? 8 : 5)
                    }
                }
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .frame(height: 150, alignment: .bottom)
            }
            .padding(.horizontal)
            .onAppear {
                // Charger l'image du premier produit
                if !produitsQuiExpirentBientot.isEmpty {
                    loadImage(for: currentIndex)
                }
            }
        }
    }
    
    // Fonction pour charger l'image depuis l'URL
    private func loadImage(for index: Int) {
        guard index < produitsQuiExpirentBientot.count,
              let productDetails = produitsQuiExpirentBientot[index].productDetails,
              let stockId = produitsQuiExpirentBientot[index].stockId,
              let url = URL(string: productDetails.imageUrl),
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

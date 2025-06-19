import SwiftUI

struct ProduitRowView: View {
    let produit: Produit
    @State private var navigateToDetail = false
    
    // 🔹 NOUVELLE LOGIQUE : Couleur basée sur les jours restants
    var couleurTexte: Color {
        if produit.joursRestants < 0 {
            return .red  // Périmé
        } else if produit.joursRestants <= 1 {
            return .red  // 0-1 jour
        } else if produit.joursRestants <= 3 {
            return .orange  // 2-3 jours
        } else {
            return .green  // 4+ jours
        }
    }
    
    // 🔹 NOUVEAU : Texte d'affichage amélioré
    var textePeremption: String {
        if produit.joursRestants < 0 {
            let daysPassed = abs(produit.joursRestants)
            return daysPassed == 1 ?
                "Périmé depuis 1 jour" :
                "Périmé depuis \(daysPassed) jours"
        } else if produit.joursRestants == 0 {
            return "Expire aujourd'hui"
        } else if produit.joursRestants == 1 {
            return "Expire demain"
        } else {
            return "Expire dans \(produit.joursRestants) jours"
        }
    }
    
    var body: some View {
        NavigationLink(destination: ProductDetailView(produit: produit)) {
            HStack {
                // Image du produit
                if let productDetails = produit.productDetails {
                    // Vérifier si l'URL d'image n'est pas vide
                    if !productDetails.imageUrl.isEmpty,
                       let url = URL(string: productDetails.imageUrl) {
                        
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Text(produit.image)
                                    .font(.largeTitle)
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                            case .failure:
                                Text(produit.image)
                                    .font(.largeTitle)
                            @unknown default:
                                Text(produit.image)
                                    .font(.largeTitle)
                            }
                        }
                        .frame(width: 60, height: 60)
                    } else {
                        Text(produit.image)
                            .font(.largeTitle)
                    }
                } else {
                    Text(produit.image)
                        .font(.largeTitle)
                }
                
                VStack(alignment: .leading) {
                    Text(produit.nom)
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    // 🔹 NOUVEAU : Affichage de la date complète
                    Text("Périme le \(produit.peremption)")
                        .font(.subheadline)
                        .foregroundColor(.black)
                    
                    // 🔹 NOUVEAU : Affichage du statut avec couleur
                    Text(textePeremption)
                        .foregroundColor(couleurTexte)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Quantité : \(produit.quantite)")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                
                Spacer()
                
                // Icône de chevron pour indiquer qu'on peut cliquer
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .padding(.trailing, 5)
            }
            .padding()
            .background(Color(hex: "#B6D2ED"))
            .cornerRadius(0)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle()) // Évite les effets de pression sur toute la cellule
    }
}

#Preview {
    VStack(spacing: 10) {
        // Produit périmé
        ProduitRowView(produit: Produit(
            nom: "Yaourt périmé",
            peremption: "5 octobre 2024",
            joursRestants: -2,
            quantite: 1,
            image: "🥛",
            stockId: 1,
            productDetails: ProductDetails(
                barcode: "12345678",
                brand: "Danone",
                contentSize: "125g",
                nutriscore: "A",
                imageUrl: ""
            )
        ))
        
        // Produit expire aujourd'hui
        ProduitRowView(produit: Produit(
            nom: "Lait expire aujourd'hui",
            peremption: "19 juin 2025",
            joursRestants: 0,
            quantite: 1,
            image: "🥛",
            stockId: 2,
            productDetails: ProductDetails(
                barcode: "12345679",
                brand: "Lactel",
                contentSize: "1L",
                nutriscore: "B",
                imageUrl: ""
            )
        ))
        
        // Produit expire dans 2 jours
        ProduitRowView(produit: Produit(
            nom: "Pain expire bientôt",
            peremption: "21 juin 2025",
            joursRestants: 2,
            quantite: 1,
            image: "🍞",
            stockId: 3,
            productDetails: ProductDetails(
                barcode: "12345680",
                brand: "Boulangerie",
                contentSize: "500g",
                nutriscore: "C",
                imageUrl: ""
            )
        ))
        
        // Produit OK
        ProduitRowView(produit: Produit(
            nom: "Canette Pepsi",
            peremption: "10 juillet 2025",
            joursRestants: 21,
            quantite: 1,
            image: "🥤",
            stockId: 4,
            productDetails: ProductDetails(
                barcode: "12345681",
                brand: "Pepsi",
                contentSize: "330ml",
                nutriscore: "D",
                imageUrl: ""
            )
        ))
    }
    .padding()
}

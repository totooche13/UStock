import SwiftUI

struct ProduitRowView: View {
    let produit: Produit
    @State private var navigateToDetail = false
    
    var couleurTexte: Color {
        switch produit.joursRestants {
        case ...0:
            return .red
        case 1...3:
            return .orange
        case 4...14:
            return .green
        default:
            return .gray
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
                    
                    Text("Périme le \(produit.peremption) (\(produit.joursRestants >= 0 ? "\(produit.joursRestants) jours" : "Périmé"))")
                        .foregroundColor(couleurTexte)
                        .font(.subheadline)
                    
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
    ProduitRowView(produit: Produit(
        nom: "Canette Pepsi",
        peremption: "10-04-25",
        joursRestants: 30,
        quantite: 1,
        image: "🥤",
        stockId: 1,
        productDetails: ProductDetails(
            barcode: "12345678",
            brand: "Pepsi",
            contentSize: "330ml",
            nutriscore: "D",
            imageUrl: "https://world.openfoodfacts.org/images/products/590/760/011/1702/front_fr.177.400.jpg"
        )
    ))
}

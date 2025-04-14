import SwiftUI

struct StockEntryView: View {
    let product: Product
    @Environment(\.dismiss) private var dismiss
    
    // Important : nous initialisons le ViewModel avec le produit
    @StateObject private var viewModel: ScannerViewModel
    
    // Initialisation pour passer le produit au ViewModel
    init(product: Product) {
        self.product = product
        // Création d'un StateObject avec un produit préchargé
        _viewModel = StateObject(wrappedValue: ScannerViewModel(preloadedProduct: product))
    }
    
    @State private var quantity: Int = 1
    @State private var expirationDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isLoading = false
    @State private var showSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Image du produit
                        if let imageUrl = product.image_url, let url = URL(string: imageUrl) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 120, height: 120)
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 120, height: 120)
                                        .cornerRadius(10)
                                        .shadow(radius: 3)
                                case .failure:
                                    Image(systemName: "photo")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.gray)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .padding(.top, 20)
                        } else {
                            Image(systemName: "photo")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        }
                        
                        // Informations produit
                        VStack(alignment: .leading, spacing: 12) {
                            Text(product.product_name)
                                .font(.custom("ChauPhilomeneOne-Regular", size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.bottom, 5)
                            
                            HStack {
                                Text("Code-barres:")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Spacer()
                                Text(product.barcode)
                                    .font(.body)
                                    .foregroundColor(.black) // Changé de .secondary à .black
                            }
                            .padding(.horizontal)
                            
                            if let brand = product.brand {
                                HStack {
                                    Text("Marque:")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text(brand)
                                        .font(.body)
                                        .foregroundColor(.black) // Changé de .secondary à .black
                                }
                                .padding(.horizontal)
                            }
                            
                            if let contentSize = product.content_size {
                                HStack {
                                    Text("Contenance:")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text(contentSize)
                                        .font(.body)
                                        .foregroundColor(.black) // Changé de .secondary à .black
                                }
                                .padding(.horizontal)
                            }
                            
                            if let nutriscore = product.nutriscore {
                                HStack {
                                    Text("Nutri-Score:")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Text(nutriscore.uppercased())
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 30, height: 30)
                                        .background(viewModel.nutriscoreColor(nutriscore))
                                        .clipShape(Circle())
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(15)
                        .shadow(radius: 3)
                        .padding(.horizontal)
                        
                        // Sélecteur de quantité
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Quantité")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 20))
                                .foregroundColor(.black)
                                .padding(.horizontal)
                            
                            HStack {
                                Button(action: {
                                    if quantity > 1 {
                                        quantity -= 1
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: "156585"))
                                }
                                
                                Text("\(quantity)")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)
                                    .frame(minWidth: 50)
                                    .multilineTextAlignment(.center)
                                
                                Button(action: {
                                    quantity += 1
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: "156585"))
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(15)
                            .shadow(radius: 2)
                            .padding(.horizontal)
                        }
                        .padding(.top, 10)
                        
                        // Sélecteur de date de péremption
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Date de péremption")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 20))
                                .foregroundColor(.black)
                                .padding(.horizontal)
                            
                            // DatePicker modifié pour un meilleur contraste
                            ZStack {
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white.opacity(0.8))
                                    .shadow(radius: 2)
                                
                                DatePicker("", selection: $expirationDate, displayedComponents: .date)
                                    .datePickerStyle(WheelDatePickerStyle())
                                    .labelsHidden()
                                    .accentColor(Color(hex: "156585")) // Couleur d'accent
                                    .colorScheme(.light) // Force le mode clair
                                    .colorMultiply(Color.black) // Assombrit les textes
                            }
                            .frame(height: 200)
                            .padding(.horizontal)
                        }
                        .padding(.top, 10)
                        
                        // Bouton Ajouter à l'inventaire
                        Button(action: {
                            addToStock()
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .padding(.trailing, 5)
                                }
                                
                                Text("AJOUTER À L'INVENTAIRE")
                                    .font(.custom("ChauPhilomeneOne-Regular", size: 20))
                                    .fontWeight(.bold)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(Color(hex: "689FA7"))
                            .foregroundColor(.black)
                            .cornerRadius(20)
                            .shadow(radius: 5)
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, 30)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle("Ajouter un produit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .alert("Produit ajouté", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Le produit a été ajouté à votre inventaire avec succès.")
            }
            .alert(viewModel.errorMessage ?? "Erreur", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            }
            // Forcer le style clair pour tout le DatePicker
            .environment(\.colorScheme, .light)
        }
    }
    
    private func addToStock() {
        isLoading = true
        viewModel.addProductToStock(quantity: quantity, expirationDate: expirationDate) { success in
            isLoading = false
            if success {
                showSuccess = true
            }
        }
    }
}

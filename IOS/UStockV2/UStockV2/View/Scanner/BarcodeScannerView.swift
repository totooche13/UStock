import SwiftUI

struct BarcodeScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @State private var scannedCode: String? = nil
    @State private var isShowingScanner = true
    @State private var isFlashOn = false
    @State private var showStockEntryView = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Titre
                    Text("SCANNER")
                        .font(.custom("ChauPhilomeneOne-Regular", size: 28))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    
                    if let product = viewModel.scannedProduct {
                        // Affichage du produit scanné
                        productInfoView(product)
                    } else if viewModel.isLoading {
                        // Indicateur de chargement
                        loadingView
                    } else {
                        // Instructions de scan
                        scanInstructionsView
                    }
                    
                    if isShowingScanner {
                        // Vue de la caméra
                        ZStack {
                            CameraScannerView(
                                scannedCode: $scannedCode,
                                isShowingScanner: $isShowingScanner,
                                isFlashOn: $isFlashOn
                            )
                            .frame(height: 350)
                            .cornerRadius(20)
                            .padding(.horizontal, 15)
                            .shadow(radius: 5)
                            
                            // Cadre de scan animé
                            scannerOverlayView
                        }
                        .padding(.vertical, 15)
                        
                        // Bouton lampe torche
                        Button(action: {
                            isFlashOn.toggle()
                        }) {
                            HStack {
                                Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                                    .font(.system(size: 22))
                                Text(isFlashOn ? "Désactiver la lampe" : "Activer la lampe")
                                    .font(.system(size: 16))
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(isFlashOn ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.2))
                            .cornerRadius(15)
                            .foregroundColor(isFlashOn ? .orange : .gray)
                        }
                        .padding(.bottom, 20)
                    } else if viewModel.scannedProduct == nil && !viewModel.isLoading {
                        // Bouton pour réactiver le scanner
                        Button(action: {
                            resetScanner()
                        }) {
                            HStack {
                                Image(systemName: "barcode.viewfinder")
                                Text("Scanner à nouveau")
                            }
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color(hex: "156585"))
                            .cornerRadius(15)
                            .shadow(radius: 3)
                        }
                        .padding(.vertical, 20)
                    }
                    
                    Spacer()
                }
            }
            
            
            .onChange(of: scannedCode) { _, newCode in
                if let barcode = newCode {
                    viewModel.fetchProductInfo(barcode: barcode)
                }
            }
            .sheet(isPresented: $showStockEntryView) {
                if let product = viewModel.scannedProduct {
                    StockEntryView(product: product)
                        .onDisappear {
                            // Réinitialiser l'état du scanner après la fermeture de la feuille
                            resetScanner()
                        }
                }
            }
            .alert(viewModel.errorMessage ?? "Erreur", isPresented: $viewModel.showError) {
                Button("OK") {
                    resetScanner()
                }
            }
        }
    }
    
    // Vue des instructions de scan
    private var scanInstructionsView: some View {
        VStack(spacing: 15) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 70))
                .foregroundColor(Color(hex: "156585"))
                .padding(.bottom, 10)
            
            Text("Scannez un code-barres")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.black)
            
            Text("Placez le code-barres du produit dans le cadre pour le scanner automatiquement")
                .font(.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 3)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    // Vue de chargement
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Recherche du produit...")
                .font(.headline)
                .foregroundColor(.black)
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 3)
        .padding(.horizontal, 20)
    }
    
    // Vue des informations du produit
    private func productInfoView(_ product: Product) -> some View {
        VStack(spacing: 15) {
            HStack(alignment: .top, spacing: 20) {
                // Image du produit
                productImageView(product)
                
                // Informations produit
                VStack(alignment: .leading, spacing: 8) {
                    Text(product.product_name)
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(2)
                    
                    if let brand = product.brand {
                        Text("Marque: \(brand)")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    
                    if let contentSize = product.content_size {
                        Text("Format: \(contentSize)")
                            .font(.subheadline)
                            .foregroundColor(.black)
                    }
                    
                    if let nutriscore = product.nutriscore {
                        HStack {
                            Text("Nutri-Score:")
                                .font(.subheadline)
                                .foregroundColor(.black)
                            
                            Text(nutriscore.uppercased())
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(viewModel.nutriscoreColor(nutriscore))
                                .clipShape(Circle())
                        }
                    }
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 130)
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(15)
            .shadow(radius: 3)
            .padding(.horizontal, 20)
            
            // Bouton d'ajout à l'inventaire
            Button(action: {
                showStockEntryView = true
            }) {
                Text("AJOUTER À L'INVENTAIRE")
                    .font(.custom("ChauPhilomeneOne-Regular", size: 16))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "689FA7"))
                    .foregroundColor(.black)
                    .cornerRadius(20)
                    .shadow(radius: 3)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
    }
    
    // Vue de l'image du produit
    private func productImageView(_ product: Product) -> some View {
        Group {
            if let imageUrl = product.image_url, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 80)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "photo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 80, height: 80)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
            }
        }
    }
    
    // Vue de superposition du scanner
    private var scannerOverlayView: some View {
        ZStack {
            // Lignes d'angle (coins supérieurs gauche)
            VStack {
                HStack {
                    scannerCorner(rotation: 0)
                    Spacer()
                    scannerCorner(rotation: 90)
                }
                Spacer()
                HStack {
                    scannerCorner(rotation: 270)
                    Spacer()
                    scannerCorner(rotation: 180)
                }
            }
            .padding(40)
        }
    }
    
    // Coin du scanner
    private func scannerCorner(rotation: Double) -> some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 0, y: 10))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 10, y: 0))
            }
            .stroke(Color.white, lineWidth: 3)
            .frame(width: 20, height: 20)
            .rotationEffect(.degrees(rotation))
            .shadow(color: .black.opacity(0.3), radius: 2)
        }
    }
    
    // Réinitialisation du scanner
    private func resetScanner() {
        viewModel.reset()
        scannedCode = nil
        isShowingScanner = true
    }
}

#Preview {
    BarcodeScannerView()
}

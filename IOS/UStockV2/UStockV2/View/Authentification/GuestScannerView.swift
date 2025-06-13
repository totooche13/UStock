//
//  GuestScannerView.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 12/06/2025.
//


import SwiftUI

struct GuestScannerView: View {
    @StateObject private var viewModel = GuestScannerViewModel()
    @State private var scannedCode: String? = nil
    @State private var isShowingScanner = true
    @State private var isFlashOn = false
    @State private var showCreateAccountPrompt = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                VStack {
                    // En-tête avec badge "Mode Invité"
                    HStack {
                        Text("SCANNER (MODE INVITÉ)")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Button("Fermer") {
                            dismiss()
                        }
                        .foregroundColor(Color(hex: "156585"))
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Bannière explicative
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Vous pouvez consulter les infos produits. Créez un compte pour sauvegarder.")
                            .font(.caption)
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    if let product = viewModel.scannedProduct {
                        // Affichage du produit scanné (lecture seule)
                        productInfoView(product)
                    } else if viewModel.isLoading {
                        loadingView
                    } else {
                        scanInstructionsView
                    }
                    
                    if isShowingScanner {
                        // Scanner
                        ZStack {
                            CameraScannerView(
                                scannedCode: $scannedCode,
                                isShowingScanner: $isShowingScanner,
                                isFlashOn: $isFlashOn
                            )
                            .frame(height: 300)
                            .cornerRadius(20)
                            .padding(.horizontal, 15)
                            .shadow(radius: 5)
                            
                            scannerOverlayView
                        }
                        .padding(.vertical, 15)
                        
                        // Bouton lampe
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
                    } else if viewModel.scannedProduct == nil && !viewModel.isLoading {
                        Button(action: {
                            resetScanner()
                        }) {
                            HStack {
                                Image(systemName: "barcode.viewfinder")
                                Text("Scanner un autre produit")
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
            .alert("Créer un compte ?", isPresented: $showCreateAccountPrompt) {
                Button("Plus tard", role: .cancel) {}
                Button("Créer un compte") {
                    // Navigation vers RegisterView
                    dismiss()
                }
            } message: {
                Text("Pour ajouter ce produit à votre inventaire et gérer vos stocks, créez un compte gratuit !")
            }
            .alert(viewModel.errorMessage ?? "Erreur", isPresented: $viewModel.showError) {
                Button("OK") {
                    resetScanner()
                }
            }
        }
    }
    
    // Vue des informations du produit (lecture seule)
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
                                .background(nutriscoreColor(nutriscore))
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
            
            // Bouton d'invitation à créer un compte
            Button(action: {
                showCreateAccountPrompt = true
            }) {
                HStack {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                    
                    Text("CRÉER UN COMPTE POUR SAUVEGARDER")
                        .font(.custom("ChauPhilomeneOne-Regular", size: 16))
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "22C55E"))
                .foregroundColor(.white)
                .cornerRadius(20)
                .shadow(radius: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 2)
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
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
    
    private var scanInstructionsView: some View {
        VStack(spacing: 15) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "156585"))
                .padding(.bottom, 10)
            
            Text("Scannez pour voir les infos")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.black)
            
            Text("Découvrez les informations nutritionnelles et les détails de vos produits")
                .font(.body)
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 3)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Recherche du produit...")
                .font(.headline)
                .foregroundColor(.black)
        }
        .frame(height: 120)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 3)
        .padding(.horizontal, 20)
    }
    
    private var scannerOverlayView: some View {
        ZStack {
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
    
    private func nutriscoreColor(_ score: String) -> Color {
        switch score.lowercased() {
        case "a": return Color(hex: "22C55E")
        case "b": return Color(hex: "86BC2B")
        case "c": return Color(hex: "FECB02")
        case "d": return Color(hex: "EF8200")
        case "e": return Color(hex: "E63E11")
        default: return .gray
        }
    }
    
    private func resetScanner() {
        viewModel.reset()
        scannedCode = nil
        isShowingScanner = true
    }
}

// ViewModel simplifié pour le mode invité
class GuestScannerViewModel: ObservableObject {
    @Published var scannedProduct: Product? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showError = false
    
    func fetchProductInfo(barcode: String) {
        isLoading = true
        errorMessage = nil
        
        ProductService.shared.fetchProduct(barcode: barcode) { product in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if let product = product {
                    self.scannedProduct = product
                } else {
                    // Si pas trouvé, essayer de créer puis récupérer
                    ProductService.shared.createProduct(barcode: barcode) { success in
                        if success {
                            ProductService.shared.fetchProduct(barcode: barcode) { newProduct in
                                DispatchQueue.main.async {
                                    if let newProduct = newProduct {
                                        self.scannedProduct = newProduct
                                    } else {
                                        self.errorMessage = "Produit introuvable"
                                        self.showError = true
                                    }
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.errorMessage = "Produit introuvable"
                                self.showError = true
                            }
                        }
                    }
                }
            }
        }
    }
    
    func reset() {
        scannedProduct = nil
        errorMessage = nil
        showError = false
    }
}

#Preview {
    GuestScannerView()
}
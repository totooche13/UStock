import SwiftUI

struct InventaireView: View {
    @StateObject private var stockViewModel = StockViewModel()
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                VStack {
                    // 🔹 Titre Inventaire avec roue dentée fonctionnelle
                    HStack {
                        Text("INVENTAIRE")
                            .font(.custom("ChauPhilomeneOne-Regular", size: 32))
                            .fontWeight(.bold)
                            .padding(.leading, 20)
                            .foregroundColor(Color(.black))
                        
                        Spacer()
                        
                        NavigationLink(destination: InventorySettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(Color(.black))
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.top, 20)
                    .background(Color(hex: "C1DDF9")) // Même couleur que le fond

                    // 🔹 NOUVEAU : ScrollView qui contient TOUT (carrousel + liste)
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Pull-to-refresh control
                            PullToRefresh(coordinateSpaceName: "pullToRefresh", onRefresh: refreshData)
                            
                            // 🔹 CARROUSEL INTÉGRÉ DANS LE SCROLL
                            CarrouselProduitsBientotPerimes(produits: stockViewModel.stocks)
                                .padding(.vertical, 10)
                            
                            // 🔹 CONTENU DE LA LISTE
                            if stockViewModel.isLoading && stockViewModel.stocks.isEmpty {
                                ProgressView("Chargement des produits...")
                                    .padding()
                            } else if stockViewModel.stocks.isEmpty {
                                VStack {
                                    Text("Aucun produit dans votre inventaire")
                                        .font(.headline)
                                        .padding()
                                    Text("Utilisez le scanner pour ajouter des produits")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(stockViewModel.stocks) { produit in
                                        ProduitRowView(produit: produit)
                                            .foregroundColor(Color(.black))
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Espace en bas pour la navigation
                            Spacer()
                                .frame(height: 100)
                        }
                    }
                    .coordinateSpace(name: "pullToRefresh")
                    .refreshable {
                        await refreshStatsAsync()
                    }

                    Spacer() // Ceci pousse tout le contenu vers le haut

                    // Barre de navigation encore plus compacte
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            // 🔹 CORRIGÉ : Bouton Inventaire sans navigation (on est déjà dessus)
                            Button(action: {
                                // Ne rien faire si on est déjà sur la page Inventaire
                            }) {
                                VStack(spacing: 0) {
                                    Image(systemName: "archivebox.fill")
                                        .font(.system(size: 30))
                                    Text("Inventaire")
                                        .font(.system(size: 12))
                                }
                                .foregroundColor(Color(hex: "156585")) // Couleur active
                            }
                            Spacer()
                            NavigationLink(destination: Text("Liste")) {
                                VStack(spacing: 0) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 30))
                                    Text("Liste")
                                        .font(.system(size: 12))
                                }
                            }
                            Spacer()
                            // Espace pour le bouton Scanner qui va "flotter" au-dessus
                            Spacer()
                            Spacer()
                            NavigationLink(destination: ProfileView()) {
                                VStack(spacing: 0) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 30))
                                    Text("Profil")
                                        .font(.system(size: 12))
                                }
                            }
                            Spacer()
                            NavigationLink(destination: StatsView()) {
                                VStack(spacing: 0) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 30))
                                    Text("Statistiques")
                                        .font(.system(size: 12))
                                }
                            }
                            Spacer()
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 6) // Moins d'espace en bas
                        .background(Color.white)
                        .foregroundColor(Color.black)
                        .shadow(radius: 1, y: -1) // Ombre encore plus légère
                        .edgesIgnoringSafeArea(.bottom)
                    }
                    .overlay(
                        // Bouton Scanner flottant
                        NavigationLink(destination: BarcodeScannerView()) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: "156585"))
                                    .frame(width: 65, height: 65)
                                    .shadow(radius: 2, y: 1)
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 30))
                                    .foregroundColor(.white)
                            }
                        }
                        .offset(y: -25), // Décale davantage le bouton scanner vers le haut
                        alignment: .center
                    )
                }
            }
            .onAppear {
                // Charger les produits quand la vue apparaît
                stockViewModel.fetchStocks()
                
                // 🔹 NOUVEAU : Programmer les notifications après chargement
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    NotificationService.shared.scheduleExpirationNotifications(for: stockViewModel.stocks)
                }
            }
            .alert(stockViewModel.errorMessage ?? "Erreur", isPresented: $stockViewModel.showErrorAlert) {
                Button("OK", role: .cancel) {}
            }
        }
        // 🔹 NOUVEAU : Forcer le mode clair
        .preferredColorScheme(.light)
    }
    
    // Fonction pour rafraîchir les données
    private func refreshData() {
        isRefreshing = true
        stockViewModel.fetchStocks()
        // La mise à jour isLoading dans le ViewModel mettra fin au refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
        }
    }
    
    // Version async pour le refreshable
    private func refreshStatsAsync() async {
        stockViewModel.fetchStocks()
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
}

// Preview
#Preview {
    InventaireView()
}

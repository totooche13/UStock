import SwiftUI

struct StatsView: View {
    @State private var stats: ConsumptionStats?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedPeriod: StatsPeriod = .month
    
    enum StatsPeriod {
        case month, total
    }
    
    var body: some View {
        ZStack {
            // Fond d'écran
            Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Titre
                    Text("STATISTIQUES")
                        .font(.custom("ChauPhilomeneOne-Regular", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.top, 20)
                    
                    // Sélecteur de période
                    periodSelector
                        .padding(.bottom, 10)
                    
                    if isLoading {
                        loadingView
                    } else if let stats = stats {
                        VStack(spacing: 25) {
                            // Carte principale avec le taux de gaspillage
                            mainStatsCard(stats: selectedPeriod == .month ? stats.current_month : stats.total)
                            
                            // Nouvelle carte pour l'argent gaspillé
                            moneyWastedCard(stats: selectedPeriod == .month ? stats.current_month : stats.total)
                            
                            // Cartes des produits consommés et gaspillés
                            HStack(spacing: 15) {
                                consumedWastedCard(
                                    title: "Consommés",
                                    value: selectedPeriod == .month ? stats.current_month.consumed_count : stats.total.consumed_count,
                                    color: .green
                                )
                                
                                consumedWastedCard(
                                    title: "Gaspillés",
                                    value: selectedPeriod == .month ? stats.current_month.wasted_count : stats.total.wasted_count,
                                    color: .red
                                )
                            }
                            .padding(.horizontal, 15)
                            
                            // Graphique des tendances
                            if selectedPeriod == .month && stats.current_month.total_count > 0 {
                                donutChartView(stats: stats.current_month)
                                    .padding(.top, 10)
                            }
                            
                            // Conseils si le taux de gaspillage est élevé
                            if (selectedPeriod == .month && stats.current_month.waste_rate > 10) ||
                               (selectedPeriod == .total && stats.total.waste_rate > 10) {
                                tipsCard
                            }
                        }
                    } else {
                        noDataView
                    }
                }
                .padding(.bottom, 80) // Espace pour la barre de navigation
            }
        }
        .onAppear {
            loadStats()
        }
    }
    
    // MARK: - Components
    
    // Nouvelle vue pour afficher l'argent gaspillé
    private func moneyWastedCard(stats: ConsumptionStatTotal) -> some View {
        VStack(spacing: 15) {
            Text("Impact financier du gaspillage")
                .font(.headline)
                .foregroundColor(.black)
            
            HStack(spacing: 15) {
                // Icône Euro
                Image(systemName: "eurosign.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Color(hex: "D12E2E"))
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(String(format: "%.2f", stats.wasted_money))")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(Color(hex: "D12E2E"))
                        
                        Text("€")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "D12E2E"))
                    }
                    
                    Text("gaspillés")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 15)
            
            // Message d'explication
            Text("Cette estimation représente la valeur approximative des produits jetés.")
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 15)
    }
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach([StatsPeriod.month, StatsPeriod.total], id: \.self) { period in
                Button(action: {
                    withAnimation {
                        selectedPeriod = period
                    }
                }) {
                    Text(period == .month ? "Ce mois" : "Historique")
                        .font(.system(size: 16, weight: .medium))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(selectedPeriod == period ? .white : .black)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedPeriod == period ? Color(hex: "156585") : Color.white.opacity(0.6))
                        )
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.3))
        .cornerRadius(25)
        .padding(.horizontal, 20)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding(40)
            
            Text("Chargement des statistiques...")
                .font(.headline)
                .foregroundColor(.gray)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }
    
    private var noDataView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.pie")
                .font(.system(size: 70))
                .foregroundColor(Color(hex: "156585").opacity(0.7))
                .padding(40)
            
            Text("Aucune donnée disponible")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text("Commencez à marquer des produits comme consommés ou gaspillés pour voir vos statistiques.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal, 40)
        }
        .frame(height: 400)
        .frame(maxWidth: .infinity)
    }
    
    private func mainStatsCard(stats: ConsumptionStatTotal) -> some View {
        VStack(spacing: 15) {
            Text(selectedPeriod == .month ? "Taux de gaspillage mensuel" : "Taux de gaspillage global")
                .font(.headline)
                .foregroundColor(.black)
            
            // Grand cercle avec le taux
            ZStack {
                Circle()
                    .trim(from: 0, to: min(stats.waste_rate / 100, 1.0))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.green, .yellow, .orange, .red]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 160, height: 160)
                
                VStack(spacing: 0) {
                    Text("\(Int(stats.waste_rate))%")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(wasteRateColor(stats.waste_rate))
                    
                    Text("gaspillés")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 20)
            
            // Interprétation du taux
            Text(wasteRateInterpretation(stats.waste_rate))
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 15)
    }
    
    private func consumedWastedCard(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 15) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
            
            Text("\(value)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(color)
            
            Text("produits")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    private func donutChartView(stats: ConsumptionStatTotal) -> some View {
        VStack(spacing: 15) {
            Text("Répartition ce mois-ci")
                .font(.headline)
                .foregroundColor(.black)
            
            ZStack {
                // Cercle fond gris
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 30)
                    .frame(width: 200, height: 200)
                
                // Portion consommée (verte)
                if stats.total_count > 0 {
                    Circle()
                        .trim(from: 0, to: CGFloat(stats.consumed_count) / CGFloat(stats.total_count))
                        .stroke(Color.green, lineWidth: 30)
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                }
                
                // Texte au centre
                VStack {
                    Text("\(stats.consumed_count)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("vs")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                    
                    Text("\(stats.wasted_count)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red)
                }
            }
            .padding(.vertical, 20)
            
            // Légende
            HStack(spacing: 30) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    
                    Text("Consommés")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    
                    Text("Gaspillés")
                        .font(.subheadline)
                        .foregroundColor(.black)
                }
            }
            .padding(.bottom, 15)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 15)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 15)
    }
    
    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("CONSEILS ANTI-GASPILLAGE")
                .font(.headline)
                .foregroundColor(.black)
            
            VStack(alignment: .leading, spacing: 15) {
                tipRow(icon: "refrigerator", text: "Placez les produits qui expirent bientôt à l'avant du réfrigérateur.")
                
                tipRow(icon: "list.bullet.clipboard", text: "Planifiez vos repas à l'avance et n'achetez que ce dont vous avez besoin.")
                
                tipRow(icon: "arrow.3.trianglepath", text: "Utilisez les restes pour créer de nouveaux plats.")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(hex: "FFEBCC"))
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 15)
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "FF9500"))
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Helpers
    
    private func loadStats() {
        isLoading = true
        errorMessage = nil
        
        ProductConsumptionService.shared.getStats { result in
            self.isLoading = false
            
            switch result {
            case .success(let stats):
                self.stats = stats
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    private func wasteRateColor(_ rate: Double) -> Color {
        if rate < 5 {
            return .green
        } else if rate < 15 {
            return .yellow
        } else if rate < 30 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func wasteRateInterpretation(_ rate: Double) -> String {
        if rate < 5 {
            return "Excellent ! Votre taux de gaspillage est très faible."
        } else if rate < 15 {
            return "Bon résultat. Vous pourriez encore améliorer votre consommation."
        } else if rate < 30 {
            return "Attention, votre taux de gaspillage est assez élevé. Essayez de mieux planifier vos repas."
        } else {
            return "Votre taux de gaspillage est important. Consultez nos conseils pour le réduire."
        }
    }
}

// MARK: - Modèles des données

// Structure pour les statistiques de consommation et gaspillage
struct ConsumptionStats: Codable {
    let total: ConsumptionStatTotal
    let current_month: ConsumptionStatTotal
    let top_wasted_products: [ProductStat]?
    let monthly_history: [MonthlyHistoryStat]?
}

struct ConsumptionStatTotal: Codable {
    let consumed_count: Int
    let wasted_count: Int
    let total_count: Int
    let waste_rate: Double
    let wasted_money: Double // Ajout de l'information financière
    let consumed_money: Double? // Optionnel, si vous voulez aussi le total consommé
    let total_money: Double? // Optionnel, somme des deux
}

struct ProductStat: Codable {
    let name: String
    let quantity: Int
}

struct MonthlyHistoryStat: Codable {
    let month: String
    let wasted: Int
    let consumed: Int
    let total: Int
}

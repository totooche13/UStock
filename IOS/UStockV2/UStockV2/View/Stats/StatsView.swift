import SwiftUI

struct StatsView: View {
    @State private var stats: ConsumptionStats?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        ZStack {
            Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("STATISTIQUES")
                        .font(.custom("ChauPhilomeneOne-Regular", size: 32))
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    if isLoading {
                        ProgressView("Chargement des statistiques...")
                            .padding()
                    } else if let stats = stats {
                        // Section du mois en cours
                        VStack(alignment: .leading, spacing: 10) {
                            Text("CE MOIS-CI")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 24))
                                .foregroundColor(.black)
                                .padding(.horizontal)
                            
                            HStack(spacing: 15) {
                                // Carte des produits consommés
                                statCard(
                                    value: stats.current_month.consumed_count,
                                    title: "Consommés",
                                    color: .green
                                )
                                
                                // Carte des produits gaspillés
                                statCard(
                                    value: stats.current_month.wasted_count,
                                    title: "Gaspillés",
                                    color: .red
                                )
                            }
                            .padding(.horizontal)
                            
                            // Taux de gaspillage
                            VStack(spacing: 10) {
                                Text("Taux de gaspillage")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                HStack {
                                    Text("\(String(format: "%.1f", stats.current_month.waste_rate))%")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(wasteRateColor(stats.current_month.waste_rate))
                                }
                                
                                // Texte d'interprétation
                                Text(wasteRateInterpretation(stats.current_month.waste_rate))
                                    .font(.system(size: 16))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(15)
                            .shadow(radius: 3)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding(.horizontal)
                        
                        // Historique global
                        VStack(alignment: .leading, spacing: 10) {
                            Text("HISTORIQUE GLOBAL")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 24))
                                .foregroundColor(.black)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            HStack(spacing: 15) {
                                // Carte des produits consommés
                                statCard(
                                    value: stats.total.consumed_count,
                                    title: "Consommés",
                                    color: .green
                                )
                                
                                // Carte des produits gaspillés
                                statCard(
                                    value: stats.total.wasted_count,
                                    title: "Gaspillés",
                                    color: .red
                                )
                            }
                            .padding(.horizontal)
                            
                            // Carte de ratio
                            VStack(spacing: 10) {
                                Text("Taux global de gaspillage")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                HStack {
                                    Text("\(String(format: "%.1f", stats.total.waste_rate))%")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(wasteRateColor(stats.total.waste_rate))
                                    
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 2, height: 60)
                                        .padding(.horizontal)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Total produits: \(stats.total.total_count)")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                        Text("C: \(stats.total.consumed_count) | G: \(stats.total.wasted_count)")
                                            .font(.subheadline)
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(15)
                            .shadow(radius: 3)
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(15)
                        .shadow(radius: 5)
                        .padding([.horizontal, .bottom])
                        
                        // Conseils pour réduire le gaspillage
                        if stats.total.waste_rate > 10 {
                            tipsSection()
                        }
                        
                    } else if let errorMessage = errorMessage {
                        Text("Erreur: \(errorMessage)")
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        Text("Aucune donnée disponible")
                            .padding()
                    }
                }
                .padding(.bottom, 80) // Espace pour la barre de navigation
            }
        }
        .onAppear {
            loadStats()
        }
    }
    
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
    
    private func statCard(value: Int, title: String, color: Color) -> some View {
        VStack {
            Text("\(value)")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.black)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.6))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
    
    private func wasteRateColor(_ rate: Double) -> Color {
        if rate < 5 {
            return .green
        } else if rate < 15 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private func wasteRateInterpretation(_ rate: Double) -> String {
        if rate < 5 {
            return "Excellent ! Votre taux de gaspillage est très faible ce mois-ci."
        } else if rate < 15 {
            return "Bon résultat. Vous pourriez encore améliorer votre consommation."
        } else if rate < 30 {
            return "Attention, votre taux de gaspillage est assez élevé. Essayez de mieux planifier vos repas."
        } else {
            return "Votre taux de gaspillage est important. Consultez nos conseils pour le réduire."
        }
    }
    
    private func tipsSection() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("CONSEILS ANTI-GASPILLAGE")
                .font(.custom("ChauPhilomeneOne-Regular", size: 20))
                .foregroundColor(.black)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 10) {
                tipRow(icon: "refrigerator", text: "Vérifiez régulièrement les dates de péremption et placez les produits qui expirent bientôt à l'avant du réfrigérateur.")
                
                tipRow(icon: "list.bullet.clipboard", text: "Planifiez vos repas à l'avance et n'achetez que ce dont vous avez besoin.")
                
                tipRow(icon: "arrow.3.trianglepath", text: "Utilisez les restes pour créer de nouveaux plats.")
                
                tipRow(icon: "freeze", text: "Congelez les aliments que vous ne consommerez pas rapidement.")
            }
            .padding()
            .background(Color.white.opacity(0.6))
            .cornerRadius(15)
            .shadow(radius: 3)
            .padding(.horizontal)
        }
        .padding()
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding([.horizontal, .bottom])
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(hex: "156585"))
                .frame(width: 30)
            
            Text(text)
                .font(.body)
                .foregroundColor(.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    StatsView()
}

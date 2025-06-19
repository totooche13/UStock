import SwiftUI

struct StatsView: View {
    @State private var stats: ConsumptionStats?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedPeriod: StatsPeriod = .month
    @State private var selectedCategory: StatsCategory = .overview
    @State private var showingExportSheet = false
    @State private var animateValues = false
    
    enum StatsPeriod: String, CaseIterable {
        case month = "Ce mois"
        case total = "Historique"
    }
    
    enum StatsCategory: String, CaseIterable {
        case overview = "Vue d'ensemble"
        case consumption = "Consommation"
        case waste = "Gaspillage"
        case trends = "Tendances"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fond uniforme plus lisible
                Color(hex: "C1DDF9")
                    .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // En-tête avec sélecteurs
                        headerSection
                        
                        if isLoading {
                            loadingView
                        } else if let stats = stats {
                            // Contenu principal selon la catégorie sélectionnée
                            Group {
                                switch selectedCategory {
                                case .overview:
                                    overviewContent(stats: stats)
                                case .consumption:
                                    consumptionContent(stats: stats)
                                case .waste:
                                    wasteContent(stats: stats)
                                case .trends:
                                    trendsContent(stats: stats)
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            
                        } else if let errorMessage = errorMessage {
                            errorView(message: errorMessage)
                        } else {
                            emptyStateView
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await refreshStats()
                }
            }
            .navigationTitle("Statistiques")
                .font(.custom("ChauPhilomeneOne-Regular", size: 32))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingExportSheet = true }) {
                            Label("Exporter les données", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: { shareStats() }) {
                            Label("Partager", systemImage: "square.and.arrow.up.on.square")
                        }
                        
                        Divider()
                        
                        Button(action: { resetStats() }) {
                            Label("Réinitialiser", systemImage: "arrow.clockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.title2)
                            .foregroundColor(Color(hex: "156585"))
                    }
                }
            }
        }
        .onAppear {
            loadStats()
            withAnimation(.easeOut(duration: 1.0).delay(0.5)) {
                animateValues = true
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            exportOptionsView
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Sélecteur de période
            periodSelector
            
            // Sélecteur de catégorie
            categorySelector
        }
        .padding(.top, 10)
    }
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(StatsPeriod.allCases, id: \.self) { period in
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedPeriod = period
                    }
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(selectedPeriod == period ? .white : Color(hex: "156585"))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(selectedPeriod == period ? Color(hex: "156585") : Color.white)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(StatsCategory.allCases, id: \.self) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                            selectedCategory = category
                        }
                    }) {
                        Text(category.rawValue)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(selectedCategory == category ? .white : Color(hex: "156585"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedCategory == category ? Color(hex: "156585") : Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private func overviewContent(stats: ConsumptionStats) -> some View {
        VStack(spacing: 20) {
            // KPI Cards
            kpiCardsSection(stats: getCurrentPeriodStats(stats))
            
            // Graphique circulaire principal
            mainCircularChart(stats: getCurrentPeriodStats(stats))
            
            // Comparaison simple entre périodes
            if selectedPeriod == .month {
                comparisonCard(current: stats.current_month, total: stats.total)
            }
            
            // Conseils intelligents
            if getCurrentPeriodStats(stats).waste_rate > 15 {
                smartTipsCard(stats: getCurrentPeriodStats(stats))
            }
        }
    }
    
    @ViewBuilder
    private func consumptionContent(stats: ConsumptionStats) -> some View {
        VStack(spacing: 20) {
            // Détails de consommation
            consumptionDetailsCard(stats: getCurrentPeriodStats(stats))
            
            // Top produits consommés (seulement si on a des données)
            // Note: Retiré car pas dans l'API actuelle
        }
    }
    
    @ViewBuilder
    private func wasteContent(stats: ConsumptionStats) -> some View {
        VStack(spacing: 20) {
            // Analyse du gaspillage
            wasteAnalysisCard(stats: getCurrentPeriodStats(stats))
            
            // Impact du gaspillage
            wasteImpactCard(stats: getCurrentPeriodStats(stats))
        }
    }
    
    @ViewBuilder
    private func trendsContent(stats: ConsumptionStats) -> some View {
        VStack(spacing: 20) {
            // Comparaison des tendances
            trendsComparisonCard(current: stats.current_month, total: stats.total)
            
            // Prédictions basées sur les données actuelles
            predictionCard(stats: getCurrentPeriodStats(stats))
        }
    }
    
    // MARK: - Individual Components
    
    private func kpiCardsSection(stats: ConsumptionStatTotal) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            KPICard(
                title: "Consommés",
                value: "\(stats.consumed_count)",
                subtitle: "produits",
                color: Color(hex: "22C55E"),
                icon: "checkmark.circle.fill",
                trend: .neutral,
                animate: animateValues
            )
            
            KPICard(
                title: "Gaspillés",
                value: "\(stats.wasted_count)",
                subtitle: "produits",
                color: Color(hex: "EF4444"),
                icon: "xmark.circle.fill",
                trend: .neutral,
                animate: animateValues
            )
            
            KPICard(
                title: "Taux de gaspillage",
                value: "\(String(format: "%.1f", stats.waste_rate))%",
                subtitle: wasteRateInterpretation(stats.waste_rate),
                color: wasteRateColor(stats.waste_rate),
                icon: "chart.pie.fill",
                trend: .neutral,
                animate: animateValues
            )
            
            KPICard(
                title: "Total",
                value: "\(stats.total_count)",
                subtitle: "produits traités",
                color: Color(hex: "156585"),
                icon: "cube.box.fill",
                trend: .neutral,
                animate: animateValues
            )
        }
    }
    
    private func mainCircularChart(stats: ConsumptionStatTotal) -> some View {
        ModernCard {
            VStack(spacing: 20) {
                HStack {
                    Text("Répartition")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "1F2937"))
                    
                    Spacer()
                    
                    Text(selectedPeriod.rawValue)
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "6B7280"))
                }
                
                ZStack {
                    // Cercle de fond
                    Circle()
                        .stroke(Color(hex: "F3F4F6"), lineWidth: 20)
                        .frame(width: 200, height: 200)
                    
                    // Portion consommée
                    if stats.total_count > 0 {
                        Circle()
                            .trim(from: 0, to: animateValues ? CGFloat(stats.consumed_count) / CGFloat(stats.total_count) : 0)
                            .stroke(
                                Color(hex: "22C55E"),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 1.5).delay(0.5), value: animateValues)
                    }
                    
                    // Texte central
                    VStack(spacing: 4) {
                        Text("\(stats.consumed_count)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "22C55E"))
                        
                        Text("sur \(stats.total_count)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "6B7280"))
                        
                        Text("consommés")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "9CA3AF"))
                    }
                }
                
                // Légende
                HStack(spacing: 40) {
                    LegendItem(color: Color(hex: "22C55E"), label: "Consommés", value: stats.consumed_count)
                    LegendItem(color: Color(hex: "EF4444"), label: "Gaspillés", value: stats.wasted_count)
                }
            }
        }
    }
    
    private func consumptionDetailsCard(stats: ConsumptionStatTotal) -> some View {
        ModernCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "22C55E"))
                    
                    Text("Analyse de Consommation")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "1F2937"))
                    
                    Spacer()
                }
                
                VStack(spacing: 16) {
                    DetailRow(
                        title: "Taux de réussite",
                        value: stats.total_count > 0 ? "\(String(format: "%.1f", (Double(stats.consumed_count) / Double(stats.total_count)) * 100))%" : "0%",
                        icon: "target",
                        color: Color(hex: "22C55E")
                    )
                    
                    DetailRow(
                        title: "Produits par jour (moyenne)",
                        value: "\(String(format: "%.1f", Double(stats.total_count) / 30.0))",
                        icon: "calendar",
                        color: Color(hex: "3B82F6")
                    )
                    
                    DetailRow(
                        title: "Efficacité",
                        value: stats.waste_rate < 10 ? "Excellente" : stats.waste_rate < 20 ? "Bonne" : "À améliorer",
                        icon: "star.fill",
                        color: wasteRateColor(stats.waste_rate)
                    )
                }
            }
        }
    }
    
    private func wasteAnalysisCard(stats: ConsumptionStatTotal) -> some View {
        ModernCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "F59E0B"))
                    
                    Text("Analyse du Gaspillage")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "1F2937"))
                    
                    Spacer()
                }
                
                VStack(spacing: 16) {
                    DetailRow(
                        title: "Taux de gaspillage",
                        value: "\(String(format: "%.1f", stats.waste_rate))%",
                        icon: "chart.pie",
                        color: wasteRateColor(stats.waste_rate)
                    )
                    
                    DetailRow(
                        title: "Produits gaspillés",
                        value: "\(stats.wasted_count) sur \(stats.total_count)",
                        icon: "trash",
                        color: Color(hex: "EF4444")
                    )
                    
                    DetailRow(
                        title: "Statut",
                        value: wasteRateInterpretation(stats.waste_rate),
                        icon: "info.circle",
                        color: wasteRateColor(stats.waste_rate)
                    )
                }
            }
        }
    }
    
    private func wasteImpactCard(stats: ConsumptionStatTotal) -> some View {
        ModernCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "22C55E"))
                    
                    Text("Impact Environnemental")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "1F2937"))
                    
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    Text("En évitant le gaspillage de \(stats.consumed_count) produits :")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "6B7280"))
                    
                    ImpactRow(
                        icon: "drop.fill",
                        title: "Eau économisée",
                        value: "\(stats.consumed_count * 50)L",
                        color: Color(hex: "3B82F6")
                    )
                    
                    ImpactRow(
                        icon: "leaf.arrow.circlepath",
                        title: "CO₂ évité",
                        value: "\(String(format: "%.1f", Double(stats.consumed_count) * 0.3))kg",
                        color: Color(hex: "22C55E")
                    )
                }
            }
        }
    }
    
    private func comparisonCard(current: ConsumptionStatTotal, total: ConsumptionStatTotal) -> some View {
        ModernCard {
            VStack(spacing: 16) {
                Text("Comparaison Mensuelle vs Historique")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "1F2937"))
                
                HStack(spacing: 30) {
                    ComparisonColumn(
                        title: "Ce mois",
                        wasteRate: current.waste_rate,
                        totalCount: current.total_count,
                        isMain: true
                    )
                    
                    Rectangle()
                        .fill(Color(hex: "E5E7EB"))
                        .frame(width: 1, height: 80)
                    
                    ComparisonColumn(
                        title: "Historique",
                        wasteRate: total.waste_rate,
                        totalCount: total.total_count,
                        isMain: false
                    )
                }
            }
        }
    }
    
    private func trendsComparisonCard(current: ConsumptionStatTotal, total: ConsumptionStatTotal) -> some View {
        ModernCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Évolution des Tendances")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "1F2937"))
                
                let improvement = total.waste_rate - current.waste_rate
                
                VStack(spacing: 12) {
                    TrendRow(
                        title: "Évolution du gaspillage",
                        value: improvement > 0 ? "↓ \(String(format: "%.1f", improvement))%" : "↑ \(String(format: "%.1f", abs(improvement)))%",
                        isPositive: improvement > 0
                    )
                    
                    TrendRow(
                        title: "Performance actuelle",
                        value: current.waste_rate < 15 ? "Bonne" : "À améliorer",
                        isPositive: current.waste_rate < 15
                    )
                }
            }
        }
    }
    
    private func predictionCard(stats: ConsumptionStatTotal) -> some View {
        ModernCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "crystal.ball")
                        .font(.title2)
                        .foregroundColor(Color(hex: "8B5CF6"))
                    
                    Text("Prédictions")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "1F2937"))
                    
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    let predictedRate = max(0, stats.waste_rate - 2) // Prédiction optimiste
                    
                    DetailRow(
                        title: "Objectif atteignable",
                        value: "\(String(format: "%.1f", predictedRate))% de gaspillage",
                        icon: "target",
                        color: Color(hex: "22C55E")
                    )
                    
                    Text("Basé sur votre progression actuelle")
                        .font(.caption)
                        .foregroundColor(Color(hex: "9CA3AF"))
                }
            }
        }
    }
    
    private func smartTipsCard(stats: ConsumptionStatTotal) -> some View {
        ModernCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(Color(hex: "F59E0B"))
                    
                    Text("Conseils Personnalisés")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "1F2937"))
                    
                    Spacer()
                }
                
                VStack(spacing: 12) {
                    TipRow(
                        text: "Votre taux de gaspillage est élevé (\(String(format: "%.1f", stats.waste_rate))%). Planifiez mieux vos repas.",
                        priority: .high
                    )
                    
                    TipRow(
                        text: "Vérifiez les dates de péremption 2 fois par semaine.",
                        priority: .medium
                    )
                    
                    TipRow(
                        text: "Placez les produits qui expirent bientôt devant.",
                        priority: .low
                    )
                }
            }
        }
    }
    
    // MARK: - Supporting Views
    
    private var loadingView: some View {
        ModernCard {
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "156585")))
                
                Text("Analyse de vos données...")
                    .font(.headline)
                    .foregroundColor(Color(hex: "6B7280"))
            }
            .frame(height: 150)
        }
    }
    
    private var emptyStateView: some View {
        ModernCard {
            VStack(spacing: 20) {
                Image(systemName: "chart.pie")
                    .font(.system(size: 60))
                    .foregroundColor(Color(hex: "156585").opacity(0.6))
                
                Text("Aucune donnée")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "1F2937"))
                
                Text("Commencez à scanner des produits pour voir vos statistiques")
                    .font(.body)
                    .foregroundColor(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
                
                Button(action: {}) {
                    Text("Scanner un produit")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color(hex: "156585"))
                        .cornerRadius(12)
                }
                .padding(.top)
            }
            .frame(height: 300)
        }
    }
    
    private var exportOptionsView: some View {
        NavigationView {
            List {
                Section("Format d'export") {
                    ExportOption(title: "PDF", icon: "doc.text", description: "Rapport complet")
                    ExportOption(title: "CSV", icon: "tablecells", description: "Données brutes")
                    ExportOption(title: "Image", icon: "photo", description: "Graphiques visuels")
                }
                
                Section("Période") {
                    ForEach(StatsPeriod.allCases, id: \.self) { period in
                        HStack {
                            Text(period.rawValue)
                            Spacer()
                            if period == selectedPeriod {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "156585"))
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPeriod = period
                        }
                    }
                }
            }
            .navigationTitle("Exporter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        showingExportSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getCurrentPeriodStats(_ stats: ConsumptionStats) -> ConsumptionStatTotal {
        switch selectedPeriod {
        case .month:
            return stats.current_month
        case .total:
            return stats.total
        }
    }
    
    private func loadStats() {
        isLoading = true
        errorMessage = nil
        
        ProductConsumptionService.shared.getStats { result in
            withAnimation(.easeInOut(duration: 0.5)) {
                self.isLoading = false
                
                switch result {
                case .success(let stats):
                    self.stats = stats
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func refreshStats() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        loadStats()
    }
    
    private func shareStats() {
        // Logique de partage
    }
    
    private func resetStats() {
        // Logique de réinitialisation
    }
    
    private func wasteRateColor(_ rate: Double) -> Color {
        switch rate {
        case 0..<5: return Color(hex: "22C55E")
        case 5..<15: return Color(hex: "F59E0B")
        case 15..<30: return Color(hex: "F97316")
        default: return Color(hex: "EF4444")
        }
    }
    
    private func wasteRateInterpretation(_ rate: Double) -> String {
        switch rate {
        case 0..<5: return "Excellent"
        case 5..<15: return "Bon"
        case 15..<30: return "À améliorer"
        default: return "Critique"
        }
    }
    
    private func errorView(message: String) -> some View {
        ModernCard {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(Color(hex: "F59E0B"))
                
                Text("Erreur")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "1F2937"))
                
                Text(message)
                    .font(.body)
                    .foregroundColor(Color(hex: "6B7280"))
                    .multilineTextAlignment(.center)
                
                Button("Réessayer") {
                    loadStats()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(height: 200)
        }
    }
}

// MARK: - Supporting Components

struct ModernCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            )
    }
}

struct KPICard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String
    let trend: TrendDirection
    let animate: Bool
    
    enum TrendDirection {
        case up, down, neutral
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(animate ? value : "0")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: "1F2937"))
                    .animation(.easeInOut(duration: 1.0).delay(0.3), value: animate)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color(hex: "1F2937"))
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color(hex: "6B7280"))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    let value: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(Color(hex: "6B7280"))
                
                Text("\(value)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "1F2937"))
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "1F2937"))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ImpactRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "1F2937"))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct ComparisonColumn: View {
    let title: String
    let wasteRate: Double
    let totalCount: Int
    let isMain: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(isMain ? Color(hex: "156585") : Color(hex: "6B7280"))
            
            Text("\(String(format: "%.1f", wasteRate))%")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(isMain ? Color(hex: "156585") : Color(hex: "9CA3AF"))
            
            Text("gaspillage")
                .font(.caption)
                .foregroundColor(Color(hex: "6B7280"))
            
            Text("\(totalCount) produits")
                .font(.caption)
                .foregroundColor(Color(hex: "9CA3AF"))
        }
    }
}

struct TrendRow: View {
    let title: String
    let value: String
    let isPositive: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isPositive ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                .font(.title3)
                .foregroundColor(isPositive ? Color(hex: "22C55E") : Color(hex: "EF4444"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "1F2937"))
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isPositive ? Color(hex: "22C55E") : Color(hex: "EF4444"))
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct TipRow: View {
    let text: String
    let priority: Priority
    
    enum Priority {
        case high, medium, low
        
        var color: Color {
            switch self {
            case .high: return Color(hex: "EF4444")
            case .medium: return Color(hex: "F59E0B")
            case .low: return Color(hex: "3B82F6")
            }
        }
        
        var icon: String {
            switch self {
            case .high: return "exclamationmark.circle.fill"
            case .medium: return "info.circle.fill"
            case .low: return "lightbulb.fill"
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: priority.icon)
                .font(.caption)
                .foregroundColor(priority.color)
                .frame(width: 16)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color(hex: "1F2937"))
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ExportOption: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Color(hex: "156585"))
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color(hex: "1F2937"))
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(Color(hex: "6B7280"))
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Data Models

struct ConsumptionStats: Codable {
    let total: ConsumptionStatTotal
    let current_month: ConsumptionStatTotal
}

struct ConsumptionStatTotal: Codable {
    let consumed_count: Int
    let wasted_count: Int
    let total_count: Int
    let waste_rate: Double
}

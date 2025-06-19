import SwiftUI

struct InventorySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // États des paramètres
    @State private var scannerSound = UserDefaults.standard.bool(forKey: "scanner_sound_enabled")
    @State private var hapticsEnabled = UserDefaults.standard.bool(forKey: "haptics_enabled")
    @State private var showCarousel = UserDefaults.standard.object(forKey: "show_carousel") == nil ? true : UserDefaults.standard.bool(forKey: "show_carousel")
    @State private var dateFormat = DateDisplayFormat(rawValue: UserDefaults.standard.string(forKey: "date_format") ?? "long") ?? .long
    @State private var alertThreshold = UserDefaults.standard.integer(forKey: "alert_threshold") == 0 ? 3 : UserDefaults.standard.integer(forKey: "alert_threshold")
    @State private var itemSize = ItemSize(rawValue: UserDefaults.standard.string(forKey: "item_size") ?? "normal") ?? .normal
    @State private var displayMode = DisplayMode(rawValue: UserDefaults.standard.string(forKey: "display_mode") ?? "list") ?? .list
    @State private var sortOption = SortOption(rawValue: UserDefaults.standard.string(forKey: "sort_option") ?? "expiration") ?? .expiration
    
    // Couleurs d'alerte personnalisées
    @State private var expiredColor = UserDefaults.standard.colorForKey("expired_color") ?? .red
    @State private var urgentColor = UserDefaults.standard.colorForKey("urgent_color") ?? .orange
    @State private var goodColor = UserDefaults.standard.colorForKey("good_color") ?? .green
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "C1DDF9").edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // En-tête
                        VStack(spacing: 10) {
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 50))
                                .foregroundColor(Color(hex: "156585"))
                            
                            Text("Paramètres de l'inventaire")
                                .font(.custom("ChauPhilomeneOne-Regular", size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // SCANNER
                        SettingsSection(title: "Scanner", icon: "barcode.viewfinder") {
                            VStack(spacing: 15) {
                                ToggleSetting(
                                    title: "Son du scanner",
                                    description: "Jouer un bip lors du scan",
                                    isOn: $scannerSound,
                                    icon: "speaker.wave.2.fill"
                                )
                                
                                ToggleSetting(
                                    title: "Vibrations",
                                    description: "Retour haptique lors des actions",
                                    isOn: $hapticsEnabled,
                                    icon: "iphone.radiowaves.left.and.right"
                                )
                            }
                        }
                        
                        // AFFICHAGE
                        SettingsSection(title: "Affichage", icon: "rectangle.grid.1x2") {
                            VStack(spacing: 15) {
                                // Carrousel
                                ToggleSetting(
                                    title: "Afficher le carrousel",
                                    description: "Produits qui périment bientôt",
                                    isOn: $showCarousel,
                                    icon: "rectangle.3.group"
                                )
                                
                                // Format des dates
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Format des dates", systemImage: "calendar")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    
                                    Picker("Format", selection: $dateFormat) {
                                        Text("Court (21 juin)").tag(DateDisplayFormat.short)
                                        Text("Long (21 juin 2025)").tag(DateDisplayFormat.long)
                                        Text("Relatif (dans 3 jours)").tag(DateDisplayFormat.relative)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                // Taille des éléments
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Taille des éléments", systemImage: "textformat.size")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    
                                    Picker("Taille", selection: $itemSize) {
                                        Text("Compact").tag(ItemSize.compact)
                                        Text("Normal").tag(ItemSize.normal)
                                        Text("Large").tag(ItemSize.large)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                // Mode d'affichage
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Mode d'affichage", systemImage: "rectangle.grid.2x2")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    
                                    Picker("Mode", selection: $displayMode) {
                                        Text("Liste").tag(DisplayMode.list)
                                        Text("Grille").tag(DisplayMode.grid)
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                            }
                        }
                        
                        // TRI ET FILTRES
                        SettingsSection(title: "Organisation", icon: "arrow.up.arrow.down") {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Tri par défaut", systemImage: "arrow.up.arrow.down.square")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                
                                Picker("Tri", selection: $sortOption) {
                                    Text("Date d'expiration").tag(SortOption.expiration)
                                    Text("Nom du produit").tag(SortOption.name)
                                    Text("Quantité").tag(SortOption.quantity)
                                    Text("Ajout récent").tag(SortOption.dateAdded)
                                }
                                .pickerStyle(MenuPickerStyle())
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(8)
                            }
                        }
                        
                        // ALERTES
                        SettingsSection(title: "Alertes", icon: "bell.badge") {
                            VStack(spacing: 15) {
                                // Seuil d'alerte
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Seuil d'alerte", systemImage: "exclamationmark.triangle")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    
                                    Text("Considérer comme \"bientôt périmé\" à partir de :")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Picker("Seuil", selection: $alertThreshold) {
                                        ForEach(1...7, id: \.self) { day in
                                            Text("\(day) jour\(day > 1 ? "s" : "")")
                                                .tag(day)
                                        }
                                    }
                                    .pickerStyle(SegmentedPickerStyle())
                                }
                                
                                // Couleurs d'alerte
                                VStack(alignment: .leading, spacing: 12) {
                                    Label("Couleurs d'alerte", systemImage: "paintbrush")
                                        .font(.headline)
                                        .foregroundColor(.black)
                                    
                                    VStack(spacing: 10) {
                                        ColorPickerRow(
                                            title: "Produits périmés",
                                            color: $expiredColor,
                                            defaultColor: .red
                                        )
                                        
                                        ColorPickerRow(
                                            title: "Expire bientôt",
                                            color: $urgentColor,
                                            defaultColor: .orange
                                        )
                                        
                                        ColorPickerRow(
                                            title: "Encore bon",
                                            color: $goodColor,
                                            defaultColor: .green
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Aperçu des modifications
                        PreviewSection(
                            dateFormat: dateFormat,
                            itemSize: itemSize,
                            expiredColor: expiredColor,
                            urgentColor: urgentColor,
                            goodColor: goodColor
                        )
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        saveSettings()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.light)
    }
    
    // MARK: - Fonctions privées
    
    private func saveSettings() {
        // Paramètres booléens
        UserDefaults.standard.set(scannerSound, forKey: "scanner_sound_enabled")
        UserDefaults.standard.set(hapticsEnabled, forKey: "haptics_enabled")
        UserDefaults.standard.set(showCarousel, forKey: "show_carousel")
        
        // Paramètres énumérés
        UserDefaults.standard.set(dateFormat.rawValue, forKey: "date_format")
        UserDefaults.standard.set(itemSize.rawValue, forKey: "item_size")
        UserDefaults.standard.set(displayMode.rawValue, forKey: "display_mode")
        UserDefaults.standard.set(sortOption.rawValue, forKey: "sort_option")
        
        // Paramètres numériques
        UserDefaults.standard.set(alertThreshold, forKey: "alert_threshold")
        
        // Couleurs
        UserDefaults.standard.setColor(expiredColor, forKey: "expired_color")
        UserDefaults.standard.setColor(urgentColor, forKey: "urgent_color")
        UserDefaults.standard.setColor(goodColor, forKey: "good_color")
        
        print("💾 Paramètres d'inventaire sauvegardés")
        
        // 🔹 NOUVEAU : Notifier les autres vues que les paramètres ont changé
        NotificationCenter.default.post(name: .settingsChanged, object: nil)
    }
}

// MARK: - Énumérations

enum DateDisplayFormat: String, CaseIterable {
    case short = "short"
    case long = "long"
    case relative = "relative"
}

enum ItemSize: String, CaseIterable {
    case compact = "compact"
    case normal = "normal"
    case large = "large"
}

enum DisplayMode: String, CaseIterable {
    case list = "list"
    case grid = "grid"
}

enum SortOption: String, CaseIterable {
    case expiration = "expiration"
    case name = "name"
    case quantity = "quantity"
    case dateAdded = "dateAdded"
}

// MARK: - Composants personnalisés

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color(hex: "156585"))
                
                Text(title)
                    .font(.custom("ChauPhilomeneOne-Regular", size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            
            content
        }
        .padding(20)
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
}

struct ToggleSetting: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "156585"))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(Color(hex: "156585"))
        }
    }
}

struct ColorPickerRow: View {
    let title: String
    @Binding var color: Color
    let defaultColor: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.black)
            
            Spacer()
            
            ColorPicker("", selection: $color)
                .frame(width: 40, height: 30)
            
            Button("Reset") {
                color = defaultColor
            }
            .font(.caption)
            .foregroundColor(Color(hex: "156585"))
        }
    }
}

struct PreviewSection: View {
    let dateFormat: DateDisplayFormat
    let itemSize: ItemSize
    let expiredColor: Color
    let urgentColor: Color
    let goodColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "eye")
                    .font(.title2)
                    .foregroundColor(Color(hex: "156585"))
                
                Text("Aperçu")
                    .font(.custom("ChauPhilomeneOne-Regular", size: 20))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
            
            VStack(spacing: 8) {
                // Aperçu des couleurs
                HStack(spacing: 15) {
                    ColorPreview(color: expiredColor, label: "Périmé")
                    ColorPreview(color: urgentColor, label: "Urgent")
                    ColorPreview(color: goodColor, label: "Bon")
                }
                
                // Aperçu du format de date
                Text("Format de date : \(previewDate)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                // Aperçu de la taille
                Text("Taille des éléments : \(itemSize.rawValue.capitalized)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.8))
        .cornerRadius(15)
        .shadow(radius: 3)
    }
    
    private var previewDate: String {
        let date = Calendar.current.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        switch dateFormat {
        case .short:
            return date.shortFrenchString
        case .long:
            return date.fullFrenchString
        case .relative:
            return "Dans 2 jours"
        }
    }
}

struct ColorPreview: View {
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Extensions UserDefaults pour les couleurs

extension UserDefaults {
    func setColor(_ color: Color, forKey key: String) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let colorData = [red, green, blue, alpha]
        set(colorData, forKey: key)
    }
    
    func colorForKey(_ key: String) -> Color? {
        guard let colorData = object(forKey: key) as? [CGFloat],
              colorData.count == 4 else { return nil }
        
        return Color(.sRGB, red: colorData[0], green: colorData[1], blue: colorData[2], opacity: colorData[3])
    }
}

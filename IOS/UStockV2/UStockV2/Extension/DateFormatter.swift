import Foundation
import SwiftUI

extension DateFormatter {
    
    // Formatter pour affichage complet (ex: "10 octobre 2022")
    static let fullFrenchDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()
    
    // Formatter pour affichage court avec jour (ex: "10 oct. 2022")
    static let shortFrenchDisplay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
    
    // Formatter pour l'API (format ISO)
    static let apiFormat: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // Formatter pour parser les dates reçues de l'API
    static let inputParser: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yy"
        return formatter
    }()
}

// Extension pour faciliter les conversions de dates
extension Date {
    
    // Convertir en format d'affichage complet français
    var fullFrenchString: String {
        return DateFormatter.fullFrenchDisplay.string(from: self)
    }
    
    // Convertir en format d'affichage court français
    var shortFrenchString: String {
        return DateFormatter.shortFrenchDisplay.string(from: self)
    }
    
    // Convertir en format API
    var apiString: String {
        return DateFormatter.apiFormat.string(from: self)
    }
    
    // 🔹 NOUVEAU : Calculer les jours restants avec logique corrigée
    var daysFromNow: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let expirationDay = calendar.startOfDay(for: self)
        
        let components = calendar.dateComponents([.day], from: today, to: expirationDay)
        return components.day ?? 0
    }
    
    // 🔹 NOUVEAU : Vérifier si le produit est vraiment périmé (jour dépassé)
    var isExpired: Bool {
        return daysFromNow < 0
    }
    
    // 🔹 NOUVEAU : Obtenir la couleur selon les jours restants
    var expirationColor: Color {
        let days = daysFromNow
        
        if isExpired {
            return .red  // Périmé = rouge
        } else if days <= 1 {
            return .red  // 0-1 jour = rouge
        } else if days <= 3 {
            return .orange  // 2-3 jours = orange
        } else {
            return .green  // 4+ jours = vert
        }
    }
    
    // 🔹 NOUVEAU : Texte d'affichage des jours restants
    var daysRemainingText: String {
        let days = daysFromNow
        
        if isExpired {
            let daysPassed = abs(days)
            return daysPassed == 1 ? "Périmé depuis 1 jour" : "Périmé depuis \(daysPassed) jours"
        } else if days == 0 {
            return "Expire aujourd'hui"
        } else if days == 1 {
            return "Expire demain"
        } else {
            return "Expire dans \(days) jours"
        }
    }
}

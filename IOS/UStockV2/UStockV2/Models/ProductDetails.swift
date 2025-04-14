//
//  ProductDetails.swift
//  UStockV2
//
//  Created by Theo RUELLAN on 20/03/2025.
//


import SwiftUI

struct ProductDetails {
    let barcode: String
    let brand: String
    let contentSize: String
    let nutriscore: String
    let imageUrl: String
}

struct Produit: Identifiable {
    let id: UUID
    let nom: String
    let peremption: String
    let joursRestants: Int
    let quantite: Int
    let image: String // On gardera ce champ mais il sera vide
    let stockId: Int?
    let productDetails: ProductDetails?
    
    init(id: UUID = UUID(), nom: String, peremption: String, joursRestants: Int, quantite: Int, image: String, stockId: Int? = nil, productDetails: ProductDetails? = nil) {
        self.id = id
        self.nom = nom
        self.peremption = peremption
        self.joursRestants = joursRestants
        self.quantite = quantite
        self.image = image
        self.stockId = stockId
        self.productDetails = productDetails
    }
}
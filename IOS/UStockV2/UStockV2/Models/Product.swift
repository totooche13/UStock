import Foundation

struct Product: Codable, Identifiable {
    let id: Int
    let barcode: String
    let product_name: String
    let brand: String?
    let content_size: String?
    let nutriscore: String?
    let image_url: String?
}

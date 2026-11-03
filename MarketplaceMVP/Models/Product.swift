import Foundation

/// A single software product listing in the marketplace.
struct Product: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var description: String
    var price: Double
    var category: String
    var emoji: String          // placeholder "icon" — swap for real app icons/screenshots later
    var sellerName: String     // the developer/publisher
    var isAvailable: Bool = true
    var createdAt: Date = Date()

    var priceText: String {
        price.formatted(.currency(code: "USD"))
    }
}

/// Categories available when posting a software product.
extension Product {
    static let categories = ["iOS Apps", "Android Apps", "Web Apps", "Games", "Productivity", "Design", "Other"]
}

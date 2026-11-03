import Foundation

/// Server-backed store — talks to the Node.js + PostgreSQL backend in the
/// `backend` folder. Views only call the methods here, so the data source
/// can be swapped without touching any view.
final class ProductStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published var errorMessage: String?

    /// Where the backend lives — CHANGE THIS FOR THE DEMO:
    /// - Backend on the same Mac as the simulator: "http://127.0.0.1:3000/api"
    /// - Backend on the Windows PC:               "http://<PC-LAN-IP>:3000/api"
    private let baseURL = URL(string: "http://127.0.0.1:3000/api")!

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .custom(Self.decodeDate)
    }

    // MARK: - Actions (call from a Task)

    func load() async {
        do {
            products = try await send([Product].self, "GET", "products")
            clearError()
        } catch {
            setError("Could not load products", error)
            // Offline fallback: before the backend is running, keep the
            // app demoable with local sample data.
            if products.isEmpty {
                products = Self.sampleProducts()
            }
        }
    }

    func add(_ product: Product) async {
        do {
            let body = try encoder.encode(product)
            let created: Product = try await send(Product.self, "POST", "products", body: body)
            products.insert(created, at: 0)
            clearError()
        } catch {
            setError("Could not post product", error)
            if isOffline(error) {
                products.insert(product, at: 0)
            }
        }
    }

    func delete(_ product: Product) async {
        do {
            try await send("DELETE", "products/\(product.id.uuidString)")
            products.removeAll { $0.id == product.id }
            clearError()
        } catch {
            setError("Could not delete product", error)
            if isOffline(error) {
                products.removeAll { $0.id == product.id }
            }
        }
    }

    func toggleAvailability(_ product: Product) async {
        do {
            let payload = ["isAvailable": !product.isAvailable]
            let body = try JSONSerialization.data(withJSONObject: payload)
            let updated: Product = try await send(
                Product.self, "PATCH", "products/\(product.id.uuidString)/availability", body: body
            )
            if let index = products.firstIndex(where: { $0.id == updated.id }) {
                products[index] = updated
            }
            clearError()
        } catch {
            setError("Could not update product", error)
            if isOffline(error), let index = products.firstIndex(where: { $0.id == product.id }) {
                products[index].isAvailable.toggle()
            }
        }
    }

    // MARK: - Networking

    /// Decoding variant.
    private func send<T: Decodable>(
        _ type: T.Type, _ method: String, _ path: String, body: Data? = nil
    ) async throws -> T {
        let data = try await perform(method: method, path: path, body: body)
        return try decoder.decode(T.self, from: data)
    }

    /// No-content variant (DELETE returns 204).
    private func send(_ method: String, _ path: String, body: Data? = nil) async throws {
        _ = try await perform(method: method, path: path, body: body)
    }

    private func perform(method: String, path: String, body: Data?) async throws -> Data {
        var request = URLRequest(url: baseURL.appendingPathComponent(path))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw URLError(.badServerResponse)
        }
        return data
    }

    // MARK: - Dates (ISO 8601, with or without fractional seconds)

    private static let fractionalFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let plainFormatter = ISO8601DateFormatter()

    private static func decodeDate(_ decoder: Decoder) throws -> Date {
        let string = try decoder.singleValueContainer().decode(String.self)
        if let date = fractionalFormatter.date(from: string) { return date }
        if let date = plainFormatter.date(from: string) { return date }
        throw DecodingError.dataCorrupted(.init(
            codingPath: decoder.codingPath,
            debugDescription: "Unexpected date format: \(string)"
        ))
    }

    // MARK: - Errors

    /// True when the backend simply isn't reachable (offline demo mode) —
    /// as opposed to the server actively rejecting a request.
    private func isOffline(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .cannotConnectToHost, .cannotFindHost, .timedOut,
             .networkConnectionLost, .notConnectedToInternet:
            return true
        default:
            return false
        }
    }

    private func clearError() {
        errorMessage = nil
    }

    private func setError(_ message: String, _ error: Error) {
        errorMessage = "\(message): \(error.localizedDescription)"
    }

    // MARK: - Offline sample data (shown until the backend responds)

    private static func sampleProducts() -> [Product] {
        [
            Product(name: "FitTrack Pro",
                    description: "iOS fitness tracking app with workout plans, step tracking and health sync.",
                    price: 4.99, category: "iOS Apps", emoji: "📱", sellerName: "Alex"),
            Product(name: "TaskFlow",
                    description: "Web-based task management tool for teams with kanban boards and reports.",
                    price: 9.99, category: "Web Apps", emoji: "💻", sellerName: "Maria"),
            Product(name: "Puzzle Quest HD",
                    description: "Addictive puzzle game for mobile with 200 levels and daily challenges.",
                    price: 2.99, category: "Games", emoji: "🎮", sellerName: "Sam"),
            Product(name: "PaletteKit",
                    description: "Design tool with 500+ icon pack and color palette generator for developers.",
                    price: 14.99, category: "Design", emoji: "🎨", sellerName: "Alex"),
            Product(name: "NoteMaster",
                    description: "Cross-platform notes app with cloud sync, tags and markdown support.",
                    price: 6.99, category: "Productivity", emoji: "📝", sellerName: "Maria")
        ]
    }
}

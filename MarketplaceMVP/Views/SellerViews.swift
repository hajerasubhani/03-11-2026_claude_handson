import SwiftUI

/// Seller display: post products and manage your listings.
struct SellerHomeView: View {
    @EnvironmentObject private var store: ProductStore
    @State private var sellerName = "Me"

    private var myProducts: [Product] {
        store.products.filter { $0.sellerName == sellerName }
    }

    var body: some View {
        List {
            Section("Your Listings (\(myProducts.count))") {
                if myProducts.isEmpty {
                    Text("You haven't posted anything yet. Tap + to add your first product.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(myProducts) { product in
                        SellerRow(product: product)
                    }
                    .onDelete(perform: delete)
                }
            }
        }
        .refreshable { await store.load() }
        .task { await store.load() }
        .navigationTitle("Seller")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    AddProductView(sellerName: sellerName)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            Task { await store.delete(myProducts[index]) }
        }
    }
}

private struct SellerRow: View {
    let product: Product
    @EnvironmentObject private var store: ProductStore

    var body: some View {
        HStack(spacing: 12) {
            Text(product.emoji)
                .font(.largeTitle)
                .frame(width: 52, height: 52)
                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                Text(product.priceText)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }

            Spacer()

            // Toggle listing on/off without deleting it.
            Button {
                Task { await store.toggleAvailability(product) }
            } label: {
                Image(systemName: product.isAvailable ? "eye.fill" : "eye.slash")
                    .foregroundStyle(product.isAvailable ? .blue : .secondary)
            }
            .buttonStyle(.borderless)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                store.delete(product)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

/// Form for posting a new product.
struct AddProductView: View {
    let sellerName: String

    @EnvironmentObject private var store: ProductStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var descriptionText = ""
    @State private var priceText = ""
    @State private var category = Product.categories.first!
    @State private var emoji = "📦"

    private let emojiChoices = ["📱", "💻", "🎮", "🧩", "📝", "🎨", "📊", "📷", "🎵", "🤖", "🗂️", "⚙️"]

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Double(priceText) != nil
            && Double(priceText) ?? 0 > 0
    }

    var body: some View {
        Form {
            Section("Product") {
                TextField("Name", text: $name)

                TextField("Description", text: $descriptionText, axis: .vertical)
                    .lineLimit(3...6)

                TextField("Price (USD)", text: $priceText)
                    .keyboardType(.decimalPad)

                Picker("Category", selection: $category) {
                    ForEach(Product.categories, id: \.self) { Text($0) }
                }
            }

            Section("Icon (placeholder for photo)") {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                    ForEach(emojiChoices, id: \.self) { choice in
                        Button {
                            emoji = choice
                        } label: {
                            Text(choice)
                                .font(.title)
                                .frame(width: 44, height: 44)
                                .background(
                                    emoji == choice ? Color.blue.opacity(0.2) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle("Add Product")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Post") {
                    save()
                }
                .disabled(!isFormValid)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    private func save() {
        let product = Product(
            name: name.trimmingCharacters(in: .whitespaces),
            description: descriptionText,
            price: Double(priceText) ?? 0,
            category: category,
            emoji: emoji,
            sellerName: sellerName
        )
        Task {
            await store.add(product)
            dismiss()
        }
    }
}

#Preview {
    NavigationStack { SellerHomeView() }
        .environmentObject(ProductStore())
}

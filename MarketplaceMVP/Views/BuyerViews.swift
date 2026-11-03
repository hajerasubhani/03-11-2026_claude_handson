import SwiftUI

/// Buyer display: search + grid of all available listings, tap for details.
struct BuyerHomeView: View {
    @EnvironmentObject private var store: ProductStore
    @State private var searchText = ""
    @State private var selectedCategory: String?

    private var filteredProducts: [Product] {
        store.products.filter { product in
            product.isAvailable
                && (selectedCategory == nil || product.category == selectedCategory)
                && (searchText.isEmpty
                    || product.name.localizedCaseInsensitiveContains(searchText)
                    || product.description.localizedCaseInsensitiveContains(searchText))
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]

    var body: some View {
        ScrollView {
            if !filteredProducts.isEmpty {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filteredProducts) { product in
                        NavigationLink(value: product) {
                            ProductCard(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            } else {
                ContentUnavailableView.search(
                    text: "No products found",
                    description: Text("Try a different search or category.")
                )
                .padding(.top, 100)
            }
        }
        .searchable(text: $searchText, prompt: "Search products")
        .refreshable { await store.load() }
        .task { await store.load() }
        .navigationTitle("Buyer")
        .navigationDestination(for: Product.self) { product in
            ProductDetailView(product: product)
        }
        .safeAreaInset(edge: .top) { categoryBar }
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(label: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(Product.categories, id: \.self) { category in
                    CategoryChip(label: category, isSelected: selectedCategory == category) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.bar)
    }
}

private struct CategoryChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.blue.opacity(0.12), in: Capsule())
                .foregroundStyle(isSelected ? .white : .blue)
        }
        .buttonStyle(.plain)
    }
}

struct ProductCard: View {
    let product: Product

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(product.emoji)
                .font(.system(size: 56))
                .frame(maxWidth: .infinity)
                .frame(height: 110)
                .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)

            Text(product.priceText)
                .font(.headline)
                .foregroundStyle(.blue)
        }
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
    }
}

/// Product detail — full description with a mock "contact seller" action.
struct ProductDetailView: View {
    let product: Product
    @EnvironmentObject private var store: ProductStore
    @State private var showContactConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(product.emoji)
                    .font(.system(size: 96))
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

                Text(product.name)
                    .font(.title.bold())

                Text(product.priceText)
                    .font(.title2)
                    .foregroundStyle(.blue)

                Label(product.sellerName, systemImage: "person.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(product.description)
                    .font(.body)

                Text(product.category)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12), in: Capsule())

                if !product.isAvailable {
                    Label("No longer available", systemImage: "xmark.circle")
                        .font(.headline)
                        .foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    showContactConfirmation = true
                } label: {
                    Text("Message Seller")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!product.isAvailable)
            }
        }
        .alert("Contact Seller", isPresented: $showContactConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("In the full app this would open a chat with \(product.sellerName).")
        }
    }
}

#Preview {
    NavigationStack { BuyerHomeView() }
        .environmentObject(ProductStore())
}

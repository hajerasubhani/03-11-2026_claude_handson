import SwiftUI

/// Launch screen — pick which display to use: Buyer or Seller.
struct RootView: View {
    @EnvironmentObject private var store: ProductStore
    @State private var selectedRole: RootView.Role?

    enum Role: String, CaseIterable, Identifiable {
        case buyer = "Buyer"
        case seller = "Seller"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Marketplace")
                    .font(.largeTitle.bold())

                Text("Who are you today?")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                ForEach(Role.allCases) { role in
                    NavigationLink(value: role) {
                        RoleCard(role: role)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding()
            .navigationDestination(for: Role.self) { role in
                switch role {
                case .buyer:  BuyerHomeView()
                case .seller: SellerHomeView()
                }
            }
            .alert("Connection problem", isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }
}

private struct RoleCard: View {
    let role: RootView.Role

    private var symbol: String {
        role == .buyer ? "bag.fill" : "tag.fill"
    }

    private var subtitle: String {
        role == .buyer ? "Browse and shop listings" : "Post and manage products"
    }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: symbol)
                .font(.title)
                .frame(width: 56, height: 56)
                .background(.blue.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(role.rawValue)
                    .font(.title3.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
}

#Preview {
    RootView()
        .environmentObject(ProductStore())
}

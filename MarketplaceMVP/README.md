# Marketplace MVP (SwiftUI)

A minimal marketplace app: sellers post products, buyers browse and view
listings. Two displays — one for buyers, one for sellers — chosen at launch.

## Features

**Buyer display**
- Search products by name/description
- Filter by category chips
- Grid of product cards, tap for a detail page
- "Message Seller" button (mock alert in MVP)

**Seller display**
- Post a product (name, description, price, category, placeholder icon)
- Your listings list with delete (swipe or List edit)
- Eye toggle to mark a listing available/unavailable

**Data layer**
- `ProductStore` (ObservableObject) is server-backed: it calls the
  Node.js + PostgreSQL REST API in the `backend` folder (see
  `backend/README.md` for the demo-day runbook).
- Views never touch networking directly — they call the store, so the data
  source can be swapped without touching them.

## How to build in Xcode (on a Mac)

These files were written on Windows, so you need to create the Xcode project
on a Mac and drop them in:

1. Open **Xcode → File → New → Project → iOS → App**.
2. Product Name: `MarketplaceMVP`, Interface: **SwiftUI**, Language: **Swift**.
3. Xcode generates two template files: `<YourName>App.swift` and
   `ContentView.swift`. **Delete both.**
4. Drag this whole `MarketplaceMVP` folder into the Xcode project navigator
   (check "Copy items if needed" and your app target).
5. Requires **iOS 16+** (uses `NavigationStack`, `ContentUnavailableView`
   needs iOS 17 — if targeting iOS 16, replace the
   `ContentUnavailableView.search(...)` call in `BuyerViews.swift` with a
   simple `Text("No products found")`).
6. Run on the iPhone simulator (▶ button).

## Trying it out

1. Launch → tap **Seller** → tap **+** → fill in the form → **Post**.
2. Go back → tap **Buyer** → pull to refresh → your product appears.
3. The listing is now in PostgreSQL — see the demo script in
   `../backend/README.md`.

## Files

```
MarketplaceMVP/
├── MarketplaceApp.swift        # App entry point
├── Models/Product.swift        # Product model + categories
├── Store/ProductStore.swift    # Server-backed store (URLSession -> REST API)
└── Views/
    ├── RootView.swift          # Role picker (Buyer / Seller) + error alert
    ├── BuyerViews.swift        # Buyer home, category chips, product detail
    └── SellerViews.swift       # Seller home, listing rows, add-product form
```

Before building, make sure the backend is running and `baseURL` at the top
of `ProductStore.swift` points at it — see `../backend/README.md`.

## Next steps (beyond MVP)

- Real photos via `PhotosPicker` (iOS 16+) instead of emoji placeholders
- Firebase Auth + Firestore for real multi-user sync
- Chat between buyer and seller
- Push notifications for new listings

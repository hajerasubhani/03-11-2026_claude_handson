# Marketplace Backend (Node.js + Express + PostgreSQL)

REST API backing the SwiftUI marketplace app. Built for a live MVP demo.
Runs with plain Node.js — no Docker.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | quick "is it up?" check |
| GET | `/api/products` | list all products (`?available=true` to filter) |
| POST | `/api/products` | create a product (seller posts) |
| PATCH | `/api/products/:id/availability` | toggle available/unavailable |
| DELETE | `/api/products/:id` | delete a product |

## One-time setup

**1. Install Node.js** (18 or newer, LTS is fine):

```powershell
winget install OpenJS.NodeJS.LTS
```

or download from https://nodejs.org. Verify: `node --version`.

**2. Install PostgreSQL** (16 or newer):

```powershell
winget install PostgreSQL.PostgreSQL.16
```

or download the installer from https://www.postgresql.org/download/windows/.
Remember the `postgres` password you set during installation.

**3. Create the database and user** — open a terminal and run:

```powershell
psql -U postgres
```

then inside psql:

```sql
CREATE USER marketplace WITH PASSWORD 'marketplace';
CREATE DATABASE marketplace OWNER marketplace;
\q
```

(If you prefer different credentials, put them in `.env` instead — copy
`.env.example` to `.env` and edit.)

## Run it

```bash
npm install
npm start
```

The server creates the `products` table automatically and seeds 5 sample
products on first run. Verify with:

```bash
curl http://localhost:3000/health
curl http://localhost:3000/api/products
```

or just open http://localhost:3000/api/products in a browser.

## Demo-day setup (SwiftUI app + backend)

The app's server address is at the top of
`MarketplaceMVP/Store/ProductStore.swift` (`baseURL`). Two options:

**Option A — backend on the Mac, simulator on the same Mac (simplest):**

1. Copy the `backend` folder onto the Mac (Node.js + PostgreSQL installed there), run `npm install && npm start` there.
2. Keep `baseURL = URL(string: "http://127.0.0.1:3000/api")` (the default). Done.

**Option B — backend on this Windows PC, Mac simulator hits it over Wi-Fi:**

1. Start the server here (`npm start`).
2. Find this PC's LAN IP: `ipconfig` → IPv4 Address (e.g. `192.168.1.42`).
3. On the Mac, set `baseURL = URL(string: "http://192.168.1.42:3000/api")`.
4. Allow port 3000 through Windows Defender Firewall (or temporarily disable
   it for the demo) — the Node window will trigger a firewall prompt the
   first time; click **Allow**.

### Required iOS setting for Option B

The simulator blocks plain-HTTP (non-HTTPS) requests by default. In Xcode:

1. Select the app target → **Info** tab.
2. Add `App Transport Security Settings` (dictionary).
3. Inside it add `Allows Local Networking` = `YES`.

(Only needed when the app talks to a LAN IP — `127.0.0.1` works without it.)

## Demo script suggestion

1. Show the **Buyer** screen — the 5 seeded products load from PostgreSQL.
2. Switch to the **Seller** screen — post a new product (fill the form, Post).
3. Back to **Buyer** — pull to refresh, the new product appears from the database.
4. Point out the data is in Postgres: `psql -U marketplace -d marketplace -c "SELECT name, price FROM products;"`
5. Toggle availability with the eye button → it disappears from the buyer grid.

## Reset the demo data

```bash
psql -U marketplace -d marketplace -c "DELETE FROM products;"
npm start   # restart reseeds the 5 sample products
```

## Troubleshooting

- **`Could not start — is PostgreSQL running?`** → the PostgreSQL service isn't running. Check Services (`services.msc` → `postgresql-x64-16`) or reinstall.
- **`password authentication failed`** → credentials in `.env` don't match what you created in psql.
- **`ECONNREFUSED 127.0.0.1:5432`** → Postgres isn't listening on 5432; check the service is started.
- **App shows "Could not load products"** → check `/health` in a browser; check `baseURL` matches; Option B needs the ATS setting above.
- **`node` is not recognized** → Node.js not installed or PATH not refreshed — reopen the terminal after installing.

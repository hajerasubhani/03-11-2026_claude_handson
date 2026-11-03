// Marketplace MVP backend — Express + PostgreSQL.
// Endpoints used by the SwiftUI app:
//   GET    /api/products                     list all products
//   POST   /api/products                     create a product (seller posts)
//   PATCH  /api/products/:id/availability    toggle available/unavailable
//   DELETE /api/products/:id                 delete a product
//   GET    /health                           quick "is it up?" check
require("dotenv").config();

const express = require("express");
const cors = require("cors");
const { pool, init, toProduct } = require("./db");

const app = express();
app.use(cors());
app.use(express.json());

// Express 4 does not catch errors thrown inside async handlers — wrap them.
const wrap = (handler) => (req, res, next) =>
  handler(req, res, next).catch(next);

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.get("/api/products", wrap(async (req, res) => {
  const query =
    req.query.available === "true"
      ? "SELECT * FROM products WHERE is_available = TRUE ORDER BY created_at DESC"
      : "SELECT * FROM products ORDER BY created_at DESC";
  const result = await pool.query(query);
  res.json(result.rows.map(toProduct));
}));

app.post("/api/products", wrap(async (req, res) => {
  const { name, description = "", price, category = "Other", emoji = "📦", sellerName = "Me" } = req.body;

  if (!name || !String(name).trim()) {
    return res.status(400).json({ error: "name is required" });
  }
  if (typeof price !== "number" || !Number.isFinite(price) || price <= 0) {
    return res.status(400).json({ error: "price must be a positive number" });
  }

  const result = await pool.query(
    `INSERT INTO products (name, description, price, category, emoji, seller_name)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [String(name).trim(), description, price, category, emoji, sellerName]
  );
  res.status(201).json(toProduct(result.rows[0]));
}));

app.patch("/api/products/:id/availability", wrap(async (req, res) => {
  const { isAvailable } = req.body;
  if (typeof isAvailable !== "boolean") {
    return res.status(400).json({ error: "isAvailable (boolean) is required" });
  }

  const result = await pool.query(
    "UPDATE products SET is_available = $1 WHERE id = $2 RETURNING *",
    [isAvailable, req.params.id]
  );
  if (result.rows.length === 0) {
    return res.status(404).json({ error: "Product not found" });
  }
  res.json(toProduct(result.rows[0]));
}));

app.delete("/api/products/:id", wrap(async (req, res) => {
  const result = await pool.query(
    "DELETE FROM products WHERE id = $1 RETURNING id",
    [req.params.id]
  );
  if (result.rows.length === 0) {
    return res.status(404).json({ error: "Product not found" });
  }
  res.status(204).end();
}));

app.use((req, res) => {
  res.status(404).json({ error: "Not found" });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "Internal server error" });
});

// Init schema/seed, then listen on all interfaces so other devices
// on the network (e.g. the Mac running the simulator) can reach it.
const port = Number(process.env.PORT) || 3000;
init()
  .then(() => {
    app.listen(port, "0.0.0.0", () => {
      console.log(`Marketplace backend listening on http://0.0.0.0:${port}`);
      console.log(`Health check: http://localhost:${port}/health`);
    });
  })
  .catch((err) => {
    console.error("Could not start — is PostgreSQL running?", err.message);
    process.exit(1);
  });

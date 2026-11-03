// PostgreSQL connection, schema setup and seed data.
// Credentials come from .env (see .env.example); defaults match
// the docker-compose.yml in this folder.
const { Pool } = require("pg");

const pool = new Pool({
  user: process.env.PGUSER || "marketplace",
  host: process.env.PGHOST || "localhost",
  database: process.env.PGDATABASE || "marketplace",
  password: process.env.PGPASSWORD || "marketplace",
  port: Number(process.env.PGPORT) || 5432,
});

// Convert a DB row (snake_case) to the JSON shape the SwiftUI app expects (camelCase).
function toProduct(row) {
  return {
    id: row.id,
    name: row.name,
    description: row.description,
    price: Number(row.price), // NUMERIC comes back as a string from pg
    category: row.category,
    emoji: row.emoji,
    sellerName: row.seller_name,
    isAvailable: row.is_available,
    createdAt: row.created_at,
  };
}

// Create the table if missing and seed sample data on first run.
async function init() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS products (
      id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
      name         TEXT NOT NULL,
      description  TEXT NOT NULL DEFAULT '',
      price        NUMERIC(10,2) NOT NULL CHECK (price > 0),
      category     TEXT NOT NULL DEFAULT 'Other',
      emoji        TEXT NOT NULL DEFAULT '📱',
      seller_name  TEXT NOT NULL DEFAULT 'Me',
      is_available BOOLEAN NOT NULL DEFAULT TRUE,
      created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
    )
  `);

  const { rows } = await pool.query("SELECT COUNT(*)::int AS count FROM products");
  if (rows[0].count === 0) {
    const seed = [
      ["FitTrack Pro", "iOS fitness tracking app with workout plans, step tracking and health sync.", 4.99, "iOS Apps", "📱", "Alex"],
      ["TaskFlow", "Web-based task management tool for teams with kanban boards and reports.", 9.99, "Web Apps", "💻", "Maria"],
      ["Puzzle Quest HD", "Addictive puzzle game for mobile with 200 levels and daily challenges.", 2.99, "Games", "🎮", "Sam"],
      ["PaletteKit", "Design tool with 500+ icon pack and color palette generator for developers.", 14.99, "Design", "🎨", "Alex"],
      ["NoteMaster", "Cross-platform notes app with cloud sync, tags and markdown support.", 6.99, "Productivity", "📝", "Maria"],
    ];
    for (const [name, description, price, category, emoji, sellerName] of seed) {
      await pool.query(
        `INSERT INTO products (name, description, price, category, emoji, seller_name)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [name, description, price, category, emoji, sellerName]
      );
    }
    console.log(`Seeded ${seed.length} sample products.`);
  }
}

module.exports = { pool, init, toProduct };

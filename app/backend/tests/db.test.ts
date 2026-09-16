import "dotenv/config";
import pool from "../src/db";

try {
  const result = await pool.query("SELECT NOW()");
  console.log("PostgreSQL connected successfully!");
  console.log("Database time:", result.rows[0].now);
} catch (error) {
  console.error("PostgreSQL connection failed:", error);
} finally {
  await pool.end();
}

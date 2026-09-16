import express from "express";
import "dotenv/config";
import pool from "./db.js";

const app = express();
app.use(express.json());

const PORT = 3000;

app.get("/", (_req, res) => {
  res.json({
    message: "Task Management API is running",
  });
});

app.get("/health", (_req, res) => {
  res.json({
    status: "healthy",
  });
});

app.get("/tasks", async (_req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM tasks ORDER BY created_at DESC",
    );

    res.json(result.rows);
  } catch (error) {
    console.error("Failed to fetch tasks:", error);
    res.status(500).json({
      error: "Failed to fetch tasks",
    });
  }
});

app.post("/tasks", async (req, res) => {
  try {
    const { title } = req.body;

    if (!title || typeof title !== "string") {
      return res.status(400).json({
        error: "Title is required",
      });
    }

    const result = await pool.query(
      "INSERT INTO tasks (title) VALUES ($1) RETURNING *",
      [title],
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error("Failed to create task:", error);
    res.status(500).json({
      error: "Failed to create task",
    });
  }
});

app.patch("/tasks/:id", async (req, res) => {
  try {
    const id = Number(req.params.id);
    const { title, completed } = req.body;

    if (!Number.isInteger(id)) {
      return res.status(400).json({
        error: "Invalid task ID",
      });
    }

    if (
      title !== undefined &&
      (typeof title !== "string" || title.trim() === "")
    ) {
      return res.status(400).json({
        error: "Title must be a non-empty string",
      });
    }

    if (completed !== undefined && typeof completed !== "boolean") {
      return res.status(400).json({
        error: "Completed must be a boolean",
      });
    }

    const result = await pool.query(
      `UPDATE tasks
       SET
         title = COALESCE($1, title),
         completed = COALESCE($2, completed)
       WHERE id = $3
       RETURNING *`,
      [title, completed, id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: "Task not found",
      });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error("Failed to update task:", error);
    res.status(500).json({
      error: "Failed to update task",
    });
  }
});

app.delete("/tasks/:id", async (req, res) => {
  try {
    const id = Number(req.params.id);

    if (!Number.isInteger(id)) {
      return res.status(400).json({
        error: "Invalid task ID",
      });
    }

    const result = await pool.query(
      "DELETE FROM tasks WHERE id = $1 RETURNING *",
      [id],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: "Task not found",
      });
    }

    res.json({
      message: "Task deleted successfully",
      task: result.rows[0],
    });
  } catch (error) {
    console.error("Failed to delete task:", error);
    res.status(500).json({
      error: "Failed to delete task",
    });
  }
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

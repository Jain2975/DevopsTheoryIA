CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO tasks (title, completed)
SELECT 'Learn Terraform', FALSE
WHERE NOT EXISTS (
    SELECT 1
    FROM tasks
    WHERE title = 'Learn Terraform'
);

INSERT INTO tasks (title, completed)
SELECT 'Test Infrastructure', FALSE
WHERE NOT EXISTS (
    SELECT 1
    FROM tasks
    WHERE title = 'Test Infrastructure'
);
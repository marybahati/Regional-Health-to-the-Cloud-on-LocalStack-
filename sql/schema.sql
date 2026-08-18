# Placeholder — replace with the course schema (patients table, etc.).
# Load onto Aiven before `make up`:
#   mysql -h "$AIVEN_MYSQL_HOST" -P "$AIVEN_MYSQL_PORT" -u avnadmin -p \
#     --ssl-mode=REQUIRED < sql/schema.sql

CREATE DATABASE IF NOT EXISTS capacity_lab;
USE capacity_lab;

CREATE TABLE IF NOT EXISTS patients (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

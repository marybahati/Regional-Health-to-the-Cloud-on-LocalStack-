-- strict-mode: InnoDB + utf8mb4 for Aiven MySQL 8.
CREATE TABLE IF NOT EXISTS patients (
  id INT NOT NULL AUTO_INCREMENT,
  national_id VARCHAR(32) NOT NULL,
  full_name VARCHAR(255) NOT NULL,
  date_of_birth DATE NOT NULL,
  district VARCHAR(64) NOT NULL,
  notes TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_national_id (national_id),
  KEY idx_district (district)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

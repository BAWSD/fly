CREATE DATABASE IF NOT EXISTS flight_info CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS flight_status CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS airport_map CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS flight_data CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'flight_user'@'%' IDENTIFIED BY 'Flight@123456';
GRANT ALL PRIVILEGES ON flight_info.* TO 'flight_user'@'%';
GRANT ALL PRIVILEGES ON flight_status.* TO 'flight_user'@'%';
GRANT ALL PRIVILEGES ON airport_map.* TO 'flight_user'@'%';
GRANT ALL PRIVILEGES ON flight_data.* TO 'flight_user'@'%';
FLUSH PRIVILEGES;
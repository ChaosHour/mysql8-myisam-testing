# Include environment variables from .env file
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.PHONY: build-primary1 build-primary2 create-database copy-sdi-files copy-files-2-datadir start-primary1 start-primary2 stop create-myisam-table create-symlink import-sdi validate-myisam-table restart-mysql-primary2

# Build the primary1 and primary2 images
build-primary1:
	docker build -t mysql-primary1 .

build-primary2:
	docker build --build-arg build_type=primary2 -t mysql-primary2 .

# Start only the primary1
start-primary1: build-primary1
	@mkdir -p shared_data 
	docker-compose up -d mysql-primary1

# Start only the primary2
start-primary2: build-primary2
	@mkdir -p shared_data2
	docker-compose up -d mysql-primary2

# Stop the primary1 and primary2
stop:
	docker-compose down -v --remove-orphans
	if [ -d "shared_data" ]; then find shared_data -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -rf; fi
	if [ -d "shared_data2" ]; then find shared_data2 -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -rf; fi

# Create a MyISAM table and populate it in primary1
create-myisam-table:
	@echo "Creating MyISAM table in primary1..."
	@docker-compose exec mysql-primary1 mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS testdb; USE testdb; CREATE TABLE myisam_table (id INT PRIMARY KEY) ENGINE=MyISAM; INSERT INTO myisam_table VALUES (1)" 2>/dev/null
	@echo "MyISAM table created and populated."

# Create symlink in primary2
create-symlink:
	@echo "Creating symlink in primary2..."
	@docker-compose exec mysql-primary2 sh -c "chown -R mysql: /rl/data/mysql/data02/data"
	@docker-compose exec mysql-primary2 sh -c "ln -s /rl/data/mysql/data01/data/testdb /rl/data/mysql/data02/data/testdb"
	@docker-compose exec mysql-primary2 sh -c "chown -R mysql: /rl/data/mysql/data02/data/testdb"
	@docker-compose exec mysql-primary2 sh -c "chown -R mysql: /var/lib/mysql-files"
	@echo "Symlink created."

# Restart MySQL in primary2
restart-mysql-primary2:
	@echo "Restarting MySQL in primary2..."
	@docker-compose exec -T mysql-primary2 sh -c "mysqladmin -u root -p'${MYSQL_ROOT_PASSWORD}' shutdown" || true
	@sleep 5
	@docker-compose exec -d mysql-primary2 mysqld
	@echo "MySQL restarted in primary2."

# Validate that the MyISAM table exists and is accessible in primary2
validate-myisam-table:
	@echo "Validating MyISAM table in primary2..."
	@docker-compose exec mysql-primary2 mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "\u testdb; SELECT * FROM myisam_table" -P3307 2>/dev/null
	@echo "MyISAM table validated."

copy-sdi-files:
	@echo "Copying files to primary2..."
	@docker-compose exec mysql-primary2 sh -c "cp -v /rl/data/mysql/data01/data/testdb/*.sdi /var/lib/mysql-files/"
	@echo "Files copied."

copy-files-2-datadir:
	@echo "Copying files to primary2..."
	@docker-compose exec mysql-primary2 sh -c "cp -v /rl/data/mysql/data01/data/testdb/{*.MYD,*.MYI} /rl/data/mysql/data02/data/testdb"
	@echo "Files copied."

create-database:
	@echo "Creating testdb on primary2..."
	@docker-compose exec -T mysql-primary2 sh -c "mysqladmin -u root -p'${MYSQL_ROOT_PASSWORD}' create testdb" 
	@echo "Database Created..."

import-sdi:
	@echo "Importing sdi files into primary2..."
	@docker-compose exec mysql-primary2 sh -c "chown -R mysql: /var/lib/mysql-files"
	@docker-compose exec mysql-primary2 mysql -u root -p"${MYSQL_ROOT_PASSWORD}" -e "IMPORT TABLE FROM '/var/lib/mysql-files/employees_371.sdi','/var/lib/mysql-files/myisam_table_373.sdi'" testdb -vvv -P3307 2>/dev/null
	@echo "SDI files have been imported."
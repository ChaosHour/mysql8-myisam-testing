## Ran the following tests: 

What is needed to run this test:
- MySQL Client
- Create two folders in the root of this project called shared_data and shared_data2
- Docker

```bash
Did not work:
MySQL 8:
Test 1:
make start-primary1 && make start-primary2
make create-myisam-table
make create-symlink
make restart-mysql-primary2


Worked:
MySQL 8
Test 2:
make start-primary1 && make start-primary2
make create-myisam-table
make create-database
make copy-sdi-files
make copy-files-2-datadir
make import-sdi
```

# Clean up
```bash
make stop
```


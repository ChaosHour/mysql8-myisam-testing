# Use the official MySQL 8.0 image as the base image
FROM mysql:8.0

# Set the default build argument to "primary1"
ARG build_type=primary1

## Set stanza for mysqld
RUN echo "[mysqld]" >> /etc/mysql/conf.d/docker.cnf

# Set up the primary1 database
COPY primary1/primary1.sql /docker-entrypoint-initdb.d/
RUN echo "server-id=1" >> /etc/mysql/conf.d/docker.cnf

# Enable GTID replication
RUN echo "gtid_mode=ON" >> /etc/mysql/conf.d/docker.cnf
RUN echo "enforce_gtid_consistency=true" >> /etc/mysql/conf.d/docker.cnf

# Add InnoDB configuration
RUN echo "innodb_file_per_table=ON" >> /etc/mysql/conf.d/docker.cnf

# Set datadir based on build_type
RUN if [ "$build_type" = "primary1" ]; then \
    echo "datadir=/rl/data/mysql/data01/data" >> /etc/mysql/conf.d/docker.cnf; \
elif [ "$build_type" = "primary2" ]; then \
    echo "datadir=/rl/data/mysql/data02/data" >> /etc/mysql/conf.d/docker.cnf; \
    echo "symbolic-links=1" >> /etc/mysql/conf.d/docker.cnf; \
fi

# Expose the MySQL port
EXPOSE 3306

# Copy and set up custom entrypoint script
COPY custom-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/custom-entrypoint.sh

# Set as entrypoint
ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]

# Remove default CMD
CMD []
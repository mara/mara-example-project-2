FROM postgres:11

# Build dependencies
ARG buildDeps='git libpq-dev libprotobuf-c0-dev make postgresql-server-dev-11 protobuf-c-compiler gcc g++'

# Install extensions' dependencies
RUN apt-get update \
    && apt-get install -y ${buildDeps}

# Install cstore-fdw extension
RUN cd /tmp && git clone -b v1.6.2 https://github.com/citusdata/cstore_fdw.git
RUN cd /tmp/cstore_fdw && PATH=/usr/local/pgsql/bin/:$PATH make && PATH=/usr/local/pgsql/bin/:$PATH make install

# Remove un-needed build dependencies
RUN apt-get purge -y --auto-remove ${buildDeps} \
    && rm -rf /var/lib/apt/lists/*

# Copy custom configuration
COPY mara-postgres.conf /etc/postgresql/postgresql.conf

# this adds the initdb.sql file to the postgres server folder /docker-entrypoint-initdb.d
# to run on initial database server start up. on start up, all .sql, .sh files in this folder
# are run, which makes it the best place to create a database we shall be using.
ADD initdb.sql /docker-entrypoint-initdb.d

CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf"]

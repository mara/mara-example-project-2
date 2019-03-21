# This tells the docker daemon to build an image on top of a postgres 11 version image.
FROM postgres:11

# Install extensions' dependencies
RUN apt-get update && apt-get install -y \
    git \
    libpq-dev \
    libprotobuf-c0-dev \
    make \
    postgresql-server-dev-11 \
    protobuf-c-compiler \
    gcc \
    g++

# Install cstore-fdw extension
RUN cd /tmp && git clone -b v1.6.2 https://github.com/citusdata/cstore_fdw.git
RUN cd /tmp/cstore_fdw && PATH=/usr/local/pgsql/bin/:$PATH make && PATH=/usr/local/pgsql/bin/:$PATH make install

# Install hll extension
RUN cd /tmp && git clone https://github.com/citusdata/postgresql-hll.git
RUN cd /tmp/postgresql-hll && PG_CONFIG=/usr/lib/postgresql/11/bin/pg_config make CC=gcc CXX=gcc && make CC=gcc CXX=gcc install

# Copy custom configuration
COPY mara-postgres.conf /etc/postgresql/postgresql.conf

# this adds the initdb.sql file to the postgres server folder /docker-entrypoint-initdb.d
# to run on initial database server start up. on start up, all .sql, .sh files in this folder
# are run, which makes it the best place to create a database we shall be using.
ADD initdb.sql /docker-entrypoint-initdb.d

# declare the default postgres server port
EXPOSE 5432

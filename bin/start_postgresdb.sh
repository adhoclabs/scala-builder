#!/usr/bin/env bash

sudo -u postgres PGDATA=/var/lib/postgresql/data /usr/lib/postgresql/"${POSTGRES_VERSION}"/bin/pg_ctl start

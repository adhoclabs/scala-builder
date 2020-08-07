#!/usr/bin/env bash

sudo -u postgres PGDATA=/var/lib/postgresql/data /usr/lib/postgresql/11/bin/pg_ctl start

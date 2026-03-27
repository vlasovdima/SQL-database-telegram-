#!/bin/bash
mkdir -p exports
docker exec tg_postgres pg_dump -U telegram_user -d telegram_demo -s > exports/postgres_schema_dump.sql
docker exec tg_postgres pg_dump -U telegram_user -d telegram_demo > exports/postgres_full_dump.sql

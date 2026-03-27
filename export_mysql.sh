#!/bin/bash
mkdir -p exports
docker exec tg_mysql mysqldump -u telegram_user -ptelegram_pass --no-data telegram_demo > exports/mysql_schema_dump.sql
docker exec tg_mysql mysqldump -u telegram_user -ptelegram_pass telegram_demo > exports/mysql_full_dump.sql

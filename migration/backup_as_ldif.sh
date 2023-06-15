#!/usr/bin/env bash

slapcat -n 2 > migration_backup.ldif

echo "Generating LDIF"

bucket = ""

ionice -c 3 nice gzip -cv migration_backup.ldif.gz | aws s3 cp  s3://${bucket}/migration_backup.ldif.gz

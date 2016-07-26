#!/bin/bash

# Base Config
cat << EOF > /tmp/s3cfg
[default]
bucket_location = Ireland
cloudfront_host = cloudfront.amazonaws.com
default_mime_type = binary/octet-stream
delete_removed = False
dry_run = False
enable_multipart = True
encoding = ANSI_X3.4-1968
encrypt = False
follow_symlinks = False
force = False
get_continue = False
gpg_command = /usr/bin/gpg
gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
gpg_passphrase =
guess_mime_type = True
host_base = s3.amazonaws.com
host_bucket = %(bucket)s.s3.amazonaws.com
human_readable_sizes = False
invalidate_on_cf = False
list_md5 = False
log_target_prefix =
mime_type =
multipart_chunk_size_mb = 15
preserve_attrs = True
progress_meter = True
proxy_host =
proxy_port = 0
recursive = False
recv_chunk = 4096
reduced_redundancy = False
send_chunk = 4096
simpledb_host = sdb.amazonaws.com
skip_existing = False
socket_timeout = 300
urlencoding_mode = normal
use_https = True
verbosity = WARNING
website_endpoint = http://%(bucket)s.s3-website-%(location)s.amazonaws.com/
website_error =
website_index = index.html
EOF

# Check env vars
set -e
: ${ACCESS_KEY:?"ACCESS_KEY env variable is required"}
: ${SECRET_KEY:?"SECRET_KEY env variable is required"}
: ${S3_PATH:?"S3_PATH env variable is required (s3://blabla/)"}
: ${DATA_PATH:?"DATA_PATH env variable is required (/app)"}
: ${BACKUP_TYPE:?"BACKUP_TYPE env variable is required (sync - backup)"}
: ${SLEEP:?"SLEEP env variable is required (1h 1d 7d 30d ...)"}
: ${EXPIRE:?"EXPIRE env variable is required (7 14 30 60 90 ...) days"}

echo "access_key=${ACCESS_KEY}" >> /tmp/s3cfg
echo "secret_key=${SECRET_KEY}" >> /tmp/s3cfg

# Backup
if [ ${BACKUP_TYPE} == "backup" ]
then
STAMP=$(date)
echo "[${STAMP}] Starting backup to [${S3_PATH}/backup/${STAMP}/] ..."
/usr/bin/s3cmd --no-preserve --no-progress --config=/tmp/s3cfg sync "${DATA_PATH}" "${S3_PATH}/backup/${STAMP}/"
STAMP=$(date)
echo "[${STAMP}] Done making a backup to [${S3_PATH}/backup/${STAMP}/] ..."

echo "[${STAMP}] Setting expiry on [${S3_PATH}/backup/${STAMP}/] ..."
/usr/bin/s3cmd --no-preserve --no-progress --config=/tmp/s3cfg expire --expiry-days="${EXPIRE}" --expiry-prefix="${S3_PATH}/backup/${STAMP}/" "${S3_PATH}"
STAMP=$(date)
echo "[${STAMP}] Done setting expiry on [${S3_PATH}/backup/${STAMP}/] ..."
fi

# Backup
if [ ${BACKUP_TYPE} == "sync" ]
then
# Sync
STAMP=$(date)
echo "[${STAMP}] Starting sync to [$S3_PATH/sync/] ..."
/usr/bin/s3cmd --no-preserve --no-progress --config=/tmp/s3cfg sync ${PARAMS} "${DATA_PATH}" "${S3_PATH}/sync/"
STAMP=$(date)
echo "[${STAMP}] Done syncing to [$S3_PATH/sync/] ..."
fi

# Sleep
STAMP=$(date)
echo "[${STAMP}] Sleeping for [${SLEEP}] ..."

sleep ${SLEEP}

# Bye Bye
STAMP=$(date)
echo "[${STAMP}] Bye Bye..."

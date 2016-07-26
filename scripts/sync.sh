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
: ${AWS_ACCESS_KEY:?"ACCESS_KEY env variable is required"}
: ${AWS_SECRET_KEY:?"SECRET_KEY env variable is required"}
: ${S3_BUCKET:?"S3_BUCKET env variable is required (s3://bucketname)"}
: ${BACKUP_NAME:?"BACKUP_NAME env variable is required (yourbackupname)"}
: ${BACKUP_DATA_PATH:?"BACKUP_DATA_PATH env variable is required (/app)"}
: ${BACKUP_TYPE:?"BACKUP_TYPE env variable is required (backup - upload)"}
: ${BACKUP_SLEEP:?"BACKUP_SLEEP env variable is required (1h 1d 7d 30d ...)"}
: ${BACKUP_EXPIRE:?"BACKUP_EXPIRE env variable is required (7d 14d 30d 60d 90d ...) days"}
: ${OPENSHIFT_WEEPEE_ID:?"OPENSHIFT_WEEPEE_ID env variable is required"}

# Add credentials to config
echo "access_key=${AWS_ACCESS_KEY}" >> /tmp/s3cfg
echo "secret_key=${AWS_SECRET_KEY}" >> /tmp/s3cfg

# Create S3 Path
S3_PATH="${S3_BUCKET}/${OPENSHIFT_WEEPEE_ID}/${BACKUP_NAME}"

# Remove alpha chars from BACKUP_EXPIRE
BACKUP_EXPIRE=$(printf '%s\n' "${BACKUP_EXPIRE//[[:alpha:]]/}")

# Backup
if [ ${BACKUP_TYPE} == "backup" ]
then
STAMP=$(date)
echo "[${STAMP}] Starting backup to [${S3_PATH}/backup/${STAMP}/] ..."
/usr/bin/s3cmd --no-mime-magic --no-preserve --no-progress --config=/tmp/s3cfg put -r "${BACKUP_DATA_PATH}" "${S3_PATH}/backup/${STAMP}/"
STAMP=$(date)
echo "[${STAMP}] Done making a backup to [${S3_PATH}/backup/${STAMP}/] ..."

echo "[${STAMP}] Setting expiry ${BACKUP_EXPIRE} days on [${S3_PATH}/backup/${STAMP}/] ..."
/usr/bin/s3cmd --no-preserve --no-progress --config=/tmp/s3cfg expire --expiry-days="${BACKUP_EXPIRE}" --expiry-prefix="/backup/${STAMP}/" "${S3_BUCKET}"
STAMP=$(date)
echo "[${STAMP}] Done setting ${BACKUP_EXPIRE} days expiry on [${S3_PATH}/backup/${STAMP}/] ..."
fi

# Backup
if [ ${BACKUP_TYPE} == "upload" ]
then
# Sync
STAMP=$(date)
echo "[${STAMP}] Starting upload to [$S3_PATH/upload/] ..."
/usr/bin/s3cmd --no-mime-magic --no-preserve --no-progress --config=/tmp/s3cfg put -r "${BACKUP_DATA_PATH}" "${S3_PATH}/upload/"
STAMP=$(date)
echo "[${STAMP}] Done upload to [$S3_PATH/upload/] ..."
fi

# Sleep
STAMP=$(date)
echo "[${STAMP}] Sleeping for [${BACKUP_SLEEP}] ..."

sleep ${BACKUP_SLEEP}

# Bye Bye
STAMP=$(date)
echo "[${STAMP}] Bye Bye..."

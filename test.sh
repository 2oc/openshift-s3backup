#!/bin/bash


docker run  -e ACCESS_KEY=###YOURKEY### -e SECRET_KEY="###YOURSECRET###" -e S3_PATH=s3://wp-s3backup/test/ -e DATA_PATH=/scripts -e SLEEP=5m -i -t weepee/s3backup:latest

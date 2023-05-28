#!/bin/bash

#usage: sh /root/mysql-backup.sh /backup root@server:/backup/ rootpassword

TODAY=$(date +"%Y-%m-%d")
NOW=$(date +"%Y-%m-%d-%Hh")
HOURAGO=$(date -d '1 hour ago' +"%Y-%m-%d-%Hh")
TWOHOURAGO=$(date -d '2 hour ago' +"%Y-%m-%d-%Hh")
HOUR=$(date +"%H")
DAY=$(date +"%d")


echo "$NOW"
echo "$HOURAGO"
echo "$HOUR"
echo "$DAY"

# was until 2023-01-14
#if [ "$HOUR" = "08" ]
#then
#   MYSQLDUMP_IGNORETABLES=""
#   PREFIX="keep"
#   EXCLUSION_LIST="'information_schema','mysql'"
#   INCLUSION_LIST="'coinvertit_coinvertit','cointessa_cointessa','coinvertit_coinvertit_archive'"
#else
#   MYSQLDUMP_IGNORETABLES="--ignore-table=coinvertit_coinvertit.Locations --ignore-table=coinvertit_coinvertit.ExchangeTable --ignore-table=coinvertit_coinvertit.ExchangeTableHistory --ignore-table=coinvertit_coinvertit.IP2location_db5"
#   PREFIX="backup"
#   EXCLUSION_LIST="'information_schema','mysql','cointessa_cointessa','coinvertit_coinvertit_archive'"
#   INCLUSION_LIST="'coinvertit_coinvertit'"
#fi

MYSQLDUMP_IGNORETABLES=""
PREFIX="mysqldb"
EXCLUSION_LIST="'information_schema','mysql'"
INCLUSION_LIST="''"

MYSQLUSERNAME="root"
MYSQLPASSWORD=$3

if [ -n "$MYSQLPASSWORD" ]
then
    MYSQLCONNECT='-u'$MYSQLUSERNAME' -p'$MYSQLPASSWORD
else
    MYSQLCONNECT='-u'$MYSQLUSERNAME
fi

DATABASES_TO_EXCLUDE="performance_schema"
for DB in `echo "${DATABASES_TO_EXCLUDE}"`
do
    EXCLUSION_LIST="${EXCLUSION_LIST},'${DB}'"
done
SQLSTMT="SELECT schema_name FROM information_schema.schemata"

## if you use the EXCLUSION_LIST uncomment below (use only one)
SQLSTMT="${SQLSTMT} WHERE schema_name NOT IN (${EXCLUSION_LIST})"
## if you use the INCLUSION_LIST uncomment below (use only one)
#SQLSTMT="${SQLSTMT} WHERE schema_name IN (${INCLUSION_LIST})"

MYSQLDUMP_DATABASES="--databases"
for DB in `mysql $MYSQLCONNECT -ANe"${SQLSTMT}"`
do
    MYSQLDUMP_DATABASES="${MYSQLDUMP_DATABASES} ${DB}"
done

#MYSQLDUMP_OPTIONS="--routines --triggers"

mysqldump $MYSQLCONNECT ${MYSQLDUMP_OPTIONS} --single-transaction --quick --skip-add-locks ${MYSQLDUMP_DATABASES} ${MYSQLDUMP_IGNORETABLES} > /$1/$PREFIX$NOW.sql

cpulimit -l 75 gzip -9 /$1/$PREFIX$NOW.sql

## Uncomment if you want to encrypt the files.
#split -b 200M -d -a 4 /$1/$PREFIX$NOW.sql.gz /$1/mysqlbackup/$PREFIX$NOW.sql.gz.part
#rm /$1/$PREFIX$NOW.sql.gz
#cd /$1/mysqlbackup/
#for f in $PREFIX$NOW*; do openssl smime -encrypt -binary -text -aes256 -in "$f" -out "$f.enc" -outform DER /root/mysqldump.pub.pem; rm -Rf "$f"; done

rm -Rf /$1/mysqlbackup/keep$HOURAGO.sql.*
rm -Rf /$1/mysqlbackup/backup$HOURAGO.sql.*
rm -Rf /$1/mysqlbackup/keep$TWOHOURAGO.sql.*
rm -Rf /$1/mysqlbackup/backup$TWOHOURAGO.sql.*

## Uncomment if you want to transfer the backup to a backup server.
#rsync -av -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -T -c arcfour -o Compression=no -x" --safe-links --delete-after --progress /$1/mysqlbackup/$PREFIX$NOW.sql.* $2

#! /bin/sh

[[ -f /tmp/daily_urls.lock ]] && exit 1

touch /tmp/daily_urls.lock

. /etc/socorro/socorrorc

REPORT_DATE="1 days ago"

if [ -n "$1" ]
then
  REPORT_DATE=$1
fi

SCRIPT_RUN_DATE=`date -d "$REPORT_DATE" '+%Y-%m-%d'`
$PYTHON /data/socorro/application/scripts/startDailyUrl.py --day=$SCRIPT_RUN_DATE

#DATA_FILE=`date -d "$REPORT_DATE" '+%Y%m%d-crashdata.csv.gz'`
#scp ${HOME}/${DATA_FILE} bacula@10.22.72.131:/data/security_group/crash_urls/
#scp ${HOME}/${DATA_FILE} mozauto@sisyphus.bughunter.ateam.phx1.mozilla.com:/work/mozilla/crash-reports/
#ssh bacula@10.22.72.131 'chmod 640 /data/security_group/crash_urls/*'
#ssh mozauto@sisyphus.bughunter.ateam.phx1.mozilla.com 'chmod 640 /work/mozilla/crash-reports/*'
#mv ${HOME}/${DATA_FILE} /tmp

DATA_FILE=`date -d "$REPORT_DATE" '+%Y%m%d-pub-crashdata.csv.gz'`
SCRIPT_RUN_DATE=`date -d "$REPORT_DATE" '+%Y%m%d'`
#scp $DATA_FILE bacula@people.mozilla.org:/var/www/html/crash_analysis/$SCRIPT_RUN_DATE/

mkdir -p /mnt/crashanalysis/crash_analysis/$SCRIPT_RUN_DATE/
cp $DATA_FILE /mnt/crashanalysis/crash_analysis/$SCRIPT_RUN_DATE/
mv ${HOME}/${DATA_FILE} /tmp

rm -f /tmp/daily_urls.lock
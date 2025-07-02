#!/bin/bash
SLACK_ALERTS_CHANNEL="<---SLACK-CHANNEL--->"
SLACK_AUTOMATION_BOT_TOKEN="<---SLACK-TOKEN--->"
TEKSTS="/home/scripts/cert/diff.log"
wget https://cert.lv/lv/rss/incidenti/bridinajumi.xml -O /home/scripts/cert/cert-`date +%d-%m-%Y`.log
DATNE="/home/scripts/cert/cert-`date +%d-%m-%Y`.log"
OLD="/home/scripts/cert/vecs.baze"
NEW="/home/scripts/cert/jauns.log"
cat $DATNE | grep -E '(title>|pubDate>|description>)' | sed -e 's/^[ \t]*//' | sed -e 's/<title>/\n/' -e 's/<\/title>//' -e 's/<pubDate>//' -e 's/<\/pubDate>//' -e 's/<description>//' -e 's/<\/description>//' | perl -p -e 's/&.* ?;//g' | sed 1,4d > $NEW
if diff <(sort $NEW) <(sort $OLD); then
    cd /home/scripts/cert/
    rm -f *.log
else
    if [ `cat $NEW | wc -l` -ge "2" ]; then
    echo "CERT brīdina! Jauni brīdinājumi https://cert.lv/lv/incidenti/bridinajumi. Pārbaudīts plkst. $(LANG='lv_LV.UTF-8'; date)" >> /var/log/cert.log
    diff <(sort $NEW) <(sort $OLD) > /home/scripts/cert/izmainas.log
    comm -23  <(sort -u $NEW) <(sort -u $OLD) > $TEKSTS
    MESSAGE_N="CERT brīdina!"
    cat $TEKSTS | awk 'NR == 3' > /home/scripts/cert/transform.log
    cat $TEKSTS | awk 'NR == 2' >> /home/scripts/cert/transform.log
    cat $TEKSTS | awk 'NR == 1' >> /home/scripts/cert/transform.log
    TEKSTS3="/home/scripts/cert/transform.log"
    cat $TEKSTS3 > $TEKSTS
    cat $TEKSTS | grep -v $(date +"%a") > /home/scripts/cert/uz-slack.log
    if [ `cat /home/scripts/cert/uz-slack.log | wc -l` -ge "1" ]; then
    MESSAGE_CLEAN=$(while read -r LINE; do echo '\n' "$LINE"; done < /home/scripts/cert/uz-slack.log)
    MESSAGE="$MESSAGE_N
$MESSAGE_CLEAN"
    curl -s -X POST -H 'Authorization: Bearer '"$SLACK_AUTOMATION_BOT_TOKEN"'' \
    -H 'Content-type: application/json' \
    --data '{"channel":"'"$SLACK_ALERTS_CHANNEL"'","text":":exclamation:
    '"`echo $MESSAGE`"'"}' \
    https://slack.com/api/chat.postMessage > /dev/null 2>&1
    else
    echo "CERT norādā tikai vienu satura rindinu."
    fi
    cd /home/scripts/cert/
    cp $OLD /home/scripts/cert/vecs.log
    cat $NEW > $OLD
    tar -cf "cert.lv_archive_$(date '+%Y-%m-%d_%H-%M').tar" *.log
    rm -f *.log
    else
    echo "CERT tuks saturs bridinajumam"
    fi
fi

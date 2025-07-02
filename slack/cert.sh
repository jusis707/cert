#!/bin/bash

HOME_SCRIPT="/XXX/XXX"
SLACK_ALERTS_CHANNEL="<---SLACK-CHANNEL--->"
SLACK_AUTOMATION_BOT_TOKEN="<---SLACK-TOKEN--->"
VAR_LOG_CERT="/var/log/cert.log" # Path to the main log file

TEKSTS="$HOME_SCRIPT/diff.log"
DATNE="$HOME_SCRIPT/cert-$(date +%d-%m-%Y).log"
OLD="$HOME_SCRIPT/vecs.baze"
NEW="$HOME_SCRIPT/jauns.log"
IZMAINAS_LOG="$HOME_SCRIPT/izmainas.log"
TRANSFORM_LOG="$HOME_SCRIPT/transform.log"
UZ_SLACK_LOG="$HOME_SCRIPT/uz-slack.log" # Renamed from uz-email.log for Slack context

mkdir -p "$HOME_SCRIPT"

wget https://cert.lv/lv/rss/incidenti/bridinajumi.xml -O "$DATNE"

cat "$DATNE" | grep -E '(title>|pubDate>|description>)' | \
sed -e 's/^[ \t]*//' -e 's/<title>/\n/' -e 's/<\/title>//' -e 's/<pubDate>//' -e 's/<\/pubDate>//' -e 's/<description>//' -e 's/<\/description>//' | \
perl -p -e 's/&.* ?;//g' | sed '1,4d' > "$NEW"

if diff <(sort "$NEW") <(sort "$OLD"); then
    echo "CERT.LV brīdinājumi nemainīgi, pārbaudīts plkst. $(LANG='lv_LV.UTF-8'; date)" >> "$VAR_LOG_CERT"
    cd "$HOME_SCRIPT" || { echo "Error: Cannot change directory to $HOME_SCRIPT. Exiting."; exit 1; }
    rm -f *.log
else
    if [ "$(cat "$NEW" | wc -l)" -ge "2" ]; then
        echo "CERT brīdina! Jauni brīdinājumi https://cert.lv/lv/incidenti/bridinajumi. Pārbaudīts plkst. $(LANG='lv_LV.UTF-8'; date)" >> "$VAR_LOG_CERT"

        diff <(sort "$NEW") <(sort "$OLD") > "$IZMAINAS_LOG"
        comm -23 <(sort -u "$NEW") <(sort -u "$OLD") > "$TEKSTS"

        cat "$TEKSTS" | awk 'NR == 3' > "$TRANSFORM_LOG"
        cat "$TEKSTS" | awk 'NR == 2' >> "$TRANSFORM_LOG"
        cat "$TEKSTS" | awk 'NR == 1' >> "$TRANSFORM_LOG"
        cat "$TRANSFORM_LOG" > "$TEKSTS" # Overwrite TEKSTS with transformed content

        cat "$TEKSTS" | grep -v "$(date +"%a")" > "$UZ_SLACK_LOG"

        if [ "$(cat "$UZ_SLACK_LOG" | wc -l)" -ge "1" ]; then
            MESSAGE_N="CERT brīdina!"
            MESSAGE_CLEAN=$(while read -r LINE; do echo '\n' "$LINE"; done < "$UZ_SLACK_LOG")
            MESSAGE="${MESSAGE_N}${MESSAGE_CLEAN}"

            curl -s -X POST -H 'Authorization: Bearer '"$SLACK_AUTOMATION_BOT_TOKEN"'' \
            -H 'Content-type: application/json' \
            --data '{"channel":"'"$SLACK_ALERTS_CHANNEL"'","text":":exclamation: '"`echo "$MESSAGE"`"'"}' \
            https://slack.com/api/chat.postMessage > /dev/null 2>&1
            
            if [ $? -eq 0 ]; then
                echo "Slack message sent successfully." >> "$VAR_LOG_CERT"
            else
                echo "Failed to send Slack message." >> "$VAR_LOG_CERT"
            fi
        else
            echo "CERT norādā tikai vienu satura rindinu." >> "$VAR_LOG_CERT"
        fi

        cd "$HOME_SCRIPT" || { echo "Error: Cannot change directory to $HOME_SCRIPT. Exiting."; exit 1; }
        cp "$OLD" "$HOME_SCRIPT/vecs.log"
        cat "$NEW" > "$OLD"
        tar -cf "cert.lv_archive_$(date '+%Y-%m-%d_%H-%M').tar" *.log
        rm -f *.log
    else
        echo "CERT tuks saturs bridinajumam" >> "$VAR_LOG_CERT"
    fi
fi

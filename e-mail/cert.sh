#!/bin/bash
RECIPIENT_EMAIL="<---E-PASTS--PIRMAIS--->"
EMAIL_SECONDARY="<---E-PASTS---OTRAIS---(XXX@sms.lmt.lv)--->"
SENDER_NAME="CERT.LV Notifier"
EMAIL_SUBJECT="CERT.LV Brīdinājumi"

LOG_DIR="/XXX/XXX"
TEKSTS="$LOG_DIR/diff.log"
DATNE="$LOG_DIR/cert-$(date +%d-%m-%Y).log"
OLD="$LOG_DIR/vecs.baze"
NEW="$LOG_DIR/jauns.log"
IZMAINAS_LOG="$LOG_DIR/izmainas.log"
UZ_EMAIL_LOG="$LOG_DIR/uz-email.log"
TRANSFORM_LOG="$LOG_DIR/transform.log"
VAR_LOG_CERT="/var/log/cert.log"

#CACHET_API_URL="https://sesks.lu.lv/api/v1/incidents"
#CACHET_API_TOKEN="<---CACHET--TOKENS--->"
#PUSHBULLET_API_URL="https://api.pushbullet.com/v2/pushes"
#PUSHBULLET_ACCESS_TOKEN="<---PUSHBULLET--TOKENS--->"
CERT_LV_RSS_FEED="https://cert.lv/lv/rss/incidenti/bridinajumi.xml"
CERT_LV_INFO_URL="https://cert.lv/lv/incidenti/bridinajumi"

wget "$CERT_LV_RSS_FEED" -O "$DATNE"

cat "$DATNE" | grep -E '(title>|pubDate>|description>)' | \
sed -e 's/^[ \t]*//' -e 's/<pubDate>//' -e 's/<\/pubDate>//' -e 's/<description>//' -e 's/<\/description>//' | \
perl -p -e 's/&.* ?;//g' | sed '1,3d' > "$NEW"

if diff <(sort "$NEW") <(sort "$OLD"); then
    echo "CERT.LV brīdinājumi nemainīgi, pārbaudīts plkst. $(LANG='lv_LV.UTF-8'; date)" >> "$VAR_LOG_CERT"
    cd "$LOG_DIR" || exit
    rm -f *.log
else
    if [ "$(cat "$NEW" | wc -l)" -ge "2" ]; then
        echo "CERT brīdina! Jauni brīdinājumi $CERT_LV_INFO_URL. Pārbaudīts plkst. $(LANG='lv_LV.UTF-8'; date)" >> "$VAR_LOG_CERT"

        diff <(sort "$NEW") <(sort "$OLD") > "$IZMAINAS_LOG"
        comm -23 <(sort -u "$NEW") <(sort -u "$OLD") > "$TEKSTS"
        cat "$TEKSTS" | grep title | sed -e 's/<title>/\n/' -e 's/<\/title>//' > "$TRANSFORM_LOG"
        cat "$TEKSTS" | grep -v title >> "$TRANSFORM_LOG"
        cat "$TRANSFORM_LOG" > "$TEKSTS"

        cat "$TEKSTS" | grep -v "$(date +"%a")" > "$UZ_EMAIL_LOG"

        if [ "$(cat "$UZ_EMAIL_LOG" | wc -l)" -ge "1" ]; then
            MESSAGE_CLEAN=$(while read -r LINE; do echo "$LINE"; done < "$UZ_EMAIL_LOG")
            EMAIL_BODY="CERT brīdina!\n\n$MESSAGE_CLEAN\n\nPlašāka informācija: $CERT_LV_INFO_URL"
            MESSAGE_CLEAN_ESCAPED=$(echo "$MESSAGE_CLEAN" | sed ':a;N;$!ba;s/\n/\\n/g' | sed 's/"/\\"/g')
            EMAIL_BODY_JSON="CERT brīdina!\\n\\n${MESSAGE_CLEAN_ESCAPED}\\n\\nPlašāka informācija: $CERT_LV_INFO_URL"
            
            echo -e "$EMAIL_BODY" | mail -s "$EMAIL_SUBJECT" -r "$SENDER_NAME <$RECIPIENT_EMAIL>" "$RECIPIENT_EMAIL"
            echo -e "CERT.LV ALERT!" | mail -s "[ALERT] CERT.LV ALERT" "$EMAIL_SECONDARY"
            
#            curl -X POST "$CACHET_API_URL" \
            -H 'Content-Type: application/json' \
            -H "X-Cachet-Token: $CACHET_API_TOKEN" \
            -d "{\"name\":\"CERT.LV ISSUED AN ALERT!\",\"message\":\"${EMAIL_BODY_JSON}\",\"status\":2,\"visible\":1,\"component_id\":1,\"component_status\":2,\"notify\":\"false\",\"template\":\"GeneralIncidentTemplate\",\"vars\": {\"foo\":\"uno\", \"bar\":\"dos\", \"xyzzy\":\"tres\"}}"

 #           curl -X POST "$PUSHBULLET_API_URL" \
            -H "Access-Token: $PUSHBULLET_ACCESS_TOKEN" \
            -H 'Content-Type: application/json' \
            -d '{"type": "note", "title": "CERT ALERT", "body": "CERT ALERT"}' -k &>/dev/null

            if [ $? -eq 0 ]; then
                echo "Email sent successfully to $RECIPIENT_EMAIL." >> "$VAR_LOG_CERT"
            else
                echo "Failed to send email to $RECIPIENT_EMAIL." >> "$VAR_LOG_CERT"
            fi
        else
            echo "CERT norāda tikai vienu satura rindiņu." >> "$VAR_LOG_CERT"
        fi

        cd "$LOG_DIR" || exit
        cp "$OLD" "$LOG_DIR/vecs.log"
        cat "$NEW" > "$OLD"
        tar -cf "cert.lv_archive_$(date '+%Y-%m-%d_%H-%M').tar" *.log
        rm -f *.log
    else
        echo "CERT tukš saturs brīdinājumam" >> "$VAR_LOG_CERT"
    fi
fi

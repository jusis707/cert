# CERT.LV brīdinājumu apziņošana
# avots https://cert.lv/lv/rss/incidenti/bridinajumi.xm
</br>Uzstādīšana, divi varianti:
</br>1. Ar e-pasta izsūtīšanu:
</br>git clone https://github.com/jusis707/cert
</br>cd e-mail
</br>rediģējam:
</br>nano cert.sh
</br>norādam divas e-pasta adreses un mainam mapi LOG_DIR="/XXX/XXX/cert" uz Jūsu mapi.
</br>Iespējama, ziņojuma, nosūtīšana uz Cachet 'ziņojmu dēļa', izaucot API, aizkomentēts, jānomaina <---CACHET-TOKENS--->.
</br>2. Ar ziņojumu nosūtīšanu uz 'Slack': 
</br>git clone https://github.com/jusis707/cert
</br>cd slack
</br>rediģējam:
</br>nano cert.sh
</br>norādam Slack kanalu u Slack tokenu.
</br>Mainam, atrašanās vieto no:
</br>HOME_SCRIPT="/XXX/XXX" uz Jūsu mapi.
</br>Jebkura iespēja, jāparedz ar cron turpmāko darbību:
</br>crontab -e
</br>*/2 * * * * /XXX/XXX/cert.sh >> /var/log/cert.log 2>&1
</br>
</br>
</br>

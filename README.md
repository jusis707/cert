# CERT.LV brīdinājumu apziņošana
</br>Uzstādīšana, divi varianti:
</br>1. Ar e-pasta izsūtīšanu:
</br>git clone https://github.com/jusis707/cert
</br>cd e-mail
</br>rediģējam:
</br>nano cert.sh
</br>norādam divas e-pasta adreses.
</br>Iespējama Cachet 'ziņojmu dēļa' nosūtīšana caur API, aizkomentēts.
</br>2. Ar ziņojumu nosūtīšanu uz 'Slack': 
</br>git clone https://github.com/jusis707/cert
</br>cd slack
</br>rediģējam:
</br>nano cert.sh
</br>norādam Slack kanalu u Slack tokenu.
</br>
</br>Jebkura iespēja, jāparedz ar cron turpmāko darbību:
</br>crontab -e
</br>*/2 * * * * /XXX/XXX/cert.sh >> /var/log/cert.log 2>&1
</br>
</br>
</br>

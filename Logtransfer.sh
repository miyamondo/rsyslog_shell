#!/bin/bash 
# upload to blob script
# Environment Settings
BASE=/var/local/scripts
LOGFILE=${BASE}/access.log
LOG_PATH=/log/Web
LOG_NAME=\*.log-$(date --date '1 day ago' +%Y%m%d)
ARC_PATH=/tmp/archive
ARC_FILE=Web_$(date --date '1 day ago' +%Y%m%d).zip
DEST_URL=<ストレージアカウントのURL>
TEMPzip=${BASE}/templates/Web/failed-zip.txt
TEMPazcopy=${BASE}/templates/Web/failed-azcopy.txt
TEMPnomal=${BASE}/templates/Web/success.txt
MSG=${BASE}/Web_message.txt
SMTP=<smtpサービスのドメイン>
SMTP_APIKEY=<smtpサービスのキー>
SMTP_PW=<smtpサービスのパスワード>
SMTP_SRC_ADDRESS=<送信元メールアドレス>
SMTP_DST_ADDRESS=<宛先メールアドレス>

# Remove plan file and log
azcopy login --identity >/dev/null
azcopy jobs clean >/dev/null

#Logging settings
rm -f $LOGFILE
exec 1> >(awk '{print strftime("[%Y-%m-%d %H:%M:%S] "),$0 } { fflush() } ' >> $LOGFILE)
exec 2> >(awk '{print strftime("[%Y-%m-%d %H:%M:%S] "),$0 } { fflush() } ' >> $LOGFILE)
echo ----- $0 is start -----

# compress
echo ----- logfile compress start -----
find $LOG_PATH -name $LOG_NAME -exec zip -r ${ARC_PATH}/${ARC_FILE} {} \;
if [ $? = 0 ]; then
 echo --- target files ---
 find $LOG_PATH -name $LOG_NAME
 echo --- archive file ---
 ls -ltr $ARC_PATH
 echo ----- logfile compress finish -----
else
 echo ----- logfile compress error -----
 cp -fp $TEMPzip $MSG
 cat $LOGFILE >> $MSG
 mailx -s "Web ログ転送結果:NG" \
  -S smtp=${SMTP} \
  -S smtp-auth-user=${SMTP_APIKEY} \
  -S smtp-auth-password=${SMTP_PW} \
  -S from=${SMTP_SRC_ADDRESS} \
  ${SMTP_DST_ADDRESS} < $MSG
 exit 1
fi

# azcopy
echo ----- upload to blobstart -----
azcopy copy ${ARC_PATH}/${ARC_FILE} ${DEST_URL}/${ARC_FILE} >/dev/null
if [ $? = 0 ]; then
 echo ----- upload to blob finish -----
 echo ----- file remove start -----
 echo remove file = $ARC_FILE
 rm -f ${ARC_PATH}/${ARC_FILE}
 echo ----- file remove finish -----
else
 echo ----- upload to blob error -----
 cp -fp $TEMPazcopy $MSG
 cat $LOGFILE >> $MSG
 mailx -s "Web ログ転送結果:NG" \
  -S smtp=${SMTP} \
  -S smtp-auth-user=${SMTP_APIKEY} \
  -S smtp-auth-password=${SMTP_PW} \
  -S from=${SMTP_SRC_ADDRESS} \
  ${SMTP_DST_ADDRESS} < $MSG
 exit 1
fi


echo ----- $0 is complite!! -----
cp -fp $TEMPnomal $MSG
cat $LOGFILE >> $MSG
mailx -s "Web ログ転送結果:OK" \
  -S smtp=${SMTP} \
  -S smtp-auth-user=${SMTP_APIKEY} \
  -S smtp-auth-password=${SMTP_PW} \
  -S from=${SMTP_SRC_ADDRESS} \
  ${SMTP_DST_ADDRESS} < $MSG
exit 0 
 
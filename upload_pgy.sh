ipaFilePath=`find ./build -iname *.ipa`
USER_KEY="775470b79bf123b24157719ec27b8b41"
API_KEY="03b18f63ec269c3db835bf7545d7fa0f"
MSG=`date '+%Y-%m-%d %H:%M:%S'`

#密码安装方式
installType=2
PASSWORD="7788"

curl -F "file=@${ipaFilePath}" -F "uKey=${USER_KEY}" -F "_api_key=${API_KEY}" -F "updateDescription=${MSG}" -F "installType=${installType}" https://qiniu-storage.pgyer.com/apiv1/app/upload

echo "\n upload pgy done"

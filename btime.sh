# Licence: GPLv2
#Please put THIS_IS_CRON=1 in crotab
if [ -n "$THIS_IS_CRON" ]
then 
btime=$(($(dash-cli getblockcount)-880648-1662))&&remainder=$(($btime % 16616));if [ $remainder -le 10 ];then /home/demo/bin/mnowatch.sh -super;fi
else
echo "I'm running only in cron"
fi

#!/bin/bash

# Licence: GPLv2
# The author of the software is the owner of the Dash Address: XnpT2YQaYpyh7F9twM6EtDMn1TCDCEEgNX
#
# MNOWATCH VERSION: 0.02

#=============== ISTRUCTIONS ==========================================
# In order for this to work you have to put THIS_IS_CRON=1 into crontab
# Look at crontab.example
#=============== END OF ISTRUCTIONS ===================================

if [ -n "$THIS_IS_CRON" ]
then 
btime=$(($(dash-cli getblockcount)-880648-1662))&&remainder=$(($btime % 16616));if [ $remainder -le 10 ];then /home/demo/bin/mnowatch.sh -super;fi
else
echo "I'm running only in cron"
fi

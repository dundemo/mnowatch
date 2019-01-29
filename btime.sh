#!/bin/bash

# Licence: GPLv2
# The author of the software is the owner of the Dash Address: XnpT2YQaYpyh7F9twM6EtDMn1TCDCEEgNX
# Tweaking / Debugging / Blockchain Advices by xkcd@dashtalk
#
# MNOWATCH VERSION: 0.03

#=============== ISTRUCTIONS ==========================================
# 1) SET MYHOME_DIR.
MYHOME_DIR="/home/demo"
# 2) ALL MNOWATCH GITHUB FILES MUST RESIDE INTO $MYHOME_DIR/bin
# 3) In order for this to work you have to put THIS_IS_CRON=1 into crontab.
#    Look at the provided crontab.example file.
#=============== END OF ISTRUCTIONS ===================================

if [ -n "$THIS_IS_CRON" ]
then 
 btime=$(($(dash-cli getblockcount)-880648-1662))&&remainder=$(($btime % 16616))
 if [ $remainder -le 10 ]
 then 
  echo $btime","$remainder","`date -u` > /tmp/The_voting_deadline
  $MYHOME_DIR/bin/mnowatch.sh -super
 else
  echo $btime","$remainder","`date -u` > /tmp/Not_a_voting_deadline
 fi
else
echo $(($(($(dash-cli getblockcount)-880648-1662)) % 16616))
 echo "This bash should be executed only by cron daemon."
fi

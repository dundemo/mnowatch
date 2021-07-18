#!/bin/bash
#set -x

# Licence: GPLv2
# Code / Tweaking / Debugging / Blockchain Advices by xkcd#7307@dashtalk Discord
#
# MNOWATCH VERSION: 0.14
#=============== INSTRUCTIONS =========================================
# 1) SET MYHOME_DIR. in case you dont want it to be $HOME
#MYHOME_DIR="/home/demo"
MYHOME_DIR=$HOME
# 2) ALL MNOWATCH GITHUB FILES MUST RESIDE INTO $MYHOME_DIR/bin
# 3) In order for this to work you have to put THIS_IS_CRON=1 into crontab.
#    Look at the provided crontab.example file.
# 4) If you want to connect to a remote dash-cli, set LOCAL_DASHCLI to 0 and edit the config file.
LOCAL_DASHCLI=0
#==========================END OF INSTRUCTIONS ==================
MYCONFIG_DIR=$MYHOME_DIR"/bin"
which dash-cli>/dev/null||{ echo "I dont know where the command dash-cli is. Please put dash-cli in your execution path.";exit;}
if [ $LOCAL_DASHCLI -eq 0 ]
then
 rpcuser=$(cut -f1 -d, $MYCONFIG_DIR/config.txt)
 rpcpassword=`cut -f2 -d, $MYCONFIG_DIR/config.txt`
 rpcconnect=`cut -f3 -d, $MYCONFIG_DIR/config.txt`
fi
dcli () {
 if [ $LOCAL_DASHCLI -eq 0 ]
 then
#         echo remote dash-cli
  dash-cli -datadir=/tmp -rpcuser=$rpcuser -rpcpassword=$rpcpassword -rpcconnect=$rpcconnect "$@" 2>&1  || { echo "The command dash-cli does not work remotely.";exit;}
 else
#         echo local dash-cli
  dash-cli "$@" 2>&1  || { echo "I dont know where the command dcli is. Please put dcli in your execution path.";exit;}
 fi
}



test -n "$THIS_IS_CRON"||{ echo "This bash should be executed only by cron daemon.";exit 1;}
block=$(dcli getblockcount)||{ echo "dashd error getting block height.";exit 2;}
remainder=$((($block-880648+1662) % 16616))
run_prog="$MYHOME_DIR/bin/mnowatch.sh"
test -x "$run_prog"||{ echo "Cannot execute $run_prog";exit 3;}
msg="$block,$remainder,$(date -u)"

# We want to run mnowatch just after the voting has closed.
if [ $remainder -le 5 ];then
	echo "$msg" > /tmp/The_voting_deadline
	"$run_prog" -super
	exit 0
else
	echo "$msg" > /tmp/Not_a_voting_deadline
fi

# We want to run mnowatch at regular intervals the day before voting closes to catch last minute vote changes.
# DASH block time is 2.625 mins on average, 60*24 mins in a day, 16616 blocks between cycles.
# Thus, 16616 - (24*60/2.65) = 16068.  We run more often if the remainder is larger than this number.

procs=$(ps aux)
num_instances_this=$(echo "$procs"|grep "$0"|wc -l)
num_instances_prog=$(echo "$procs"|grep "$run_prog"|wc -l)

if [ $num_instances_this -le 1 -a $num_instances_prog -eq 0 -a $remainder -ge 16068 ];then
# Note 1: No new report appears in case it is identical to the previous one.

# Note 2: In case you dont calculate the similarities, mnowatch.sh lasts about 2 minutes. In that case you can sleep less than 3600. 
# If you want to exclude  similarities you should run: mnowatch.sh 0

	"$run_prog"
#	"$run_prog" 0
	sleep 3600
#	sleep 120

fi



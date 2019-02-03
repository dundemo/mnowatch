#!/bin/bash
#set -x

# Licence: GPLv2
# Tweaking / Debugging / Blockchain Advices by xkcd#7307@dashtalk Discord
#
# MNOWATCH VERSION: 0.05

#=============== INSTRUCTIONS =========================================
# 1) SET MYHOME_DIR.
MYHOME_DIR="/home/demo"
# 2) ALL MNOWATCH GITHUB FILES MUST RESIDE INTO $MYHOME_DIR/bin
# 3) In order for this to work you have to put THIS_IS_CRON=1 into crontab.
#    Look at the provided crontab.example file.
#=============== END OF ISTRUCTIONS ===================================

test -n "$THIS_IS_CRON"||{ echo "This bash should be executed only by cron daemon.";exit 1;}
block=$(dash-cli getblockcount)||{ echo "dashd error getting block height.";exit 2;}
remainder=$((($block-880648+1662) % 16616))
run_prog="$MYHOME_DIR/bin/mnowatch.sh"
test -x "$run_prog"||{ echo "Cannot execute $run_prog";exit 3;}
msg="$block,$remainder,$(date -u)"

# We want to run mnowatch just after the voting has closed.
if [ $remainder -le 10 ];then
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
	"$run_prog"
	sleep 3600
fi



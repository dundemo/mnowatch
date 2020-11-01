#!/bin/bash
#set -x

# Licence: GPLv2
# The author of the software is the owner of the Dash Address: XnpT2YQaYpyh7F9twM6EtDMn1TCDCEEgNX
# Tweaking / Debugging by xkcd@dashtalk 
#
# MNOWATCH VERSION: 0.13
# COMPATIBLE TO DASHD VERSION 16 (works also for DASHD VERSION 12 and above)

#==========================INSTRUCTIONS ======================

# 1) Set MYHOME_DIR to whatever DIR you want, provided that the script has read/write priviledges there. 
#    example: MYHOME_DIR="/home/demo"
#    You may also leave the below as it is, in case you want everything to reside in $HOME.
MYHOME_DIR=$HOME
# 2) IMPORTANT: All MNOWATCH files must reside into $MYHOME_DIR/bin, so create that dir and put them inside it.
# 3) Run the script. It runs silently and lasts about 2 minutes (in an Intel Xeon 2.7 Ghz)
#    If the script ends withour errors, everything is fine. Check $MYHOME_DIR/httpd for new reports.
#    No new report will appear in case the previous report is identical.
# 4) Set SIMILARNUM less than 99 and greater than 0 in case you want to spot similarities.
#    WARNING: Setting $SIMILARNUM greater than 0 may cause HUGE delays in script's execution!
#    If you want to overwrite the default SIMILARNUM you can run: mnowatch.sh <number>
SIMILARNUM=90
#==========================END OF INSTRUCTIONS ==================
which dash-cli>/dev/null||{ echo "I dont know where the command dash-cli is. Please put dash-cli in your execution path.";exit;}
which bc>/dev/null||{ echo "I dont know where the command bc is. Please put bc in your execution path.";exit;}
which zip>/dev/null||{ echo "I dont know where the command zip is. Please put zip in your execution path.";exit;}
which ssdeep>/dev/null||{ echo "I dont know where ssdeep command is. Please put ssdeep in your execution path.";exit;}

#checkbin=`cd \`dirname $0\` &&pwd|grep /bin$|wc -l`
checkbin=$(cd $(dirname $0) &&pwd|grep /bin$|wc -l)

if [ $checkbin -eq 0 ]; then
test -n "$THIS_IS_CRON"||{ echo "INSTALLATION ERROR: Please put all the mnowatch github files into the directory named "$MYHOME_DIR"/bin";}
exit 
fi 

BIN_DIR=$MYHOME_DIR"/bin"

#The below seems not to run in cron so I commented it.
#lsfiles=`cd $BIN_DIR;ls ansi2html.sh btime.sh jsssdeep.html mnowatch.sh ssdeepit.sh 2>/dev/null`
#lsfilescheck=`echo $lsfiles|grep "ansi2html.sh btime.sh jsssdeep.html mnowatch.sh ssdeepit.sh"|wc -l`
#if [ $lsfilescheck -ne 1 ]; then 
#test -n "$THIS_IS_CRON"||{ echo "FILES MISSING: Please put ALL the github mnowatch files into THE SAME directory named "$MYHOME_DIR"/bin";}
#exit
#fi 

TMP_DIR=$MYHOME_DIR"/tmp" 
if [ ! -d $TMP_DIR ] ; then 
 mkdir $TMP_DIR||{ echo "Unable to create directory $TMP_DIR. Please check your read-write priviledges.";exit 1;}
fi
HTTPD_DIR=$MYHOME_DIR"/httpd" ; if [ ! -d $HTTPD_DIR ] ; then mkdir $HTTPD_DIR ; echo "<html><body>" > $HTTPD_DIR/index.html ; echo "Hello world. The time of the reports is UTC. <br>" >> $HTTPD_DIR/index.html ; echo "</body></html>" >> $HTTPD_DIR/index.html ; fi;

TYPES_DIR=$MYHOME_DIR"/httpd/Types" ; if [ ! -d $TYPES_DIR ] ; then mkdir $TYPES_DIR ; echo "<html><body>" > $TYPES_DIR/index.html ; echo "Here we explain the reason why the admins classified some masternodes into a specific type.<p> " >> $TYPES_DIR/index.html ; echo "</body></html>" >> $TYPES_DIR/index.html ; fi;

PREVIUSREPORT=`cd $HTTPD_DIR;ls -tra the_results_dashd_*.html.csv 2>/dev/null|tail -1`
PREVIUSREPORTCOUNT=`echo $PREVIUSREPORT|wc -c`
if [ $PREVIUSREPORTCOUNT -gt 1 ]
then
PREVIUSREPORTFULL=$HTTPD_DIR"/"$PREVIUSREPORT
else
PREVIUSREPORTFULL=""
fi

superblock=0
if [ $# -gt 0 ] ; then
  re='^[0-9]+$'
  if [[ $1 =~ $re ]] ; then
    if [[ $1 -ge 0 && $1 -lt 100 ]] ; then
      SIMILARNUM=$1
    fi
  elif [ $1 == '-super' ] ; then
#BUG in case the super report is identical to the previous report, not "--end of vote" tag appears in index.html
    superblock=1
    if [ $# -gt 1 ] ; then
      if [[ $2 =~ $re ]] ; then
        if [[ $2 -ge 0 && $2 -lt 100 ]] ; then
          SIMILARNUM=$2
        fi
      fi
    fi
  fi
fi


#echo "SIMILARNUM=$SIMILARNUM superblock=$superblock"

codeurl="https://github.com/dundemo/mnowatch"
codeurl2="You may find the code used to produce this report <a href=\""$codeurl"\"> here </a>. The time of the report is UTC. <br>"

if [ $superblock -gt 0 ]
then
codeurl2=$codeurl2" <strong>This Report occured as close as possible to the Votes Deadline</strong><br>"
fi


for pid in $(pidof -x mnowatch.sh); do
    if [ $pid != $$ ]; then
        echo "[$(date)] : mnowatch.sh : Process is already running with PID $pid"
        exit 1
    fi
done

#procs=`ps -aux|grep mnowatch.sh|wc -l`
#if [ $procs -gt 3 ]
#then
#exit
#fi


cd $TMP_DIR
rm -rf *_* upload proposals

#crowdnodes=`wget -qO- crowdnode.io|grep ">MN"|awk -F"address/" '{for(i=2;i<=NF;i++){{print $i}}}'  |cut -f1 -d'"'|cut -f1 -d"."|uniq`
#second (working) version
#crowdnodes=`wget -qO- crowdnode.io|grep ">MN"|awk -F"address.dws" '{for(i=2;i<=NF;i++){{print $i}}}'  |cut -f1 -d'"'|cut -f1 -d"."|uniq|cut -f2 -d?`
#xkcd version

#crowdnodes=`wget -qO- crowdnode.io|grep ">MN"|awk -F"address.dws" '{for(i=2;i<=NF;i++){{print $i}}}'|sed 's/.\(.\{34\}\).*/\1/g'|uniq`

#BUG: https://app.crowdnode.io/ is more accurate! Use it, instead of crowdnode.io. Unfortunately it provides info about IPs rather than addresses, but we could fix that somehow.
wget -qO- crowdnode.io|grep ">MN"|awk -F"address.dws" '{for(i=2;i<=NF;i++){{print $i}}}'|sed 's/.\(.\{34\}\).*/\1/g'|uniq > $HTTPD_DIR/Types/CrowdNode.txt

#dash-cli masternodelist|jq -r '.[]| "\(.collateraladdress) \(.address)"'
#dash-cli masternodelist|jq 'keys'
dash-cli masternodelist|jq -r '.[]| "\(.collateraladdress) \(.address)"'|cut -f1 -d: > collateraladdress_IP

#TO DO: Make the script intedendant of dashcentral.org api. Read directly the active proposals by using dash-cli
#look at https://insight.dashevo.org/insight-api-dash/gobject/list
#Look at the end_epoch
#End epoch occurs in the middle of the month, so if a proposal ends in the middle of the month is considered as non active
#They define an overlap of two weeks prior to a superblock and two weeks after
#It accounts for the fact that superblocks don't fall into exact date times
#To put a flag and inform that this proposal will expire in the middle of the cycle, so that it is not taken as active one.
#delete all supposed active proposals that end in the middle of the cycle.
#it will be removed from the Active tab after the last superblock  overlaps with has occurred. So no, it will no longer be "active"

#TO_DO: In order to et rid of the cashcentral dependancy : dash-cli gobject list proposals (and search for endepoch to be more than the 14 of the current month)
#dash-cli gobject list valid proposals|grep end_epoch|wc -l

#old working version
#curl -s https://www.dashcentral.org/api/v1/budget > centralproposals_json
#awk -F"\"name" '{for(i=2;i<=NF;i++){{print $i}}}' centralproposals_json|cut -f2 -d":"|cut -f1 -d","|sed -e s/\"//g > current_props

#xkcd version

#curl -s https://www.dashcentral.org/api/v1/budget|jq '.proposals[].name'|sed 's/"//g' > current_props

#mytry without dashcentral
#dash-cli gobject list valid proposals|grep end_epoch|sort -nr -t: -k7|cut -f3-4 -d:|cut -f1-2 -d,|sed -e s/'\\"name\\":\\"'/''/g|sed -e s/'\\"'/''/g > newpros
#nextsuperblockseconds=$(echo "($(dash-cli getgovernanceinfo|jq -r '.nextsuperblock') - $(dash-cli getblockcount))*2.625*60"|bc)
#nextsuperblockseconds=$(printf "%.0f" $nextsuperblockseconds)
#nextsuperblocktime=$((nextsuperblockseconds + EPOCHSECONDS))
#for fn in `cat newpros`; do
#        comp=`echo $fn|cut -f1 -d,`
#        if [ $comp -gt $nextsuperblocktime ]
#        then
#                echo $fn|cut -f2 -d,
#        fi
#done
#end mytry

cat /dev/null > current_props
#xkcd version without dashcentral
nextsuperblockseconds=$(echo "($(dash-cli getgovernanceinfo|jq -r '.nextsuperblock') - $(dash-cli getblockcount))*2.625*60"|bc)
nextsuperblockseconds=$(printf "%.0f" $nextsuperblockseconds)
nextsuperblocktime=$((nextsuperblockseconds + EPOCHSECONDS))
dash-cli gobject list valid proposals|grep end_epoch|sort -nr -t: -k7|cut -f3-4 -d:|cut -f1-2 -d,|sed -e s/'\\"name\\":\\"'/''/g|sed -e s/'\\"'/''/g|while IFS=, read time name;do if ((time>nextsuperblocktime));then echo "$name">>current_props;fi;done
#end xkcd

echo  > expired_props

#dash-cli masternodelist addr > masternodelist_addr
#BUGGY VERSION: dash-cli masternodelist full ENABLED|cut -f1-3,19 -d" "|sed -e "s/: /: \"/g"|grep -v "[0:0:0:0:0:0:0:0]:0" > masternodelist_addr
#dash-cli masternodelist full ENABLED|awk '{print $1" \""$7}'|grep -v "[0:0:0:0:0:0:0:0]:0" > masternodelist_addr
dash-cli masternodelist addr|grep -v "[0:0:0:0:0:0:0:0]:0" > masternodelist_addr #https://github.com/dashpay/dash/issues/2942

#dash-cli masternodelist payee > masternodelist_payee

#TO DO: Use this payee address to do more smart groupings
#TO DO: After spork 15 the payee is not valid, we should check collateraladdress
dash-cli gobject list > gobject_list

#old working code
#grep "{" gobject_list|grep -v "DataString"|cut -f2 -d"\""|grep -v "{" > proposals
#xkcd version
jq -r '.[].Hash' gobject_list > proposals

for fn in `cat proposals`; do
dash-cli gobject getcurrentvotes $fn > "gobject_getcurrentvotes_"$fn
numi=$(grep -n "\"Hash\": \""$fn gobject_list|tail -1|cut -f1 -d":")
((numi--))
numip=$numi"p"
prop=$(sed -n $numip gobject_list|cut -f4 -d":"|cut -f2 -d"\\"|sed 's/"//g')
#echo $prop

greprop=`grep "^$prop$" current_props |wc -c`
#echo $greprop
if [ $greprop -gt 1 ]
then

propc=`echo $prop|wc -c`
if [ $propc -gt 1 -a $propc -lt 200 ]
then

#old working code		
#grep -i ABSTAIN:FUNDING "gobject_getcurrentvotes_"$fn|cut -f3 -d"("|cut -f1 -d")"|sed -e s/", "/-/g |cut -f2 -d":" > "ABSTAIN_"$prop
#xkcd version
grep -i ABSTAIN:FUNDING "gobject_getcurrentvotes_"$fn|awk -F \: '{print $2}' > "ABSTAIN_"$prop

>"ABSTAIN_IP_"$prop
for gn in `cat "ABSTAIN_"$prop`; do
grep $gn\" masternodelist_addr|cut -f2 -d":"|cut -f2 -d"\"" >> "ABSTAIN_IP_"$prop
done
sort "ABSTAIN_IP_"$prop -o "ABSTAIN_IP_"$prop
#echo "ABS:"`wc -l "ABSTAIN_IP_"$prop|cut -f1 -d" "`

#old working code		
#grep -i NO:FUNDING "gobject_getcurrentvotes_"$fn|cut -f3 -d"("|cut -f1 -d")"|sed -e s/", "/-/g |cut -f2 -d":" > "NO_"$prop
#xkcd version
grep -i NO:FUNDING "gobject_getcurrentvotes_"$fn|awk -F \: '{print $2}' > "NO_"$prop

>"NO_IP_"$prop
for gn in `cat "NO_"$prop`; do
grep $gn\" masternodelist_addr|cut -f2 -d":"|cut -f2 -d"\"" >> "NO_IP_"$prop
done
sort "NO_IP_"$prop -o "NO_IP_"$prop
#echo "NO:"`wc -l "NO_IP_"$prop|cut -f1 -d" "`

#old working code		
#grep -i YES:FUNDING "gobject_getcurrentvotes_"$fn|cut -f3 -d"("|cut -f1 -d")"|sed -e s/", "/-/g |cut -f2 -d":" > "YES_"$prop
#xkcd version
grep -i YES:FUNDING "gobject_getcurrentvotes_"$fn|awk -F \: '{print $2}' > "YES_"$prop

>"YES_IP_"$prop
for gn in `cat "YES_"$prop`; do
grep $gn\" masternodelist_addr|cut -f2 -d":"|cut -f2 -d"\"" >> "YES_IP_"$prop
done
sort "YES_IP_"$prop -o "YES_IP_"$prop
#echo "YES:"`wc -l "YES_IP_"$prop|cut -f1 -d" "`


#else
#echo "PROPOSAL <"$prop"> not accepted"
fi

#else
#echo "PROPOSAL <"$prop"> is expired" |tee -a expired_props
fi

done
#echo "Please wait"
sed 's/\"//g;s/\ //g;s/,//g' masternodelist_addr|grep -v "[{}]"> masternodelist_hash_addr_clear
#IN THIS masternodelist_hash_addr_clear are included the masternodes who didnt vote and these who change state   and have same IPS
#due to this a non voted masternode was reported as voted!
#this bug has been solved in checkifitvoted variable
cut -f2 -d":" masternodelist_addr|cut -f2 -d"\""|grep -v "[{}]"|sort > masternodelist_addr_only_sorted

mkdir upload
cp masternodelist_addr_only_sorted ./upload
cp masternodelist_hash_addr_clear ./upload

for fn in *_IP_*; do
if [ -s $fn ]
then
cp $fn ./upload
fi
done
cd upload

# Decompress the javascript helper functions and add HTML file.
dateis=`date -u +"%Y-%m-%d-%H-%M-%S"`
dateisAndTypes=`echo $dateis" <p>Note: We argue why we classified each type into mnowatch.org\\/Types<p>"`

filenameis="../the_results_dashd_"$dateis".html"
echo "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
DyH4j//F3JFOFCQPussgAA=="|base64 -d|bzcat|sed -e s/"MNOWATCH from dashd thedateis<\/title>"/"MNOwatch - FirstResults $dateis <\/title><link rel=\"icon\" type=\"image\/png\" href=\"favicon.ico\">"/g|sed -e s/"thedateis"/"$dateisAndTypes"/g > $filenameis

sed -i '1i'"$codeurl2" $filenameis

csvfile=`echo $filenameis".csv"`
#a bug occurs to all proposals than contain a , in their proposal-name
#ex. proposal-name = VENEZUELAN-ALLIED-DASH-COMMUNITIES,Cash_Evolution_Bloomberg_Radio
> $csvfile
for gn in `cat masternodelist_hash_addr_clear`; do
MNhashis=`echo $gn|cut -f1 -d":"`
ipis=`echo $gn|cut -f2 -d":"`
mycollat=`grep " $ipis$" ../collateraladdress_IP|cut -f1 -d" "`


#ANOTHER TRY that IS SUCCESFULL
#transact=`dash-cli getaddresstxids '{"addresses": ["'$mycollat'"]}'|head -2|tail -1|cut -f2 -d"\""`
#blockis=`dash-cli getrawtransaction $transact 1|grep '"locktime":'|cut -f2 -d:|cut -f1 -d,`
#if [ -z $blockis ]
#then
#blockis=`dash-cli getrawtransaction $transact 1|grep '"height":'|head -1|cut -f2 -d:|cut -f1 -d,`
#fi
#if [ $blockis -eq 0 ]
#then
#blockis=`dash-cli getrawtransaction $transact 1|grep '"height":'|head -1|cut -f2 -d:|cut -f1 -d,`
#fi
#if [ -z $blockis ]
#then
#blockis=`dash-cli getrawtransaction $transact 1|grep '"spentHeight":'|head -1|cut -f2 -d:`
#fi
#blockhash=`dash-cli getblockhash $blockis`
#mediantime=`dash-cli getblock $blockhash|grep '"mediantime":'|cut -f2 -d:|cut -f1 -d,`
#mediantime="@"`echo $mediantime`
#earlytxdate=`date -u +"%Y-%m-%d-%H-%M-%S" -d $mediantime`

#Below an alternative example on how to get the creation date of a collat address by bitinfocharts
#wget -qO- -U 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.8.1.6) Gecko/20070802 SeaMonkey/1.1.4' https://bitinfocharts.com/dash/address/Xy14MCXe7CL5nXJVtsHS7evs1X3jpkjgxM |awk -F"muted utc hidden-desktop" '{for(i=2;i<=NF;i++){{print $i}}}'|cut -f1 -d"<"|tail -1|cut -f2 -d">"

if [ $PREVIUSREPORTCOUNT -gt 1 ]
then
 SEARCHINPREVIUS=`grep ","$mycollat"," $PREVIUSREPORTFULL|wc -l`		
 if [ $SEARCHINPREVIUS -eq 1 ]
 then
  earlytxdate=`grep ","$mycollat"," $PREVIUSREPORTFULL|cut -f9 -d,`
  #echo $mycollat $earlytxdate
 else
  #begin xkcd's contribution
  transact=$(dash-cli getaddresstxids '{"addresses": ["'$mycollat'"]}'|jq -r '.[0]')
  #echo "-----------------------------------------------"
  #echo "mycollat" $mycollat
  #echo "transact" $transact
  #echo "Exiting...please fix the bug in case the dash-cli does not work"
  #exit
  tx=$(dash-cli getrawtransaction $transact 1)
  blockis=$(jq -r '.locktime' <<< $tx)
  test -z "$blockis" && blockis=$(jq -r '.height' <<< "$tx")
  test "$blockis" -eq 0 && blockis=$(jq -r '.height' <<< "$tx")
  test -z "$blockis" && blockis=$(jq -r '.vout[0].spentHeight' <<< "$tx")
  blockhash=$(dash-cli getblockhash $blockis)
  mediantime="@"$(dash-cli getblock $blockhash|jq -r '.mediantime')
  earlytxdate=$(date -u +"%Y-%m-%d-%H-%M-%S" -d $mediantime)
 fi
else
 #begin xkcd's contribution
 transact=$(dash-cli getaddresstxids '{"addresses": ["'$mycollat'"]}'|jq -r '.[0]')
 #echo "-----------------------------------------------"
 #echo "mycollat" $mycollat
 #echo "transact" $transact
 #echo "Exiting...please fix the bug in case the dash-cli does not work"
 #exit
 tx=$(dash-cli getrawtransaction $transact 1)
 blockis=$(jq -r '.locktime' <<< $tx)
 test -z "$blockis" && blockis=$(jq -r '.height' <<< "$tx")
 test "$blockis" -eq 0 && blockis=$(jq -r '.height' <<< "$tx")
 test -z "$blockis" && blockis=$(jq -r '.vout[0].spentHeight' <<< "$tx")
 blockhash=$(dash-cli getblockhash $blockis)
 mediantime="@"$(dash-cli getblock $blockhash|jq -r '.mediantime')
 earlytxdate=$(date -u +"%Y-%m-%d-%H-%M-%S" -d $mediantime)
 #end xkcd's contribution
fi

#echo $mycollat $earlytxdate



# BUG: fix ipis in case this is not fixed: https://github.com/dashpay/dash/issues/2942
#echo $MNhashis $ipis

yesvotes=`grep -l ^$ipis$ *YES_IP_*|cut -f3- -d"_"`
yesvotes=`echo $yesvotes`
novotes=`grep -l ^$ipis$ *NO_IP_*|cut -f3- -d"_"`
novotes=`echo $novotes`
absvotes=`grep -l ^$ipis$ *ABSTAIN_IP_*|cut -f3- -d"_"`
absvotes=`echo $absvotes`

checkifitvoted=`grep -R $MNhashis ../*|grep gobject_getcurrentvotes|wc -l`
if [ $checkifitvoted -eq 0 ] 
then
checkmorethanoneIP=`grep $ipis":" masternodelist_hash_addr_clear|wc -l`
if [ $checkmorethanoneIP -gt 1 ] 
then
#echo $MNhashis $ipis
#grep -R $MNhashis ../*|grep gobject_getcurrentvotes
#grep $ipis":" masternodelist_hash_addr_clear
#echo $yesvotes $novotes $absvotes
yesvotes=""
novotes=""
absvotes=""
fi
fi

allvotes=$yesvotes","$novotes","$absvotes
#there was a bug when hashing $allvotes, in case a person has NO votes and not ABS votes, while another person has not NO votes but has ABS votes identical to the previous person's NO votes. I tried to fix it by comma separate instead of space.
hashis=`bc <<<ibase=16\;$(sha1sum <<<$allvotes|tr a-z A-Z)0`


iscrowdnode2=`grep $mycollat $TYPES_DIR/CrowdNode.txt|wc -l`
if [ $iscrowdnode2 -eq 1 ]
then
 mytypeis="CrowdNode"
else
 num_matches=`grep -l $MNhashis $TYPES_DIR/*.txt|wc -l`
 if [ $num_matches -gt 1 ]
 then
  mytypeis="TypeMismatched"
 else
  if [ $num_matches -eq 1 ]
  then
   num_matches2=`grep -l $MNhashis $TYPES_DIR/*.txt`
   mytypeis=`basename $num_matches2|cut -f1 -d.`
  else
   mytypeis="NoType"
  fi
 fi
fi

#iscrowdnode2=`echo $crowdnodes|grep $mycollat|wc -l`
#isbinance=`grep $MNhashis $HTTPD_DIR/Types/Binance.txt|wc -l`
#iscoinbase=`grep $MNhashis $HTTPD_DIR/Types/Coinbase.txt|wc -l`
#mismached=1
#mytypeis=""
#istype=0
#if [[ $iscrowdnode2 -eq 0 && $isbinance -eq 0 && $iscoinbase -eq 0 ]]
#then
# mytypeis="NoType"
# mismached=0
#else
# if [[ $iscrowdnode2 -gt 0 && $isbinance -eq 0 && $iscoinbase -eq 0 ]]
# then
#  mytypeis="CrowdNode"
#  istype=1
#  mismached=0
# fi
# if [[ $iscrowdnode2 -eq 0 && $isbinance -gt 0 && $iscoinbase -eq 0 ]]
# then
#  mytypeis="Binance"
#  istype=2
#  mismached=0
# fi
# if [[ $iscrowdnode2 -eq 0 && $isbinance -eq 0 && $iscoinbase -gt 0 ]]
# then
#  mytypeis="Coinbase"
#  istype=3
#  mismached=0
# fi
# if [ $mismached -gt 0 ]
# then
#  mytypeis="TypeMismatched"
#  istype=9999
# fi
#fi



echo "<tr><td class=\"container1\"><div><a target=\"_blank\" href=https://ipinfo.io/"$ipis">"$ipis"</a> "$MNhashis" <a target=\"_blank\" href=https://bitinfocharts.com/dash/address/"$mycollat">"$mycollat"</a> "$earlytxdate" "$mytypeis"</div></td><td class=\"container2\"><div>"$yesvotes"</div></td><td class=\"container3\"><div>"$novotes"</div></td><td class=\"container4\"><div>"$absvotes"</div></td><td class=\"container5\"><div>"$hashis"</div></td></tr>" >> $filenameis


#mycollat and iscrowdnode caused problem to ssdeepit.sh but I fixed it 
#Crowdnode type is 1, Binance type is 2. Coinbase is 3.

#Question: Instead of numbers, can I use plain names(stings) for types into the csv files? 
#Will ssdeepit.sh and uniquehashvote report behave propery? I should investigate it.

#echo "\"$ipis\",$MNhashis,$yesvotes,$novotes,$absvotes,\"$hashis\",$mycollat,$istype,$earlytxdate" >> $csvfile
echo "\"$ipis\",$MNhashis,$yesvotes,$novotes,$absvotes,\"$hashis\",$mycollat,$mytypeis,$earlytxdate" >> $csvfile
#echo "\"$ipis\",$MNhashis,$yesvotes,$novotes,$absvotes,\"$hashis\"" >> $csvfile
#echo -n "."
done

echo "
</tbody>
</table>
</body>
</html>
" >> $filenameis

cd ..

cp the_results_dashd_*.html.csv ../httpd
# Check it: diff plays in tty and not in cron!
# Warning! sometimes THERE iS diff in the_results.csv and there is no diff in the uniqueHashVotes.csv.
# This is because an mno who DID NOT voted appeared/left.

#TMP_DIR
#I am on TMP_DIR/
#pwd
#In order not to use ls -trad that crashes the kernel, I have to change dirs
#BUGFIX:the code breaks ls! ---> compareresultfiles=`ls -trad $HTTPD_DIR/*|grep the_results_dashd.*.html.csv$|grep -v uniqueHashVotes|tail -2|wc -l`
compareresultfiles=`ls -tra $HTTPD_DIR/|grep the_results_dashd.*.html.csv$|grep -v uniqueHashVotes|tail -2|wc -l`

if [ $compareresultfiles -eq 2 ]
then
#BUGFIX: compareresultfiles=`ls -trad $HTTPD_DIR/*|grep the_results_dashd.*.html.csv$|grep -v uniqueHashVotes|tail -2`
compareresultfiles=`ls -tra $HTTPD_DIR/|grep the_results_dashd.*.html.csv$|grep -v uniqueHashVotes|tail -2`
#I am on TMP_DIR/
#pwd
#In order not to use ls -trad that crashes the kernel, I have to change dirs
cd $HTTPD_DIR
 istherediff=`diff $compareresultfiles |wc -l`
cd $TMP_DIR
 if [[ ( $superblock -eq 0 && $istherediff -eq 0 ) || ( $superblock -eq 1 && $istherediff -eq 0 ) ]]
 then
  echo $dateis" --> No diffs found between "$compareresultfiles" . "`date -u` > /tmp/Mnowatch_diffs
#I am on TMP_DIR/
#pwd
#In order not to use ls -trad that crashes the kernel, I have to change dirs
cd $HTTPD_DIR
  diff $compareresultfiles >> /tmp/Mnowatch_diffs 
cd $TMP_DIR
  deletelatest=`ls -tra $HTTPD_DIR/the_results_dashd_*.html.csv|grep -v uniqueHashVotes|tail -1`
#WARNING. THE BELOW COMMAND IS EXTREMELY DANGERUS. MAKE SURE YOU ARE IN TMP_DIR
cd $TMP_DIR
  rm -rf $deletelatest *_* upload proposals
  exit
 else
  echo $dateis" DIFFS FOUND! "$istherediff > /tmp/Mnowatch_diffs
#I am on TMP_DIR/
#pwd
#In order not to use ls -trad that crashes the kernel, I have to change dirs
cd $HTTPD_DIR
  diff $compareresultfiles >> /tmp/Mnowatch_diffs 
cd $TMP_DIR
 fi
else
 echo "I cant find two files to compare" > /tmp/Mnowatch_diffs
fi

filetimeis="upload_"$dateis".tar"
tar -cf $filetimeis ./upload
gzip -9 $filetimeis

distrfileis="distr_"$dateis".txt"

echo "$dateis" > $distrfileis
echo "The first operator includes all people who dont vote at all. All the rest are identified by the way they vote." >> $distrfileis
cut -f24 -d"<" the_results_dashd_*.html|cut -f2 -d">"|grep -v [a-z]|grep -v [A-Z]| grep ^[0-9]|grep -v "-"|sort|uniq -c|sed -e s/'^   '/000/g|sed -s s/'000   '/000000/g|sed -e s/'000  '/00000/g|sed -s s/'000 '/0000/g|sort -r|cut -f1 -d" "|uniq -c|sed -e s/" 0"/" operator(s) control(s) "/g|sed -e s/$/" masternode(s)"/g >> $distrfileis

cp current_props ../httpd/current_props_"$dateis".txt
cp upload_*.tar.gz ../httpd
cp distr_*.txt ../httpd

cp the_results_dashd_*.html ../httpd
ADDTHIS="<br><a href=\""`ls ./distr_*.txt`"\"> the distribution $dateis </a> and <a href=\""`ls ./the_results*.html`"\"> the results $dateis </a> (<a href=\""`ls ./the_results*.html.csv`"\">csv</a>)" 
sed -i '3i'"$ADDTHIS" ../httpd/index.html

if [ $SIMILARNUM -gt 0 ]
then
$BIN_DIR/ssdeepit.sh `ls -tra $HTTPD_DIR/*html.csv|tail -1` $SIMILARNUM
cp the_results_dashd_*.similar.*.csv ../httpd
cp the_results_dashd_*.similar.*.html ../httpd
ADDTHIS=" and <a href=\""`ls ./the_results*.similar.*.csv`"\">the similarities.csv</a> (<a href=\""`ls ./the_results*.similar.*.html`"\">html</a>)" 
else
$BIN_DIR/ssdeepit.sh `ls -tra $HTTPD_DIR/*html.csv|tail -1`
ADDTHIS=" and didnt calculate similarites" 
fi
sed -i '4i'"$ADDTHIS" ../httpd/index.html

cp the_results_dashd_*.uniqueHashVotes.*.csv ../httpd
cp the_results_dashd_*.uniqueHashVotes.*.html ../httpd
ADDTHIS=" and <a href=\""`ls ./the_results*.uniqueHashVotes.*.csv`"\"> the uniqueVotesHashes.csv</a>"
sed -i '5i'"$ADDTHIS" ../httpd/index.html
#ADDTHIS=" (<a href=\""`ls ./the_results*.uniqueHashVotes.*.html`"\">html</a>)"
ADDTHIS="(<span style=\"background: #00ee00\"><a href=\""`ls ./the_results*.uniqueHashVotes.*.html`"\">html</a></span>)"
sed -i '6i'"$ADDTHIS" ../httpd/index.html
rm -rf *_* upload proposals

#here I change the working  directory to httpd 
cd $HTTPD_DIR

diffis=`ls -ltra|grep unique|tail -1|cut -f4 -d"_"|cut -f1 -d"."`.diff
filestodiff=`ls -lrta |grep unique|grep -v html |tail -2|cut -f2 -d":"|cut -f2 -d" "|wc -l`
if [ $filestodiff -eq 2 ]
then
#git diff --color-words --word-diff=plain --unified=0 `ls -lrta |grep unique|grep -v html |tail -2|cut -f2 -d":"|cut -f2 -d" "`|sed -e s/"IPS,YES_VOTES,NO_VOTES,ABSTAIN_VOTES,VOTES_HASH,HASH_OF_THE_SORTED_IPS,NUMBER_OF"/"------------------------------"/g > $diffis
#TO DO: debug git diff --color-words. It seems to put some IPs in the same line while we expect to be in separete lines.
git diff --color-words --word-diff=plain --unified=0 `ls -lrta |grep unique|grep -v html |tail -2|cut -f2 -d":"|cut -f2 -d" "` > $diffis
else
echo "" > $diffis
fi
ADDTHIS=" and <a href=\"./"$diffis"\">the git diff</a>"
sed -i '7i'"$ADDTHIS" ./index.html
#TO DO: debug ansi2html when looks like a table.
cat $diffis |$BIN_DIR/ansi2html.sh > $diffis.init.html

initfile="$HTTPD_DIR/$diffis.init.html"
targetfile="$HTTPD_DIR/$diffis.html"
tblstart=`grep -n ".csv</span>" $initfile |tail -1|cut -f1 -d:`
#TO DO: If git_diff is empty do not create a link of it in index.html, but rathere present the simple diff (which will contain the new IPs that appeared  who didnt vote at all,  but caused the new report to be triggered)
head -n $tblstart $initfile 2>/dev/null > $targetfile
echo "<style> table { font-family: arial, sans-serif; border-collapse: collapse; width: 100%; } td, th { border: 1px solid #dddddd; text-align: left; padding: 8px; } tr:nth-child(even) { background-color: #dddddd; } </style><table><thead><tr><th>IPS</th><th>YES_VOTES</th><th>NO_VOTES</th><th>ABSTAIN_VOTES</th><th>VOTESHASH</th><th>IPSHASH</th><th>NUM_OF_MNS</th><th>MNS</th></tr></thead><tbody><tr><td><div>" >> $targetfile
tblstart=`expr $tblstart + 1`
#TO DO: insert in every line the VOTEHASH as the keyword of the row <tr id=$VOTEHASH>. (how to do it without looping? maybe by using the command paste)
tail -n +$tblstart $initfile|grep -v "<span class=\"f6\">@@"|sed -e s/"^&quot;"/"<\/div><\/td><\/tr><tr><td><div>\&quot;"/g|sed -e s/"^<span class=\"f1\">"/"<\/div><\/td><\/tr><tr><td><div><span class=\"f1\">"/g|sed -e s/"^<span class=\"f2\">"/"<\/div><\/td><\/tr><tr><td><div><span class=\"f2\">"/g|sed -e s/,/"<\/div><\/td><td><div>"/g >> $targetfile
tblend=`grep -n "</pre>" $targetfile |tail -1|cut -f1 -d:`
ADDTHIS="</tr></td></tbody></table>"
tblend=$tblend"i$ADDTHIS"
sed -i $tblend $targetfile
ADDTHIS="<title>MNOwatch - Diff $dateis</title><link rel=\"icon\" type=\"image/png\" href=\"favicon.ico\">"
sed -i '3i'"$ADDTHIS" $targetfile
rm $initfile

ADDTHIS=" (<a href=\"./"$diffis.html"\">html</a>)"
sed -i '8i'"$ADDTHIS" ./index.html

if [ $superblock -gt 0 ]
then
ADDTHIS="-<strong>EndOfVote</strong>"
sed -i '9i'"$ADDTHIS" ./index.html
fi

#echo "END! "
$MYHOME_DIR/warnings/warnings.sh $dateis

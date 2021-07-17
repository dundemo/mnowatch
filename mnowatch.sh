#!/bin/bash
#set -x

# Licence: GPLv2
# The author of the software is the owner of the Dash Address: XnpT2YQaYpyh7F9twM6EtDMn1TCDCEEgNX
# Tweaking / Debugging by xkcd@dashtalk 
#
# MNOWATCH VERSION: 0.14
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
SIMILARNUM=0
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
#NOTE: EACHTIME A REPORT IS CREATED, WE INsERT IT IN THE 3rd row of index.html. The First 2 rows of index.html are reserved as shown below. You may change the 1st and second row, but keep space for the 3rd row to be inserted smoothly.
HTTPD_DIR=$MYHOME_DIR"/httpd" ; if [ ! -d $HTTPD_DIR ] ; then mkdir $HTTPD_DIR ; echo "<!DOCTYPE html><html lang=\"en\"><head><meta http-equiv=\"content-type\" content=\"text/html; charset=UTF-8\"><title>MNOwatch</title></head>" > $HTTPD_DIR/index.html ; echo "<body> Hello world. The time of the reports is UTC. <br>" >> $HTTPD_DIR/index.html ; echo '<!--  Everything below this line is updated by MNOWatch.sh, do not modify! -->' >> $HTTPD_DIR/index.html  ; echo "</body></html>" >> $HTTPD_DIR/index.html ; fi;

TYPES_DIR=$MYHOME_DIR"/httpd/Types" ; if [ ! -d $TYPES_DIR ] ; then mkdir $TYPES_DIR ; echo "<html><body>" > $TYPES_DIR/index.html ; echo "Here we explain the reason why the admins classified some masternodes into a specific type.<p> " >> $TYPES_DIR/index.html ; echo "</body></html>" >> $TYPES_DIR/index.html ; fi;

PREVIUSREPORT=`cd $HTTPD_DIR;ls -tra the_results_dashd_*.html.csv 2>/dev/null|tail -1`
PREVIUSREPORTCOUNT=`echo $PREVIUSREPORT|wc -c`
if [ $PREVIUSREPORTCOUNT -gt 1 ]
then
PREVIUSREPORTFULL=$HTTPD_DIR"/"$PREVIUSREPORT
else
PREVIUSREPORTFULL=""
fi

MYCOMMENT="" 
superblock=0
if [ $# -gt 0 ] ; then
  MYCOMMENT=$@ #comment is initialy all arguments. But then.....
  re='^[0-9]+$'
  if [[ $1 =~ $re ]] ; then
    if [[ $1 -ge 0 && $1 -lt 100 ]] ; then
      SIMILARNUM=$1
    fi
	MYCOMMENT=`echo $@|cut -f2- -d" "` #comment starts after the similarity number
  elif [ $1 == '-super' ] ; then
#BUG
#BUG in case the super report is identical to the previous report, not "--end of vote" tag appears in index.html
#BUG
    superblock=1
	MYCOMMENT=`echo $@|cut -f2- -d" "` # comment starts after the -super flag
    if [ $# -gt 1 ] ; then
      if [[ $2 =~ $re ]] ; then
        if [[ $2 -ge 0 && $2 -lt 100 ]] ; then
          SIMILARNUM=$2
        fi
	    MYCOMMENT=`echo $@|cut -f3- -d" "` #comment starts after the -super flag and the similarity number
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


cat <<"EOF"|sed -e s/"MNOWATCH from dashd thedateis<\/title>"/"MNOwatch - FirstResults $dateis <\/title><link rel=\"icon\" type=\"image\/png\" href=\"favicon.ico\">"/g|sed -e s/"thedateis"/"$dateisAndTypes"/g > $filenameis
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>MNOWATCH from dashd thedateis</title>
<style>
table {counter-reset: rowNumber -1;}
table tr {
  counter-increment: rowNumber;
}
table tr td:first-child::before {
  content: counter(rowNumber)")";
  min-width: 1em;
  margin-right: 0.5em;
}
td.container1 > div ,td.container3 > div ,td.container4 > div ,td.container5 > div ,td.container6 > div ,td.container7 > div ,td.container8 > div ,td.container9 > div ,td.container10 > div ,td.container11 > div {
    width: 100%;
    height: 100%;
    overflow:auto;
}
td.container2 > div {
    width: 110px;
    height: 100%;
    overflow:auto;
}
table {
    border-spacing: 0;
    width: 100%;
    border: 1px solid #ddd;
}
th {
    cursor: pointer;
}
th, td {
    text-align: left;
    padding: 5px;
}
td{
    height: 75px;
}
tr:nth-child(even) {
    background-color: #f2f2f2
}
</style>
<script>
function tableFilter(n) {
  var input, filter, table, tr, td, i;
  input = document.getElementById("fltr"+n);
  filter = input.value.toUpperCase();
  table = document.getElementById("table");
  tr = table.getElementsByTagName("tr");
  for (i = 0; i < tr.length; i++) {
    td = tr[i].getElementsByTagName("td")[n];
    if (td) {
      if (td.innerText.toUpperCase().indexOf(filter) > -1) {
        tr[i].style.display = "";
      } else {
        tr[i].style.display = "none";
      }
    }
  }
}
</script>
<script>
document.addEventListener('DOMContentLoaded', function() {
    const menu = document.getElementById('menu');
    const table = document.getElementById('table');
    const headers = [].slice.call(table.querySelectorAll('th'));
    const cells = [].slice.call(table.querySelectorAll('th, td'));
    const numColumns = headers.length;
    const tbody = table.querySelector('tbody');
    tbody.addEventListener('contextmenu', function(e) {
        e.preventDefault();
        const rect = tbody.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        menu.style.top = `${y}px`;
        menu.style.left = `${x}px`;
        menu.classList.toggle('hidden');
    });
    const showColumn = function(index) {
        cells
            .filter(function(cell) {
                return cell.getAttribute('data-column-index') === `${index}`;
            })
            .forEach(function(cell) {
                cell.style.display = '';
                cell.setAttribute('data-shown', 'true');
            });
        menu.querySelectorAll(`[type="checkbox"][disabled]`).forEach(function(checkbox) {
            checkbox.removeAttribute('disabled');
        });
    };
    const hideColumn = function(index) {
        cells
            .filter(function(cell) {
                return cell.getAttribute('data-column-index') === `${index}`;
            })
            .forEach(function(cell) {
                cell.style.display = 'none';
                cell.setAttribute('data-shown', 'false');
            });
        // How many columns are hidden
        const numHiddenCols = headers
            .filter(function(th) {
                return th.getAttribute('data-shown') === 'false';
            })
            .length;
        if (numHiddenCols === numColumns - 1) {
            // There's only one column which isn't hidden yet
            // We don't allow user to hide it
            const shownColumnIndex = tbody.querySelector('[data-shown="true"]').getAttribute('data-column-index');
            const checkbox = menu.querySelector(`[type="checkbox"][data-column-index="${shownColumnIndex}"]`);
            checkbox.setAttribute('disabled', 'true');
        }
    };
    cells.forEach(function(cell, index) {
        cell.setAttribute('data-column-index', index % numColumns);
        cell.setAttribute('data-shown', 'true');
    });
    headers.forEach(function(th, index) {
        // Build the menu item
        const label = document.createElement('label');
        const checkbox = document.createElement('input');
        checkbox.setAttribute('type', 'checkbox');
        checkbox.setAttribute('checked', 'true');
        checkbox.setAttribute('data-column-index', index);
        checkbox.style.marginRight = '.25rem';
        const text = document.createTextNode(th.textContent);
        label.appendChild(text);
		menu.appendChild(checkbox);
		menu.appendChild(label);
        // Handle the event
        checkbox.addEventListener('change', function(e) {
            e.target.checked ? showColumn(index) : hideColumn(index);
            menu.classList.add('hidden');
        });
    });
});
</script>
</head>
<body>
<p><strong>
thedateis
</strong></p>
<p><strong>Click the headers to sort the table. BE PATIENT. The table is huge. You may have to press the javascript wait button of your browser.</strong></p>
IP fltr:<input type="text" id="fltr0" onkeyup="tableFilter(0)" placeholder="Search for names..">
YES fltr:<input type="text" id="fltr1" onkeyup="tableFilter(1)" placeholder="Search for names..">
NO fltr:<input type="text" id="fltr2" onkeyup="tableFilter(2)" placeholder="Search for names..">
ABS fltr:<input type="text" id="fltr3" onkeyup="tableFilter(3)" placeholder="Search for names..">
<br>
<div id="menu" class="hidden"></div>
<br>
<table id="table" class="table"> 
<tbody>
<tr>
<th>IP</th>
<th>YES VOTES</th>
<th>NO VOTES</th>
<th>ABS VOTES</th>
<th>VOTEHASH</th>
</tr>
EOF

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

cat <<"EOF" >> $filenameis
</tbody>
</table>
<script>
const getCellValue = (tr, idx) => tr.children[idx].innerText || tr.children[idx].textContent;
const comparer = (idx, asc) => (a, b) => ((v1, v2) => v1 !== '' && v2 !== '' && !isNaN(v1) && !isNaN(v2) ? v1 - v2 : v1.toString().localeCompare(v2))(getCellValue(asc ? a : b, idx), getCellValue(asc ? b : a, idx));
document.querySelectorAll('th').forEach(th => th.addEventListener('click', (() => {const table = th.closest('table');Array.from(table.querySelectorAll('tr:nth-child(n+2)')).sort(comparer(Array.from(th.parentNode.children).indexOf(th), this.asc = !this.asc)).forEach(tr => table.appendChild(tr));})));
</script>
</body>
</html>  
EOF

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

#cut -f24 -d"<" the_results_dashd_*.html|cut -f2 -d">"|grep -v [a-z]|grep -v [A-Z]| grep ^[0-9]|grep -v "-"|sort|uniq -c|sed -e s/'^   '/000/g|sed -s s/'000   '/000000/g|sed -e s/'000  '/00000/g|sed -s s/'000 '/0000/g|sort -r|cut -f1 -d" "|uniq -c|sed -e s/" 0"/" operator(s) control(s) "/g|sed -e s/$/" masternode(s)"/g >> $distrfileis
#xkcd replacement of the above command
grep -o '[0-9]\{40,\}' the_results_dashd_*.html|sort|uniq -c|awk '{ while (/^[[:blank:]]/) {if (sub(/^ /,"")) printf "0";}print;}'|sort -r|cut -f1 -d" "|uniq -c|sed 's/\( *[0-9]* \)000\(.*\)/\1operator(s) control(s) \2 masternode(s)/g' >> $distrfileis
#end of xkcd code

cp current_props ../httpd/current_props_"$dateis".txt
cp upload_*.tar.gz ../httpd
cp distr_*.txt ../httpd
cp the_results_dashd_*.html ../httpd

wheredoIedit=`grep -n "Everything below this line is updated by MNOWatch.sh, do not modify!" ../httpd/index.html |cut -f1 -d:`
ADDTHIS="<br><a href=\""`ls ./distr_*.txt`"\"> the distribution $dateis </a> and <a href=\""`ls ./the_results*.html`"\"> the results $dateis </a> (<a href=\""`ls ./the_results*.html.csv`"\">csv</a>)" 
sed -i `expr $wheredoIedit + 1`'i'"$ADDTHIS" ../httpd/index.html

if [ $SIMILARNUM -gt 0 ]
then
$BIN_DIR/ssdeepit.sh `ls -tra $HTTPD_DIR/*html.csv|tail -1` $SIMILARNUM
cp the_results_dashd_*.similar.*.csv ../httpd
cp the_results_dashd_*.similar.*.html ../httpd
ADDTHIS=" and <a href=\""`ls ./the_results*.similar.*.csv`"\">the similarities.csv</a> (<a href=\""`ls ./the_results*.similar.*.html`"\">html</a>)" 
else
$BIN_DIR/ssdeepit.sh `ls -tra $HTTPD_DIR/*html.csv|tail -1`
ADDTHIS=" and didn't calculate similarites" 
fi
sed -i `expr $wheredoIedit + 2`'i'"$ADDTHIS" ../httpd/index.html

cp the_results_dashd_*.uniqueHashVotes.*.csv ../httpd
cp the_results_dashd_*.uniqueHashVotes.*.html ../httpd
ADDTHIS=" and <a href=\""`ls ./the_results*.uniqueHashVotes.*.csv`"\"> the uniqueVotesHashes.csv</a>"
sed -i `expr $wheredoIedit + 3`'i'"$ADDTHIS" ../httpd/index.html
#ADDTHIS=" (<a href=\""`ls ./the_results*.uniqueHashVotes.*.html`"\">html</a>)"
ADDTHIS="(<span style=\"background: #00ee00\"><a href=\""`ls ./the_results*.uniqueHashVotes.*.html`"\">html</a></span>)"
sed -i `expr $wheredoIedit + 4`'i'"$ADDTHIS" ../httpd/index.html
rm -rf *_* upload proposals

#here I change the working  directory to httpd 
cd $HTTPD_DIR

diffis=`ls -ltra|grep unique|tail -1|cut -f4 -d"_"|cut -f1 -d"."`.diff
filestodiff=`ls -lrta |grep unique|grep -v html |tail -2|cut -f2 -d":"|cut -f2 -d" "|wc -l`
if [ $filestodiff -eq 2 ]
then
#git diff --color-words --word-diff=plain --unified=0 `ls -lrta |grep unique|grep -v html |tail -2|cut -f2 -d":"|cut -f2 -d" "`|sed -e s/"IPS,YES_VOTES,NO_VOTES,ABSTAIN_VOTES,VOTES_HASH,HASH_OF_THE_SORTED_IPS,NUMBER_OF"/"------------------------------"/g > $diffis
#TO DO: debug git diff --color-words. It seems to put some IPs in the same line while we expect to be in separete lines.
file1todiff=`ls -lrta |grep unique|grep -v html |tail -2|cut -f2 -d":"|cut -f2 -d" "|head -1`
file2todiff=`ls -lrta |grep unique|grep -v html |tail -1|cut -f2 -d":"|cut -f2 -d" "`
cat $file1todiff |cut -f1-11 -d, > $TMP_DIR/$file1todiff
cat $file2todiff |cut -f1-11 -d, > $TMP_DIR/$file2todiff

cd $TMP_DIR
#git diff --color-words --word-diff=plain --unified=0 `ls -lrta |grep unique|grep -v html |tail -2|cut -f2 -d":"|cut -f2 -d" "` > $diffis
#diff <(cat file1todiff|cut -f1-2 -d,) <(cat file2todiff|cut -f1-2 -d,)
#WARNING. Diff should not take into account the last collumn of history
git diff --color-words --word-diff=plain --unified=0 $file1todiff $file2todiff > $HTTPD_DIR/$diffis
cd $HTTPD_DIR
rm -f $TMP_DIR/$file1todiff
rm -f $TMP_DIR/$file2todiff

else
echo "" > $diffis
fi
ADDTHIS=" and <a href=\"./"$diffis"\">the git diff</a>"
sed -i `expr $wheredoIedit + 5`'i'"$ADDTHIS" ./index.html
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
sed -i `expr $wheredoIedit + 6`'i'"$ADDTHIS" ./index.html

if [ $superblock -gt 0 ]
then
ADDTHIS="-<strong>EndOfVote</strong>"
sed -i `expr $wheredoIedit + 7`'i'"$ADDTHIS" ./index.html
fi

reg2='^leaderboard '
if [[ $MYCOMMENT =~ $reg2 ]] 
then
ADDTHIS="-<strong><a href=\"./leaderboard/analysis/?"`echo $MYCOMMENT|cut -f2 -d" "`"\">Leaderboard</a></strong>"
sed -i `expr $wheredoIedit + 7`'i'"$ADDTHIS" ./index.html
fi

#echo "END! "
$MYHOME_DIR/warnings/warnings.sh $dateis



#!/bin/bash

# Licence: GPLv2
# The author of the software is the owner of the Dash Address: XnpT2YQaYpyh7F9twM6EtDMn1TCDCEEgNX
#
# MNOWATCH VERSION: 0.13

wcone=`echo $1|wc -c`
wctwo=`echo $2|wc -c`
if [ $wcone -eq 1 ] 
then
 echo "usage: ssdeepit.sh /mnowatch_path/httpd/csvfile [similarity_number]"
 exit
fi
if [ $wctwo -eq 1 ] 
then
 SEARCHSIMILARITIES=0
 secondarg=0
else 
 SEARCHSIMILARITIES=1
 secondarg=$2
fi

MYDIR=`dirname $1`
cd $MYDIR
cd ..
MYHOME_DIR=`pwd`
WORKING_DIR=$MYHOME_DIR"/tmp"
BIN_DIR=$MYHOME_DIR"/bin"
HTTPD_DIR=$MYHOME_DIR"/httpd"

cd $WORKING_DIR
sort -t"," -k5 $1 > mysorted.csv
#a bug occurs to all proposals than contain a , in their proposal-name
#ex. proposal-name = VENEZUELAN-ALLIED-DASH-COMMUNITIES,Cash_Evolution_Bloomberg_Radio
#sort -u -t"," -k5 $1|cut -f3- -d","|sed -e s/' '/':'/g > mysortedUnique.csv
#fix it in order to support mycollat and iscrowdnode
cut -f1-6 -d"," $1|sort -u -t"," -k5|cut -f3- -d","|sed -e s/' '/':'/g > mysortedUnique.csv

numuniques=`cat mysortedUnique.csv|wc -l`

filenameunhtml=`echo $1|cut -f1 -d"."`.uniqueHashVotes.$numuniques.html
thisuniqueHashreport=`basename $filenameunhtml`

filenameun=`echo $1|cut -f1 -d"."`.uniqueHashVotes.$numuniques.csv
filenameun=$WORKING_DIR/`basename $filenameun`
cp mysortedUnique.csv $filenameun

cat $filenameun|grep -v "^,,," > pastedonefile 
cat /dev/null > pastedtwofile
dateis=`echo $1|cut -f4 -d"_"|cut -f1 -d"."`
cat $BIN_DIR/jsssdeep.html|sed -e s/"MNOWATCH from dashd thedateis<\/title>"/"MNOwatch - VoteHashGroups $dateis <\/title><link rel=\"icon\" type=\"image\/png\" href=\"favicon.ico\">"/g|sed -e s/"thedateis"/"$dateis"/g >  mysortedUnique.html
PREVIUSREPORT=`cd $HTTPD_DIR;ls -tra *uniqueHashVotes*.html 2>/dev/null|tail -1`
PREVIUSREPORTFULL=$HTTPD_DIR"/"$PREVIUSREPORT

for fn in `cat pastedonefile`; do 
 yes=" "`echo $fn |cut -f1 -d","|sed -e s/":"/" "/g`" "
 no=" "`echo $fn |cut -f2 -d","|sed -e s/":"/" "/g`" "
 abs=" "`echo $fn |cut -f3 -d","|sed -e s/":"/" "/g`" "
 voteshash=" "`echo $fn |cut -f4 -d","`" "
 IPS=" "`grep $voteshash mysorted.csv|cut -f1 -d","|sort`" "
#Note: theIPSgrouphash contains " " in front and in the end, as inherited by $IPS
 IPS=`echo $IPS` # bug fix due to change of bash version that trims spaces differently
 theIPSgrouphash=`bc <<<ibase=16\;$(sha1sum <<<$IPS|tr a-z A-Z)0`
 #WARNING the IPS are sorted so they do not match the order of MNS or Collats
 #TO DO: Make MNS and collats match the order of IPs
 theMNS=" "`grep $voteshash mysorted.csv|cut -f2 -d","`" "
 theMNSnum=" "`grep $voteshash mysorted.csv|cut -f2 -d","|wc -l`" "
 theMNSnum=`printf %04d $theMNSnum`
 theCollats=" "`grep $voteshash mysorted.csv|cut -f7 -d","`" "
 theCollats2=" "`grep $voteshash mysorted.csv|awk -F, '{ print "\""$7"\""}'`" "
 the1stTx=" "`grep $voteshash mysorted.csv|cut -f9 -d","|sort|head -1|sed -e s/"-"/"."/g`" "
 theCrowds=" "`grep $voteshash mysorted.csv|cut -f8 -d","`" "

 echo $IPS","$yes","$no","$abs","$voteshash", \""$theIPSgrouphash"\" ,"$theMNSnum","$theMNS","$theCollats","$the1stTx","$theCrowds >> pastedtwofile

 exists=`grep $theIPSgrouphash $PREVIUSREPORTFULL 2>/dev/null|wc -l`
 theHistory=`grep -l $theIPSgrouphash $HTTPD_DIR/*uniqueHashVotes*.html 2>/dev/null|wc -l`
 theHistory=`printf %04d $theHistory`

 OLDESTREPORT=`cd $HTTPD_DIR;ls -tra *uniqueHashVotes*.html 2>/dev/null|xargs grep -l $theIPSgrouphash`
 OLDESTREPORT=`echo $OLDESTREPORT|cut -f1 -d" "`
 theHistory="<a href=\"./"$OLDESTREPORT"#"$theIPSgrouphash"\" title=\"Go to the oldest report where this group of IPs initially appeared.\">"$theHistory"</a>"

 numips=`echo $IPS|awk -F'" "' 'NF{print NF-1}'`
 numips=`expr $numips + 1`
 builtIPS=`echo " "$IPS|sed -e s/'"'/'@'/g|sed -e s/' @'/'<a target="_blank" href="https:\/\/ipinfo.io\/'/g|sed -e s/@/'">@<\/a> '/g`

 for (( c=1; c<=$numips; c++ ))
 do
  cutf=`expr $c \* 2`
  content="`echo $IPS|cut -f"$cutf" -d'\"'`"
  builtIPS=`echo $builtIPS|sed "s/@/${content}/"`
 done

 numcoll=`echo $theCollats2|awk -F'" "' 'NF{print NF-1}'`
 numcoll=`expr $numcoll + 1`
 #<a target=\"_blank\" href=https://bitinfocharts.com/dash/address/"$theCollats">"$theCollats"</a>
 #builtcoll=`echo " "$theCollats2|sed -e s/' @'/'<a target="_blank" href="https:\/\/ipinfo.io\/'/g|sed -e s/@/'">@<\/a> '/g`
 builtcoll=`echo " "$theCollats2|sed -e s/'"'/'@'/g|sed -e s/' @'/'<a target="_blank" href="https:\/\/bitinfocharts.com\/dash\/address\/'/g|sed -e s/@/'">@<\/a> '/g`

 for (( d=1; d<=$numcoll; d++ ))
 do
  cutf2=`expr $d \* 2`
  content2="`echo $theCollats2|cut -f"$cutf2" -d'\"'`"
  builtcoll=`echo $builtcoll|sed "s/@/${content2}/"`
 done

#TO DO: make every proposal link to dashwatch https://dashwatchbeta.org/api/p/proposal_name
#TO DO: rate every voter according to the quality of the proposala (as calculated by dashwatch) he historicaly voted.

#TO DO: make every MNO link to dashninja.pl https://www.dashninja.pl/mndetails.html?mnoutput=
#TO DO: show the dash address of every masternode, and link it to an OP_RETURN service so that people can send him messages.

 voteshashexist=`grep $voteshash $PREVIUSREPORTFULL|wc -l`
 if [ $exists -eq 0 ]
 then
  if [ $voteshashexist -eq 0 ]
  then
   voteshash3=$voteshash
  else
   previusreportofvoteshash=`grep $voteshash $PREVIUSREPORTFULL|cut -f2 -d"\""`
   voteshash3="<a href=\"./"$PREVIUSREPORT"#"$previusreportofvoteshash"\"  title=\"Go to the previous report and see the group that has identical VOTES_HASH.\" >"$voteshash"</a>"
  fi
 #<a target=\"_blank\" href=https://bitinfocharts.com/dash/address/"$theCollats">"$theCollats"</a> 
  echo "<tr id=\""$theIPSgrouphash"\" ><td class=\"container1\"><div>"$theMNSnum"</div></td><td class=\"container2\"><div>(History="$theHistory") <strong>"$theIPSgrouphash"</strong></div></td><td class=\"container3\"><div>"$builtIPS"</div></td><td class=\"container4\"><div>"$yes"</div></td><td class=\"container5\"><div>"$no"</div></td><td class=\"container6\"><div>"$abs"</div></td><td class=\"container7\"><div>"$voteshash3"</div></td><td class=\"container8\"><div>"$theMNS"</div></td><td class=\"container9\"><div>"$builtcoll"</div></td><td class=\"container10\"><div>"$the1stTx"</div></td><td class=\"container11\"><div>"$theCrowds"</div></td></tr>" >> pasted.html
 else
  voteshash2=$voteshash
  if [ $voteshashexist -eq 0 ]
  then
   voteshash2="<strong>"$voteshash"</strong> (copy the votehash, then search for it in the <a target=\"_blank\" href=\"./"$dateis".diff.html#"`echo $voteshash|cut -f2 -d"\""`"\">diff</a> file)"
  fi
  #BUG is there a bug in lastdiffdate? No . The reports changed to the diff in the collateral collumn. So I need to check the votes specifically in order for this not to happen again
  lastdiffdate=`cd $HTTPD_DIR;grep -l $theIPSgrouphash *.diff|grep -v "\-2019.diff"|tail -1|cut -f1 -d"."`
#Note the grep -v "\-2019.diff" usage is for excluding the non stantard date diff files. Maybe do the same for the xargs above, for performance reasons
  lastdiffdatereport=`cd $HTTPD_DIR;ls *$lastdiffdate".uniqueHashVotes."*".html"`
  echo "<tr id=\""$theIPSgrouphash"\" ><td class=\"container1\"><div>"$theMNSnum"</div></td> <td class=\"container2\"><div>(History="$theHistory") <a href=\"./"$lastdiffdatereport"#"$theIPSgrouphash" \" title=\"Go to the report where this group changed votes. Then check the diff that is linked from the VOTES_HASH column.\">"$theIPSgrouphash"</a></div></td><td class=\"container3\"><div>"$builtIPS"</div></td><td class=\"container4\"><div>"$yes"</div></td><td class=\"container5\"><div>"$no"</div></td><td class=\"container6\"><div>"$abs"</div></td><td class=\"container7\"><div>"$voteshash2"</div></td><td class=\"container8\"><div>"$theMNS"</div></td><td class=\"container9\"><div>"$builtcoll"</div></td><td class=\"container10\"><div>"$the1stTx"</div></td><td class=\"container11\"><div>"$theCrowds"</div></td></tr>" >> pasted.html
#  echo "<tr id=\""$theIPSgrouphash"\" ><td class=\"container1\"><div>"$theMNSnum"</div></td> <td class=\"container2\"><div>(History="$theHistory") <a href=\"./"$PREVIUSREPORT"#"$theIPSgrouphash"\">"$theIPSgrouphash"</a></div></td><td class=\"container3\"><div>"$builtIPS"</div></td><td class=\"container4\"><div>"$yes"</div></td><td class=\"container5\"><div>"$no"</div></td><td class=\"container6\"><div>"$abs"</div></td><td class=\"container7\"><div>"$voteshash2"</div></td><td class=\"container8\"><div>"$theMNS"</div></td></tr>" >> pasted.html
 fi
done

echo "IPS,YES_VOTES,NO_VOTES,ABSTAIN_VOTES,VOTES_HASH,HASH_OF_THE_SORTED_IPS,NUMBER_OF_MASTERNODES,MASTERNODES,COLLATERALS,FIRSTTRANS,CROWDTYPES" > $filenameun
sort -t, -k7,7 -nr pastedtwofile >> $filenameun
rm pastedonefile
rm pastedtwofile

sort -t">" -k4,4 -nr pasted.html >> mysortedUnique.html 
echo "
</tbody>
</table>
</body>
</html>
" >> mysortedUnique.html

filenameunhtml=`echo $1|cut -f1 -d"."`.uniqueHashVotes.$numuniques.html
filenameunhtml=$WORKING_DIR/`basename $filenameunhtml`
cp mysortedUnique.html $filenameunhtml

#START VOTING SIMILARITIES SEARCH
if [ $SEARCHSIMILARITIES -gt 0 ]
then
#echo "PLEASE WAIT. SEARCHING FOR SIMILARITY>"$secondarg" among "$numuniques" unique voteshashes"
 filenameis=`echo $1|cut -f1 -d"."`.similar.$secondarg.$numuniques.csv
 filenameis=$WORKING_DIR/`basename $filenameis`
 filenameishtml=`echo $1|cut -f1 -d"."`.similar.$secondarg.$numuniques.html
 filenameishtml=$WORKING_DIR/`basename $filenameishtml`
 cat /dev/null > $filenameis
 cat /dev/null > $filenameishtml
 cat /dev/null > used.txt

 cat mysortedUnique.csv > mysortedUnique_gn.csv

 for fn in `cat mysortedUnique.csv`; do
  echo $fn|cut -f1-3 -d"," > this
#maybe I should use the recursive mode ssdeep -r , for performance reasons
  ssdeep -s this > this.db
  found=0
  IPS=0
  voteshashisfn=`echo $fn|cut -f4 -d","`
  isitusedfn=`grep $voteshashisfn used.txt |wc -l`
  ALLIPS=""
  ALLIPSgrouped=""

  grep -v $fn mysortedUnique_gn.csv > mysortedUnique_gntwo.csv

  if [ $isitusedfn -eq 0 ] 
  then
   for gn in `cat mysortedUnique_gntwo.csv`; do
    isit=`echo $gn|cut -f1-3 -d"," | ssdeep -m this.db`
    isitwc=`echo $isit|wc -c`
    voteshashis=`echo $gn|cut -f4 -d","`
    isitused=`grep $voteshashis used.txt |wc -l`
    if [ $isitused -eq 0 ] 
    then
     if [ $isitwc -gt 1 ] 
     then
      cutit=`echo $isit|cut -f2 -d"("|cut -f1 -d")"`
      if [ $cutit -ne 100 ]
      then
       if [ $cutit -gt $secondarg ]
        then
         ALLIPSofthisgroup=`grep $voteshashis $1|cut -f1 -d","|sort`
         ALLIPSofthisgroup2=" "`grep $voteshashis $1|cut -f1 -d","|sort`" "
         #Note: theIPSgrouphashsimilar contains " " in front and in the end due to compatibility to uniquehashes
         ALLIPSofthisgroup2=`echo $ALLIPSofthisgroup2` # bug fix due to change of bash version that trims spaces differently
         theIPSgrouphashsimilar=`bc <<<ibase=16\;$(sha1sum <<<$ALLIPSofthisgroup2|tr a-z A-Z)0`
         ALLIPS=$ALLIPS" "$ALLIPSofthisgroup
         ALLIPSgrouped=$ALLIPSgrouped"("$cutit":"$voteshashis":"$ALLIPSofthisgroup":\"<a href=\"./"$thisuniqueHashreport"#"$theIPSgrouphashsimilar"\" title=\"How this group voted.\" >"$theIPSgrouphashsimilar"</a>\")"
         echo $voteshashis >> used.txt
         found=`expr $found + 1`
         IPSnum=`grep $voteshashis $1|cut -f1 -d","|wc -l`	
         IPS=`expr $IPS + $IPSnum`
       fi
      fi
     fi
    fi
   done
  fi

  cat mysortedUnique_gntwo.csv > mysortedUnique_gn.csv

  if [ $found -gt 0 ]
  then
   ALLIPSofthisgroupfn=`grep $voteshashisfn $1|cut -f1 -d","|sort`
   ALLIPSofthisgroupfn2=" "`grep $voteshashisfn $1|cut -f1 -d","|sort`" "
#Note: theIPSgrouphashsimilarfn contains " " in front and in the end due to compatibility to uniquehashes
   ALLIPSofthisgroupfn2=`echo $ALLIPSofthisgroupfn2` # bug fix due to change of bash version that trims spaces differently
   theIPSgrouphashsimilarfn=`bc <<<ibase=16\;$(sha1sum <<<$ALLIPSofthisgroupfn2|tr a-z A-Z)0`
   ALLIPS=$ALLIPS" "$ALLIPSofthisgroupfn
   ALLIPSgrouped=$ALLIPSgrouped"(100:"$voteshashisfn":"$ALLIPSofthisgroupfn":\"<a href=\"./"$thisuniqueHashreport"#"$theIPSgrouphashsimilarfn"\" title=\"How this group voted.\" >"$theIPSgrouphashsimilarfn"</a>\")"
   IPSnum=`grep $voteshashisfn $1|cut -f1 -d","|wc -l`	

   IPS=`expr $IPS + $IPSnum`
   ALLIPSsorted=`echo $ALLIPS|sed -s s/" "/\\\\n/g|sort -n`
#Note: ALLIPShashis DOES NOT contains " " in front and in the end
   ALLIPSsorted=`echo $ALLIPSsorted` # bug fix due to change of bash version that trims spaces differently
   ALLIPShashis=`bc <<<ibase=16\;$(sha1sum <<<$ALLIPSsorted|tr a-z A-Z)0`

   echo $IPS",\""$ALLIPShashis"\","$ALLIPSsorted","$ALLIPSgrouped >> $filenameis

   PREVIUSREPORTSIMILAR=`cd $HTTPD_DIR;ls -tra *similar*.html 2>/dev/null|tail -1`
   PREVIUSREPORTSIMILARFULL=$HTTPD_DIR"/"$PREVIUSREPORTSIMILAR
   existsfn=`grep $ALLIPShashis $PREVIUSREPORTSIMILARFULL 2>/dev/null|wc -l`
   theHistoryfn=`grep -l $ALLIPShashis $HTTPD_DIR/*similar*.html 2>/dev/null|wc -l`
   theHistoryfn=`printf %04d $theHistoryfn`

   OLDESTREPORTSIMILAR=`cd $HTTPD_DIR;ls -tra *similar*.html 2>/dev/null|grep -v ".init.html"|xargs grep -l $ALLIPShashis`
   OLDESTREPORTSIMILAR=`echo $OLDESTREPORTSIMILAR|cut -f1 -d" "`
   theHistoryfn="<a href=\"./"$OLDESTREPORTSIMILAR"#"$ALLIPShashis"\" title=\"Go to the report where this similarity initially occured.\" >"$theHistoryfn"</a>"

   if [ $existsfn -eq 0 ]
   then
    echo "<tr id=\""$ALLIPShashis"\"><td><div>"$IPS"</div></td><td><div>(History="$theHistoryfn") <strong>"$ALLIPShashis"</strong></div></td><td><div>"$ALLIPSsorted"</div></td><td><div>"$ALLIPSgrouped"</div></td></tr>" >> $filenameishtml
   else
    echo "<tr id=\""$ALLIPShashis"\"><td><div>"$IPS"</div></td><td><div>(History="$theHistoryfn") <a href=\"./"$PREVIUSREPORTSIMILAR"#"$ALLIPShashis"\" title=\"Go to the previus report and land in this similarity.\">"$ALLIPShashis"</a></div></td><td><div>"$ALLIPSsorted"</div></td><td><div>"$ALLIPSgrouped"</div></td></tr>" >> $filenameishtml
   fi

   echo $voteshashisfn >> used.txt
  fi
 done

 rm this
 rm this.db

#TO DO: CALCULATE ALSO THE IP similarities. This will apply mostly to the whale whose IP set  differ +- 1 or 2 masternodes.
#TO DO: So in case we have the same votes set and the IPs are similar, it is probable the same individual

 tmpsortin=$WORKING_DIR/tmpsort
 sort -nr $filenameis > $tmpsortin
 ADDTHIS="NUMBER_OF_IPS,HASH_OF_IPS,ALL_IPS,HOW_THE_IPS_ARE_GROUPED"
 sed -i '1i'"$ADDTHIS" $tmpsortin
 cp -f $tmpsortin $filenameis

 sort -t">" -k4,4 -nr $filenameishtml > $tmpsortin
 echo "<html><head><title>MNOwatch - Similarities $dateis</title><link rel=\"icon\" type=\"image/png\" href=\"favicon.ico\"></head><body><style> table { font-family: arial, sans-serif; border-collapse: collapse; width: 100%; } td, th { border: 1px solid #dddddd; text-align: left; padding: 8px; } tr:nth-child(even) { background-color: #dddddd; } </style><table><thead><tr><th>NUMBER_OF_IPS</th><th>HASH_OF_IPS</th><th>ALL_IPS</th><th>HOW_IPS_ARE_GROUPED</th></tr></thead><tbody>" > $filenameishtml
 cat $tmpsortin >> $filenameishtml
 echo "</tbody></table></body></html>" >> $filenameishtml

 rm tmpsort
 rm mysortedUnique_gntwo.csv 
 rm mysortedUnique_gn.csv
 rm used.txt

fi
#END VOTING SIMILARITIES SEARCH

rm mysortedUnique.csv
rm mysorted.csv
rm pasted.html
rm mysortedUnique.html

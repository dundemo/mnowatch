# Licence: GPLv2

# 1) SET MYHOME_DIR
MYHOME_DIR="/home/demo"

WORKING_DIR=$MYHOME_DIR"/tmp"
BIN_DIR=$MYHOME_DIR"/bin"
HTTPD_DIR=$MYHOME_DIR"/httpd"

wcone=`echo $1|wc -c`
wctwo=`echo $2|wc -c`
if [ $wcone -eq 1 ] 
then
echo "usage: ssdeepit.sh /full/path/csvfile [similarity_number]"
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

cd $WORKING_DIR
sort -t"," -k5 $1 > mysorted.csv
#a bug occurs to all proposals than contain a , in their proposal-name
#ex. proposal-name = VENEZUELAN-ALLIED-DASH-COMMUNITIES,Cash_Evolution_Bloomberg_Radio
sort -u -t"," -k5 $1|cut -f3- -d","|sed -e s/' '/':'/g > mysortedUnique.csv
numuniques=`cat mysortedUnique.csv|wc -l`

filenameun=`echo $1|cut -f1 -d"."`.uniqueHashVotes.$numuniques.csv
filenameun=$WORKING_DIR/`basename $filenameun`
cp mysortedUnique.csv $filenameun

cat $filenameun|grep -v "^,,," > pastedonefile 
cat /dev/null > pastedtwofile
dateis=`echo $1|cut -f4 -d"_"|cut -f1 -d"."`
cat $BIN_DIR/jsssdeep.html|sed -e s/"thedateis"/"$dateis"/g >  mysortedUnique.html
PREVIUSREPORT=`cd $HTTPD_DIR;ls -tra *uniqueHashVotes*.html|tail -1`
PREVIUSREPORTFULL=$HTTPD_DIR"/"$PREVIUSREPORT

for fn in `cat pastedonefile`; do 
yes=" "`echo $fn |cut -f1 -d","|sed -e s/":"/" "/g`" "
no=" "`echo $fn |cut -f2 -d","|sed -e s/":"/" "/g`" "
abs=" "`echo $fn |cut -f3 -d","|sed -e s/":"/" "/g`" "
voteshash=" "`echo $fn |cut -f4 -d","`" "
IPS=" "`grep $voteshash mysorted.csv|cut -f1 -d","|sort`" "
theIPSgrouphash=`bc <<<ibase=16\;$(sha1sum <<<$IPS|tr a-z A-Z)0`
theMNS=" "`grep $voteshash mysorted.csv|cut -f2 -d","`" "
theMNSnum=" "`grep $voteshash mysorted.csv|cut -f2 -d","|wc -l`" "

echo $IPS","$yes","$no","$abs","$voteshash", \""$theIPSgrouphash"\" ,"$theMNSnum","$theMNS >> pastedtwofile


exists=`grep $theIPSgrouphash $PREVIUSREPORTFULL|wc -l`
theHistory=`grep -l $theIPSgrouphash $HTTPD_DIR/*uniqueHashVotes*.html|wc -l`
theHistory=`printf %04d $theHistory`

numips=`echo $IPS|awk -F'" "' 'NF{print NF-1}'`
numips=`expr $numips + 1`
builtIPS=`echo " "$IPS|sed -e s/'"'/'@'/g|sed -e s/' @'/'<a target="_blank" href="https:\/\/ipinfo.io\/'/g|sed -e s/@/'">@<\/a> '/g`

for (( c=1; c<=$numips; c++ ))
do
cutf=`expr $c \* 2`
content="`echo $IPS|cut -f"$cutf" -d'\"'`"
builtIPS=`echo $builtIPS|sed "s/@/${content}/"`
done


if [ $exists -eq 0 ]
then
echo "<tr id=\""$theIPSgrouphash"\" ><td class=\"container1\"><div>"$theMNSnum"</div></td><td class=\"container2\"><div>(History="$theHistory") <strong>"$theIPSgrouphash"</strong></div></td><td class=\"container3\"><div>"$builtIPS"</div></td><td class=\"container4\"><div>"$yes"</div></td><td class=\"container5\"><div>"$no"</div></td><td class=\"container6\"><div>"$abs"</div></td><td class=\"container7\"><div>"$voteshash"</div></td><td class=\"container8\"><div>"$theMNS"</div></td></tr>" >> pasted.html
else
echo "<tr id=\""$theIPSgrouphash"\" ><td class=\"container1\"><div>"$theMNSnum"</div></td> <td class=\"container2\"><div>(History="$theHistory") <a href=\"./"$PREVIUSREPORT"#"$theIPSgrouphash"\">"$theIPSgrouphash"</a></div></td><td class=\"container3\"><div>"$builtIPS"</div></td><td class=\"container4\"><div>"$yes"</div></td><td class=\"container5\"><div>"$no"</div></td><td class=\"container6\"><div>"$abs"</div></td><td class=\"container7\"><div>"$voteshash"</div></td><td class=\"container8\"><div>"$theMNS"</div></td></tr>" >> pasted.html
fi



done
echo "IPS,YES_VOTES,NO_VOTES,ABSTAIN_VOTES,VOTES_HASH,HASH_OF_THE_SORTED_IPS,NUMBER_OF_MASTERNODES,MASTERNODES" > $filenameun
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

#echo "PLEASE WAIT. SEARCHING FOR SIMILARITY>"$secondarg" among "$numuniques" unique voteshashes"
filenameis=`echo $1|cut -f1 -d"."`.similar.$secondarg.$numuniques.csv
filenameis=$WORKING_DIR/`basename $filenameis`
cat /dev/null > $filenameis
cat /dev/null > used.txt

#START SIMILARITIES SEARCH
if [ $SEARCHSIMILARITIES -gt 0 ]
then

for fn in `cat  mysortedUnique.csv`; do
echo $fn|cut -f1-3 -d"," > this
#maybe I should use the recursive mode ssdeep -r , for performance reasons
ssdeep -s this > this.db
found=0
IPS=0
voteshashisfn=`echo $fn|cut -f4 -d","`
isitusedfn=`grep $voteshashisfn used.txt |wc -l`
ALLIPS=""
ALLIPSgrouped=""
if [ $isitusedfn -eq 0 ] 
 then
 for gn in `cat  mysortedUnique.csv`; do
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
       ALLIPSofthisgroup=`grep $voteshashis $1|cut -f1 -d","`
       #echo "Similarity="$cutit" voteshash="$voteshashis" IPs="$ALLIPSofthisgroup
       ALLIPS=$ALLIPS" "$ALLIPSofthisgroup
       ALLIPSgrouped=$ALLIPSgrouped"("$cutit":"$voteshashis":"$ALLIPSofthisgroup")"
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
if [ $found -gt 0 ]
then
 ALLIPSofthisgroupfn=`grep $voteshashisfn $1|cut -f1 -d","`
 #echo "The above "$found" voteshash(es) is(are) similar to the "$voteshashisfn" IPs="$ALLIPSofthisgroupfn
 ALLIPS=$ALLIPS" "$ALLIPSofthisgroupfn
 ALLIPSgrouped=$ALLIPSgrouped"(100:"$voteshashisfn":"$ALLIPSofthisgroupfn")"
 IPSnum=`grep $voteshashisfn $1|cut -f1 -d","|wc -l`	
 IPS=`expr $IPS + $IPSnum`
 ALLIPSsorted=`echo $ALLIPS|sed -s s/" "/\\\\n/g|sort -n`
 ALLIPShashis=`bc <<<ibase=16\;$(sha1sum <<<$ALLIPSsorted|tr a-z A-Z)0`
 #echo "GROUP's hash="$ALLIPShashis 
 #echo "ALL IPs sorted="`echo $ALLIPSsorted`
 #echo "TOTAL MASTERNODES OF THE GROUP="$IPS
 #echo "ALL IPs of the group="$ALLIPSgrouped
 echo $IPS",\""$ALLIPShashis"\","$ALLIPSsorted","$ALLIPSgrouped >> $filenameis
 echo $voteshashisfn >> used.txt
fi
done

rm this
rm this.db

fi
#END SIMILARITIES SEARCH

tmpsortin=$WORKING_DIR/tmpsort
sort -nr $filenameis > $tmpsortin
ADDTHIS="NUMBER_OF_IPS,HASH_OF_IPS,ALL_IPS,HOW_THE_IPS_ARE_GROUPED"
sed -i '1i'"$ADDTHIS" $tmpsortin
cp -f $tmpsortin $filenameis
rm tmpsort
rm mysortedUnique.csv
rm mysorted.csv
rm used.txt
rm pasted.html
rm mysortedUnique.html

str_insert="#moonlight# $USER `date +%Y-%m-%d,%H:%M:%S`"
for ofile in $1/*.txt
do
	if [ `grep -c "#moonlight#" $ofile` -eq 0 ];then
		echo $str_insert >> $ofile
	else
		sed -i "/#moonlight#/c $str_insert" $ofile
	fi
done
cd $1
cat *.txt


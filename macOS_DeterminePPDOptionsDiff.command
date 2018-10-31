#!/bin/bash
[ -f /tmp/debug ] && set -x
#ppd option maker

#help
if [ "$1" == "-h" ]; then
echo "$(basename $0) compares two ppds and outputs the differences as a string for use in lpadmin"
echo "Usage: $(basename $0) [original_ppd] [new_ppd]"
exit
fi

#check for parameter if not ask
if [ -z "$1" -o -z "$2" ]; then
	clear;
	echo "Drag in the unmodified PPD from /Library/Printers/PPDs/Contents/Resources:"
	open /Library/Printers/PPDs/Contents/Resources
	while [ -z "$originalfile" ]; do
	read originalfile
	done

	echo "Drag in the PPD from /etc/cups/ppd:"
	open /etc/cups/ppd
	while [ -z "$newfile" ]; do
	read newfile
	done
#else just take the arguments
elif [ -n "$1" -o -n "$2" ]; then
	newfile="$2"
	originalfile="$1"
fi

#make a temp file of the original to compare
#strip off path and extension for temp file name
tempOriginalFile="/tmp/$(basename "$originalfile" .gz)"

#if file is compressed expand
if [ "${originalfile##*.}" == "gz" ]; then
	#uncompress
	IFS=$'\n\t'
	#gunzip to temp file
	gunzip < "$originalfile" > "$tempOriginalFile"
else
#just make a copy
cp "$originalfile" "$tempOriginalFile"
fi

#change line endings from CR to LF (diff fails unless this is done)
sed -e $'s/\\\r/\\\n/g' -i '' "$tempOriginalFile"

#make a temp file of the new file to compare
#strip off path
tempNewFile="/tmp/$(basename "$newfile")"
cp "$newfile" "$tempNewFile"

#change line endings from CR to LF (diff fails unless this is done)
sed -e $'s/\\\r/\\\n/g' -i '' "$tempNewFile"

#test for file existence
if [ ! -f "$tempOriginalFile" ]; then echo "$tempOriginalFile is not a valid path"; exit; fi 
if [ ! -f "$tempNewFile" ]; then echo "$tempNewFile is not a valid path"; exit; fi 

#create options list by diffing and filtering
optionList=$(diff "$tempOriginalFile" "$tempNewFile" | grep "> [*]Default" | sed 's/> [*]Default/-o /g' | sed 's/: /=/g')

#print out the options with no line breaks
IFS=$'\n\t'
if [ ! -z "$optionList" ]; then
	for option in $optionList; do 
		echo -n "$option "
	done
	echo
else
	echo No differences
fi

#delete the temp filess
rm "$tempOriginalFile" "$tempNewFile"

exit
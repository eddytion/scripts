#!/bin/ksh93

#
# Copyright (C) 1996, 1999 International Business Machines Corporation and others. All Rights Reserved. 
# IBM Public License Version 1.0
# Read in LICENSE.txt
#
# Authors: Joel Ruiz, Viachaslau Rakhmanko
# Version: 0.7.3
#

# enable/disable debug mode
#set -x

VERSION="0.7.3"

# apar url address
APARURL="http://lsh35350rh/flrt/apars.csv"

# APAR CSV file that will be downloaded and saved to location
APARFILE="apar.csv"

# User provided lslpp output (for FLRTVC website)
LSLPPFILE=""

# User provided emgr output (for FLRTVC website)
EMGRFILE=""

# this is activated if user does not have sudo access for lslpp -e
SKIPEFIX=0

# show all vulnerabilities whether fixed or not
SHOWALL=0

# wget command
DOWNLOAD1CMD="wget -qO $APARFILE $APARURL"

# curl command
DOWNLOAD2CMD="curl -so $APARFILE $APARURL"

# toggle between compact and full reporting
VERBOSE=0

# delimiter for compact reporting
DELIMITER="|"

# disables/enables showing the header line for compact reporting
QUIET=0

# skip downloading the APAR file and use one already in existence
SKIPDOWNLOAD=0

# save LSLPP output here
LSLPPOUTPUT=""

# save EMGR output
EMGROUTPUT=""

# allows choosing a specific fileset
LISTFILESET=""

# allows choosing an apar type, hiper or sec
TYPE=""

# os level
OSLEVEL=""
OSBASELEVEL=""
ISVIOS=0

# Set of arrays to hold LSLPP line data
set -A lslppFilename
set -A lslppVersion
set -A lslppTypeCode
set -A lslppStatusCode

# Map a fileset name to an id number
typeset -A lslppIDs
lslppCount=0

# Map APAR/CVE/Package Names to package names
typeset -A efixAPAR
typeset -A efixPackage

# Regular Expressions for APAR and CVE ids
aparRegex='s/.*\([A-Z]\{2\}[0-9]\{5\}\).*/\1/p'
cveRegex='s/.*\(CVE\-[0-9]\{4\}\-[0-9]\{4\}\).*/\1/p'

# ----------------------------------------------------------------------------
# DOWNLOADING
# ----------------------------------------------------------------------------

# Download the APAR file from the FLRT website
downloadAPAR() 
{
	# check if we can skip download
	if [[ $SKIPDOWNLOAD == 1 ]] ; then
		return
	fi

	# redirect errors to dev/null 
	# {
		# attempt to use wget
		IFS=""
		eval $DOWNLOAD1CMD	# Pull CSV file from URL

		# if wget fails, use curl
		if (( $? > 0 )) ; then
			eval $DOWNLOAD2CMD

			# if curl fails, use FTP (all AIX systems should have it preinstalled)
			# this is used as last fallback because its updated through cronjob
			if (( $? > 0 )) ; then
				# ftp://ftp.software.ibm.com/software/server/flrtvc/hiper_security.csv
				/usr/bin/ftp -n ftp.software.ibm.com  <<END_SCRIPT
				user anonymous ibmFLRTVC
				cd  /software/server/flrtvc 
				get hiper_security.csv
				quit
END_SCRIPT
				
				cp hiper_security.csv $APARFILE
				rm hiper_security.csv
			fi
		fi
	# } >/dev/null 2>&1
}



# ----------------------------------------------------------------------------
# OS LEVEL
# ----------------------------------------------------------------------------

# parse the OS level from the "bos.rte" version number
# use only the first two numbers, e.g., 7.1.3.0, converts to "7100"
parseOSLevel() # version
{
	# split version using the . as delimiter
	IFS='.'
	set -A version $1
	IFS=""

	# set base level using the first two digits with 00 appended, e.g "7100"
	OSBASELEVEL=${version[0]}${version[1]}"00"
	#echo "oslevel="$OSBASELEVEL
}

checkOSLevel() #osversions
{
	#only check if there is a valid OSLevel in the version listing
	contains2 $1 "-"
	if (( $? == 1 || $ISVIOS == 1 )) ; then
		# check if apar data line has our OS base level
		contains2 $1 $OSBASELEVEL
		if (( $? == 0 )) ; then
			return 0
		fi
	fi

	return 1
}


# ----------------------------------------------------------------------------
# LSLPP PROCESSING
# ----------------------------------------------------------------------------

# parse the Interim Fixes that have been installed to make note in our report
# Package Name Example: IV79943s5b.160119.epkg.Z
# Apar Column Example: IV79943 or CVE-2006-0987
# Parse out the APAR and CVE and FixPackage Name (everything before first ".")
# We want to map each item back to the FixPackage Name, this will allow us to quickly locate
# multiple and single fixes
parseEFIX()
{
	efixoutput=""

	# parse from emgr output file
	if (( ${#EMGRFILE} > 0 )) ; then
		efixoutput=$(cat $EMGRFILE)
		contains2 $efixoutput "no efix data"
		if (( $? == 1 || ${#efixoutput} < 3 )) ; then
			SKIPEFIX=1
			return
		fi
		
	# no file, try running emgr command
	else
		# retrieve efixes through root
		efixoutput=$(emgr -lv3 2>/dev/null)
		
		# if it failed (because no root access), try sudo
		if (( $? != 0 )) ; then
			# if no sudo access, skip efix
			#echo ">>>flrtvc>>> Attempting to use sudo."
			efixoutput=$(sudo emgr -lv3 2>/dev/null)
			if (( $? != 0 )) ; then
				SKIPEFIX=1
				return
			fi
		fi
	fi
	

	# get a line count of the output
	IFS=""
	efixSearch=0
	efixLabel=""
	efixLabelPrefix="EFIX LABEL: "
	efixDescPrefix="Description:"
	output=""

	# map each fix package label to an apar or cve
	echo $efixoutput | 
		while IFS= read -r line ; do

			line=${line%$'\r'}

			if (( ${#line} == 0 )) ; then
				continue
			fi

			# is this the EFIX Label line?
			contains2 $line $efixLabelPrefix
			if (( $? == 1 )) ; then

				if (( $efixSearch == 1 )) ; then
					saveEfixes $output $efixLabel
				fi
				efixSearch=0
				efixLabel=${line/$efixLabelPrefix/}
				#efixLabel=${efixLabel/[\r]/}
				efixLabel=${efixLabel%$'\r'}

				aparID=""
				# save the package and apar names
				hasMatch $efixLabel $aparRegex
				if (( $? == 1 )) ; then
					aparID=${efixLabel:0:7}
					efixPackage[$aparID]=1;
				fi
				efixPackage[$efixLabel]=1;
			fi

			# is this the description line?
			contains2 $line $efixDescPrefix
			if (( $? == 1 && $efixSearch == 0 )) ; then
				efixSearch=1
			fi

			# only search after we found the description line and before an EFIX label
			if (( $efixSearch == 0 )) ; then
				continue
			fi

			output=$output" "$line
		done

	if (( ${#output} > 0 )) ; then
		saveEfixes $output $efixLabel
	fi
}

saveEfixes() # output efixLabel
{
	# search for matching APARs
	# save the APAR key with FixPackage value
	findMatches $1 $aparRegex
	for i in ${regexMatches[@]}; do efixAPAR[$i]=$2; done

	# search for matching CVEs
	# save the CVE key with FixPackage value
	findMatches $1 $cveRegex
	for i in ${regexMatches[@]}; do efixAPAR[$i]=$2; done
}


# locates an EFIX from a list of apars that exist in our efix mapping and adds to the reporting array
findEFIX() #aparlist fixlist lslppID issuedDate
{
	# requires sudo access, skip if no access
	if (( $SKIPEFIX != 0 )) ; then
		
		arrEFIX[$vulCount]=""
		return
	fi

	# Step 1) Check for matching APAR names
	# most APARs are delimited with /, but some are just with space
	# check if there is a /, if not use space
	delim="/"
	contains2 $1 $delim
	if (( $? == 0 )) ; then
		delim=" "
	fi

	# split the apars into an array using delimiter
	IFS="$delim"
	set -A apars $1
	count=0

	# clear, as it may be set from previous find
	arrEFIX[$vulCount]=""

	# locate the apar that matches our efix apar and add to reporting array
	found=0
	while (( $count < ${#apars[@]} )) ; do
		apar=$(trim ${apars[count]})
		IFS=""
		
		# ignore bad splits (usually just a "/" string)
		if (( ${#apar} <= 2 )) ; then
			count=$((count+1))
			continue
		fi

		IFS=""

		# check if apar exists in our efix map
		if [[ ${efixAPAR[$apar]} ]] ; then
			# append multiple fixes into one string
			fixName=$(trim ${efixAPAR[$apar]})
			appendEFix $fixName $2
			return
		fi

		count=$((count+1))
	done


	# Step 2) Check for matching FIX package names
	# most Fix Packages are delimited with /, but some are just with space
	# check if there is a /, if not use space
	delim="/"
	contains2 $2 $delim
	if (( $? == 0 )) ; then
		delim=" "
	fi

	# split the apars into an array using delimiter
	IFS="$delim"
	set -A fixes $2
	

	# copmare the fix package names to the efixes in emgr
	count=0
	while (( $count < ${#fixes[@]} )) ; do
		fix=$(trim ${fixes[count]})
		IFS=""

		fixID=${fix%%.*}
		aparID=$fixID
		hasMatch $fixID $aparRegex
		if (( $? == 1 )) ; then
			aparID=${fixID:0:7}
		fi

		# ignore bad splits (usually just a "/" string)
		if (( ${#fixID} <= 2 )) ; then
			count=$((count+1))
			continue
		fi

		if [[ ${efixPackage[$fixID]} || ${efixAPAR[$fixID]} || ${efixPackage[$aparID]} || ${efixAPAR[$aparID]} ]] ; then
			# append multiple fixes into one string
			appendEFix $(trim $fixID) $2
			return
		fi

		count=$((count+1))
	done

	
}

# Appends the APAR Fixes to a single string for the current vulnerability being processed
# Also, check against the apar fixlist to see if item has been deprecated
appendEFix() # aparFixName aparFixList
{
	# skip if string is empty
	if (( ${#1} == 0 )) ; then
		return
	fi
	
	tmp=${arrEFIX[$vulCount]}
	pkg=$1
	
	# skip if already exists in our list
	contains2 $tmp $pkg
	if (( $? == 1 )) ; then
		return
	fi

	# check if its deprecated, do not count it as a fix
	contains2 $2 "DEPRECATED::"$pkg
	if (( $? == 0 )) ; then
		fixCount=$((fixCount+1))
	else
		pkg="DEPRECATED::"$pkg
	fi

	IFS=""
	if (( ${#tmp} > 0 )) ; then
		arrEFIX[$vulCount]=$tmp" / "$pkg
	else
		arrEFIX[$vulCount]=$pkg
	fi

	
}


# ----------------------------------------------------------------------------
# LSLPP PROCESSING
# ----------------------------------------------------------------------------

# Run the LSLPP command and save the data to a set of arrays
parseLSLPP()
{
	if (( ${#LSLPPFILE} > 0 )) ; then
		LSLPPOUTPUT=$(cat $LSLPPFILE)
	else
		LSLPPOUTPUT=$(lslpp -L -q -c)
	fi
	
	#loop through the LSLPP output | lowercase all text | output filename, version, typecode, and statuscode
	IFS=""
	echo $LSLPPOUTPUT | tr "[A-Z]" "[a-z]" | awk -F: '{print $1,$2,$3,$6,$7}' | 
	while IFS=" " read filepath filename version typecode statuscode
		do
			# if lslpp -hac is used, remove root and share filesets
			contains2 $filepath "/etc/objrepos"
			if (( $? == 1 )) ; then
				continue
			fi

			contains2 $filepath "/usr/share"
			if (( $? == 1 )) ; then
				continue
			fi

			strEquals $filename "bos.rte"
			if (( $? == 1 )) ; then
				parseOSLevel $version
			fi
			# add each line to an array, that has an ID mapped to the filename
			addLSLPP $filename $version $typecode $statuscode
		done
}


# Add the LSLPP data to a set of arrays by ID
# A dictionary is used to map filename to the ID for fast lookup
addLSLPP() # filename version type status
{
	IFS=""

	lslppIDs[$1]=$lslppCount
	lslppFilename[$lslppCount]=$1
	lslppVersion[$lslppCount]=$(fixVersion $2)
	lslppTypeCode[$lslppCount]=$3
	lslppStatusCode[$lslppCount]=$4

	#echo "Added "$1" to "$lslppCount
	lslppCount=$(($lslppCount+1))
}


# Find the LSLPP ID for our arrays using the mapped LSLPP filename
# returns -1 on failure
findLSLPP() # filename
{
	filename=$1

	if [ -n "${lslppIDs[$filename]+1}" ] ; then
	    echo ${lslppIDs[$filename]}
	fi

	echo "-1"
}



# ----------------------------------------------------------------------------
# APAR CSV PROCESSING (line-by-line)
# ----------------------------------------------------------------------------

# reporting arrays used for each fileset
# each array is reset when a new fileset is started
currentFileset=""
currentVersion=""
currentLSLPP=-1
set -A arrType
set -A arrAbstract
set -A arrApars
set -A arrIFixes
set -A arrBulletinURL
set -A arrDownload
set -A arrVersions
set -A arrEFIX
set -A arrAPARScore
set -A arrReboot
set -A arrIssued
set -A arrFixedIn

typeset -A arrScore
vulCount=0
fixCount=0
totalVulCount=0
totalFixCount=0
totalFileset=0
verboseOutput=""

# Parse a CSV file in the APAR format and assign variables to each column
# loop through each line and compare the APAR fileset versions to the LSLPP fileset versions
parseAPARFile() # filename currentversion
{
	#set -o noglob

	# verbose is disabled
	if (( $VERBOSE == 0 )) ; then
		# output the header for compact reporting
		if (( $QUIET == 0 )) ; then
			printHeader
		fi
	fi


	IFS=""

	# standard output the aparfile | 
	# remove duplicate lines |
	# remove first line | 
	# fix version ranges with spaces | 
	# split apart the fileset lists from single row and generate new rows for each one | 
	# sort fileset name alphabetically and remove duplicates > 
	# output to temp file
	#
	# notes: use line below for awk numbers:
	# (1)type (2)product (3)versions (4)abstract (5)apars (6)fixedIn (7)ifixes (8)bulletinURL (9)filesets (10)issued (11)updated (12)siblings (13)download (14)cvss (15)reboot
	cat $APARFILE | 
		awk '!a[$0]++' |
		sed -e '1d' | 
		sed -e 's/- \([0-9]\)/-\1/g' | 
		awk -F, 'split($9, name_version," ") {for (k in name_version) {print name_version[k]","$1","$4","$5","$7","$8","$13","$3","$14","$15","$10","$11","$6}}' | 
		awk -F, 'n=split($1, name_version,":") { for (k=2;k<=n;k++) {print name_version[1]":"name_version[k]","$2","$3","$4","$5","$6","$7","$8","$9","$10","$11","$12","$13}}' |
		sort -fu |
		grep -i "$LISTFILESET" | 

	# loop through processed APARFILE
		while IFS=',' read fileinfos atype abstract apars ifixes bulletinURL download osversions cvss reboot issued updated fixedIn
		do
			#echo $fileinfos","$atype","$abstract","$apars","$ifixes","$bulletinURL","$download","$osversions
			
			IFS="/\\"
			set -A cvssItems $cvss
			count=0
			cvssFixed=""
			while (( $count < ${#cvssItems[@]} )) ; do
				IFS=":"
				set -A scores ${cvssItems[count]}
				cve=$(trim ${scores[0]})
				thescore=$(trim ${scores[1]})
				arrScore[$cve]=$thescore
				if (( $count > 0 )) ; then
					cvssFixed=$cvssFixed" "
				fi
				cvssFixed=$cvssFixed$cve":"$thescore

				count=$(($count+1))
			done

			# check for matching OS base level for this APAR
			checkOSLevel $osversions
			if (( $? == 0 )) ; then
				continue
			fi

			# check for user specified APAR type
			if (( ${#TYPE} > 0 )) ; then
				contains2 $atype $TYPE
				if (( $? == 0 )) ; then
					continue
				fi
			fi

			# fix an error with the version spacing for ranges (ie 7.0.0.0- 7.1.2.3, when it should be 7.0.0.0-7.1.2.3)
			IFS=""
			fileinfos=$(fixRange $fileinfos)
			
			# split the filename and versions into an array
			# format: filename:x.x.x.x
			# format: filename:<x.x.x.x
			# format: filename:x.x.x.x-x.x.x.x
			IFS=":"
			set -A filedata $fileinfos

			# trim the apar filename and unsafe version string and lowercase it
			aparFilename=$(trim ${filedata[0]})
			IFS=""
			aparFilename=$(echo $aparFilename | tr "[A-Z]" "[a-z]")
			aparVersions=""
			if (( ${#filedata[@]} == 2 )) ; then
				aparVersions=$(trim ${filedata[1]})
			fi

			# find the lslpp ID that is mapped to this fileset's filename
			lslppID=$(findLSLPP $aparFilename)
			lslppID=$(($lslppID+1))
			
			# check for valid lslppID 
			if (( $lslppID <= 0 )) ; then
				continue
			fi

			# trim the lslpp filename and versions
			lsFilename=$(trim ${lslppFilename[lslppID]})
			lsVersion=$(trim ${lslppVersion[lslppID]})
			currentLSLPP=lslppID

			# compare to make sure we found matching filesets
			strEquals $lsFilename $aparFilename
			if (( $? == 0 )) ; then
				continue
			fi

			# keep track of when we start a new fileset
			strEquals $aparFilename $currentFileset
			if (( $? == 0 )) ; then

				# if data exists, generate the report
				generateReport

				# reset fileset array data
				currentFileset=$lsFilename
				currentVersion=$lsVersion
				vulCount=0
				fixCount=0
			fi

			# verify that our lslpp file version falls under/within the APAR version
			verifyVersionInRange $lsVersion $aparVersions
			if (( $? == 0 )) ; then
				continue
			fi

			# this fileset is vunerable, add to report
			IFS=""
			arrType[$vulCount]=$(trim $atype)
			arrAbstract[$vulCount]=$(trim $abstract)
			IFS=""
			arrApars[$vulCount]=$(trim $apars)
			arrIFixes[$vulCount]=$(trim $ifixes)
			arrBulletinURL[$vulCount]=$(trim $bulletinURL)
			arrDownload[$vulCount]=$(trim $download)
			arrVersions[$vulCount]=$(trim $aparVersions)
			arrReboot[$vulCount]=$(trim $reboot)
			arrIssued[$vulCount]=$(trim $issued)
			if (( ${#updated} > 0 )) ; then
				arrIssued[$vulCount]=$(trim $updated)
			fi

			# format from yyyymmdd to mm/dd/yyyy
			temp=${arrIssued[vulCount]}
			arrIssued[$vulCount]=${temp:4:2}"/"${temp:6:2}"/"${temp:0:4}

			arrFixedIn[$vulCount]=$(trim $fixedIn)

			arrAPARScore[$vulCount]=$cvssFixed

			# if (( ${#cvssItems[@]} == 1 )) ; then
			#	cve=${cvssItems[0]}
			#	arrAPARScore[$vulCount]=${cve#*:}
			#else
			#	arrAPARScore[$vulCount]=""
			#fi

			findEFIX $apars $(trim $ifixes) $lslppID $issued

			vulCount=$(($vulCount+1))
		done  

	# the last fileset gets skipped, so generate it if any data exists
	generateReport

	# verbose is enabled
	if (( $VERBOSE != 0 )) ; then

		printVerboseHeader
		IFS=""
		echo $verboseOutput
		
	fi
}



# ----------------------------------------------------------------------------
# REPORTING
# ----------------------------------------------------------------------------

# Generates a report for the previous fileset if any vulnerabilities exist
generateReport()
{
	# exit if there are no vulnerabilities for this fileset
	if (( $vulCount == 0 )) ; then
		return
	fi

	# starting a new fileset, generate report of previous fileset
	if (( $VERBOSE == 1 )) ; then
		generateLongReport
	else
		generateCompressedReport
	fi
}

# Generate a compact report for the specific fileset we just finished checking in parseAPAR function
generateCompressedReport()
{
	# loop through all available APAR rows that are vulnerable
	i=0
	while (( $i < $vulCount ))
	do
		hasFix=${arrEFIX[i]}
		contains2 $hasFix "DEPRECATED"
		isDeprecated=$?

		if [[ $SHOWALL > 0 || ${#hasFix} == 0 || $isDeprecated == 1 ]] ; then
			printDItem $currentFileset 
			printDItem $currentVersion 
			printDItem ${arrType[i]}
			printDItem ${arrEFIX[i]}

			# attach FIXED verbiage to a fixed vulnerability's abstract
			if [[ $isDeprecated == 1 ]] ; then
				printDItem "DEPRECATED FIX - "${arrAbstract[i]}
			elif [[ ${#hasFix} > 0 ]] ; then
				printDItem "FIXED - "${arrAbstract[i]}
			else
				printDItem "NOT FIXED - "${arrAbstract[i]}
			fi

			
			printDItem ${arrVersions[i]} 
			printDItem ${arrApars[i]} 
			printDItem ${arrBulletinURL[i]}
			printDItem ${arrDownload[i]}

			#score=${arrApars[i]}
			#score=${arrScore[$score]}
			#if (( ${#score} == 0 )) ; then
			score=${arrAPARScore[i]}
			#fi
			printDItem $score

			typeset -u rebootStr
			rebootStr=${arrReboot[$i]}
			printDItem $rebootStr
			printDItem ${arrIssued[i]}
			printItem ${arrFixedIn[i]}

			printNewline
		fi

		i=$(($i+1))
	done
}

# Generate a full report for the specific fileset we just finished checking in parseAPAR function
generateLongReport()
{

	# show all fixes and non-fixes
	if [[ $SHOWALL > 0 ]] ; then
		saveVerboseOutput $(printf "")
		saveVerboseOutput $(printf '%s' "--------------------------------------------------------------------------------")
		saveVerboseOutput $(printf "%s - %s - Fixed (%d of %d)" $currentFileset $currentVersion $fixCount $vulCount)
		saveVerboseOutput $(printf '%s' "--------------------------------------------------------------------------------")
		saveVerboseOutput $(printf "")

		totalFileset=$(($totalFileset+1))
		totalVulCount=$(($totalVulCount+$vulCount))

	# show only non-fixed items, adjust counts to compensate
	elif [[ $fixCount != $vulCount ]] ; then
		actualCount=$(($vulCount-$fixCount))
		saveVerboseOutput $(printf "")
		saveVerboseOutput $(printf '%s' "--------------------------------------------------------------------------------")
		saveVerboseOutput $(printf "%s - %s - Vulnerabilities (%d)" $currentFileset $currentVersion $actualCount)
		saveVerboseOutput $(printf '%s' "--------------------------------------------------------------------------------")
		saveVerboseOutput $(printf "")

		totalFileset=$(($totalFileset+1))
		totalVulCount=$(($totalVulCount+$actualCount))
	fi

	# always keep a totalFixCount
	totalFixCount=$(($totalFixCount+1))
		

	i=0
	actualCount=0 # only count what will be shown

	# loop through each vulnerability and gather what will be outputted
	while (( $i < $vulCount ))
	do

		hasFix=${arrEFIX[i]}
		contains2 $hasFix "DEPRECATED"
		isDeprecated=$?
		# skip fixed items when not showing all
		if [[ $SHOWALL > 0 || ${#hasFix} == 0 || $isDeprecated == 1 ]] ; then


			IFS=""

			# attach FIXED verbiage to a fixed vulnerability's abstract
			if [[ $isDeprecated == 1 ]] ; then
				saveVerboseOutput $(printf " (%d) DEPRECATED FIX - %s" $(($actualCount+1)) ${arrAbstract[i]})
			elif [[ ${#hasFix} > 0 ]] ; then
				saveVerboseOutput $(printf " (%d) FIXED - %s" $(($actualCount+1)) ${arrAbstract[i]})
			else
				saveVerboseOutput $(printf " (%d) NOT FIXED - %s" $(($actualCount+1)) ${arrAbstract[i]})
			fi

			saveVerboseOutput $(printf "")
			saveVerboseOutput $(printf "     Type:         %s" ${arrType[i]})
			score=${arrApars[i]}
			score=${arrScore[$score]}
			if (( ${#score} == 0 )) ; then
				score=${arrAPARScore[i]}
			fi
			if (( ${#score} > 0 )) ; then
				saveVerboseOutput $(printf "     Score:        %s" $score)
			fi
			
			saveVerboseOutput $(printf "     Versions:     %s" ${arrVersions[i]})
			saveVerboseOutput $(printf "     APARs/CVEs:   %s" ${arrApars[i]})

			efixStr=${arrEFIX[i]}
			if (( ${#efixStr} > 0 )) ; then
				saveVerboseOutput $(printf "     EFix Active:  %s" $efixStr)
			fi
			saveVerboseOutput $(printf "     Last Update:  %s" ${arrIssued[i]})
			saveVerboseOutput $(printf "     Bulletin:     %s" ${arrBulletinURL[i]})
			saveVerboseOutput $(printf "     Download:     %s" ${arrDownload[i]})
			saveVerboseOutput $(printf "     Fixed In:     %s" ${arrFixedIn[i]})
			typeset -u rebootStr
			rebootStr=${arrReboot[$i]}
			contains2 $rebootStr "NO"
			if (( $? == 0 && ${#rebootStr} > 0 )) ; then
				contains2 $rebootStr "LU"
				if (( $? == 1 )) ; then
					rebootStr="Yes, if Live Update disabled"
				fi
				saveVerboseOutput $(printf "     Reboot:       %s" $rebootStr)
			fi
			saveVerboseOutput $(printf "")
			actualCount=$(($actualCount+1))
		fi

		i=$(($i+1))
	done
}

saveVerboseOutput() # line
{
	IFS=""
	verboseOutput=$verboseOutput"$1\n"
}

# outputs the username who generated report and the time it was generated
printVerboseHeader()
{
	printf "////////////////////////////////////////////////////////////\n"
	printf "// IBM FLRTVC (v"$VERSION") Report\n"
	printf "// Server: $(hostname)\n"
	printf "// Date: "$(date)"\n"
	printf "// Report by: "$(who am i | awk '{print $1}')"\n"
	printf "// Vulnerable Filesets: %d\n" $totalFileset
	printf "// Total Vulnerabilities: %d\n" $totalVulCount
	if [[ $SHOWALL > 0 ]] ; then
		printf "// Total Fixes: %d\n" $totalFixCount
	else 
		printf "// Total Fixes (not shown): %d\n" $totalFixCount
	fi
	printf "////////////////////////////////////////////////////////////\n"
}

# prints the header for compact reporting
printHeader()
{
	printDItem "Fileset"
	printDItem "Current Version"
	printDItem "Type"
	printDItem "EFix Installed"
	printDItem "Abstract"
	printDItem "Unsafe Versions"
	printDItem "APARs"
	printDItem "Bulletin URL"
	printDItem "Download URL"
	printDItem "CVSS Base Score"
	printDItem "Reboot Required"
	printDItem "Last Update"
	printItem "Fixed In"
	printNewline
}

# prints an item with delimiter
printDItem() # itemString
{
	IFS=""
	printf "%s%s" $1 $DELIMITER
}

# prints an item without delimiter
printItem() # itemString
{
	IFS=""
	printf "%s" $1
}

# prints a new line character
printNewline()
{
	printf "\n"
}



# ----------------------------------------------------------------------------
# VERSION REPAIR AND CHECKING
# ----------------------------------------------------------------------------

# compare the lslpp version to the apar version range
verifyVersionInRange() # lslppVersion aparVersion
{
	# if there are no apar versions associated, assume all versions are vulnerable
	if (( ${#2} == 0 )) ; then
		return 1
	fi

	contains2 $2 "<"
	if (( $? == 1 )) ; then						# requiredversion is "less than"
		requiredversion=${2#?}						# remove '<' from string

		# check if version is less than equal
		contains2 $2 "="
		if (( $? == 1 )) ; then
			requiredversion=${requiredversion#?}			# remove '=' from string
			#echo $(trim $requiredversion)" "$1
			compareVersions $(trim $requiredversion) $1 	# a result of 2 = greater than
			if (( $? != 2 )) ; then
				return 1
			fi
		fi

		# check if version is less than
		isVersionLess $(trim $requiredversion) $1 	# check version
		return $?
	fi

	contains2 $2 "-"
	if (( $? == 1 )) ; then	# requiredversion is "in range"
		IFS="-"
		set -A vrange $2 		# parse the start and end version ranges
		IFS=""
		isVersionBetween $(trim ${vrange[0]}) $(trim ${vrange[1]}) $1
		return $?
	fi
	
	isVersionEqual $2 $1
	return $?
}


# Version check is versionA equal to versionB
isVersionEqual() # versionA versionB
{
	compareVersions $1 $2
	if (( $? == 0 )) ; then
		return 1
	fi
	return 0
}


# Version check is versionA is less than versionB
isVersionLess() # versionA versionB
{
	compareVersions $1 $2
	if (( $? == 1 )) ; then
		return 1
	fi
	return 0
}



# Version check if current is between start and end
isVersionBetween() # start end current
{
	# verify current version is between start and end required versions
	compareVersions $1 $3
	if (( $? == 2 || $? == 0 )) ; then		# version is above start	
		compareVersions $2 $3
		if (( $? == 1 || $? == 0 )) ; then	# version is below end
			return 1
		fi
	fi
	return 0
}

# Compares two date strings of format: yearmonthday
# example: 20150720
# We can use the date as an integer and compare, works normally
compareDates() # dateA dateB
{
	diff=$(($1-$2))
	# check if less or more
	if (( $diff != 0 )) ; then
		if (( $diff <= 0 )) ; then
			return 2	# v2 is greater
		else
			return 1	# v2 is lesser
		fi
	fi
	return 0 # v1 and v2 are equal
}


# Compares two version strings: returns 0=equal, 1=less than, 2=greater than
compareVersions () # versionA versionB
{
	# parse version number #.#.#.# delimited by .
	IFS='.'
	set -A v1 $1
	IFS='.'
	set -A v2 $2
	IFS=""

	# loop through each number and difference the two
	i=0
	while (( $i < 4 )); do
		start=${v1[i]}
		end=${v2[i]}
		i=$(($i+1))
		if [[ "$start" == "x" || "$end" == "x" ]] ; then
			return 0
		fi

		diff=$(($start-$end))

		# check if less or more
		if (( $diff != 0 )) ; then
			if (( $diff <= 0 )) ; then
				return 2	# v2 is greater
			else
				return 1	# v2 is lesser
			fi
		fi
	done
	return 0	# v1 and v2 are equal
}


# Fixes a version range error where there is a space before or after the "-"
# Error Example: "7.0.1.1- 7.2.0.0"
# Correct Example: "7.0.1.1-7.2.0.0"
fixRange() # string
{
	output=${1//([0-9])- ([0-9])/\1-\2}
	print $output
}


# Fix Version string
# - Fixes format to be: "#.#.#.#" or for any number uses "x" (i.e: x.x.x.x)
# - Removes everything after first alpha character
# - Removes "-##" 
# - Appends ".x" until 3 "." are added
fixVersion() #versionString
{
	newvar=$1

	# remove everything after first character found
	newvar=${newvar//[a-zA-Z]*/}

	# remove any -### attached at the end of a version number
	newvar=${newvar//-[0-9]*/}

	# empty version numbers start with "x."
	if (( ${#newvar} == 0 )) ; then
		newvar="x."
	fi

	# get the last character, if it is a "." append an "x"
	lastchar=${newvar:${#newvar}-1:1}
	contains $lastchar "."
	if (( $? == 1 )) ; then
		newvar=$newvar"xa"
	fi

	# count how many dots we have
	delcnt=${newvar//[0-9a-zA-Z\-\+]/}
	delcnt=${#delcnt}

	# if we have less than 3 "." add more to complete the 3
	while (( $delcnt < 3 )) ; do
		newvar=$newvar".x"
		delcnt=$(($delcnt+1))
	done

	# output the converted version number
	print $newvar
}



# ----------------------------------------------------------------------------
# UTILS
# ----------------------------------------------------------------------------

# Remove white space at the beginning and end of a string
trim() # string
{
	if (( ${#1} == 0 )) ; then
		print ""
		return
	fi
	IFS=""
	output=${1/#+([ $'\t\n\r'])} 
	output=${output/%+([ $'\t'])} 
	print $output
}


# Check if substring is in string
contains() # haystack needle
{
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string" ; then
        return 1    # $substring is in $string
    else
        return 0    # $substring is not in $string
    fi
}


# Check if substring is in string
contains2() # haystack needle
{
	haystack=${1/$2/}
	if (( ${#haystack} != ${#1} )) ; then
		return 1
	fi
	return 0
}


# Check if substring is in string
strEquals() # haystack needle
{
	if [[ $1 == $2 ]] ; then
		return 1
	fi
	return 0
}



set -A regexMatches
findMatches() # haystack pattern
{
	unset regexMatches
	set -A regexMatches
	cnt=0
	haystack=$1
	output=$(echo $haystack | sed -n -e "$2")
	while (( ${#output} != 0 )) ; do
		m=$(trim $output)
		regexMatches[$cnt]=$m
		haystack=${haystack/$m/}
		cnt=$(($cnt+1))
		output=$(echo $haystack | sed -n -e "$2")
	done
}

hasMatch() # haystack pattern
{
	output=$(echo $1 | sed -n -e "$2")
	if (( ${#output} != 0 )) ; then
		return 1
	fi
	return 0
}

# ----------------------------------------------------------------------------
# PROFILING
# ----------------------------------------------------------------------------

profileOutput=""
set -A profileTimes
# Begin Profiling, capture start time
profileBegin() # id
{
	profileTimes[$1]=$SECONDS
}


# End of Profile, output message and execution time
profileEnd() # id msg
{
	#profileEndTime=
	elapsed=$((SECONDS-${profileTimes[$1]}))
	IFS=""
	if (( $QUIET == 0 )) ; then
		profileOutput=$profileOutput$(printf $2' completed in %d:%02d:%02ds' \
       		$((elapsed / 3600)) $((elapsed / 60 % 60)) $((elapsed % 60)))"\n"
    fi
}

profileResults() 
{
	echo $profileOutput
}



# ----------------------------------------------------------------------------
# COMMAND-LINE OPTIONS
# ----------------------------------------------------------------------------

usage()
{
	echo "\n"
	echo "Usage flrtvc: Change delimiter for compact reporting" 1>&2
	echo "\t./flrtvc.ksh -d '||'\n" 1>&2
	echo "Usage flrtvc: Generate full reporting (verbose mode)" 1>&2
	echo "\t./flrtvc.ksh -v\n" 1>&2
	echo "Usage flrtvc: Choose custom apar.csv file to use" 1>&2
	echo "\t./flrtvc.ksh -f myfile.csv\n" 1>&2
	echo "Usage flrtvc: Only show specific filesets in verbose mode" 1>&2
	echo "\t./flrtvc.ksh -vg printers\n" 1>&2
	echo "Usage flrtvc: Show only hiper results" 1>&2
	echo "\t./flrtvc.ksh -t hiper\n" 1>&2
	echo "Usage flrtvc: Custom lslpp and emgr outputs" 1>&2
	echo "\t./flrtvc.ksh -l lslpp.txt -e emgr.txt\n" 1>&2
	echo "Flags:\n" 1>&2
	echo "-d = Change delimiter for compact reporting" 1>&2
	echo "-f = Enter a custom aparCSV file in local filesystem" 1>&2
	echo "-q = Quiet mode, hide compact reporting header" 1>&2
	echo "-s = Skip download and locate 'apar.csv' filename in current directory" 1>&2
	echo "-v = Verbose, full report (for piping to email)" 1>&2
	echo "-g = Filter filesets for specific phrase, useful for verbose mode" 1>&2
	echo "-t = Type of APAR [hiper | sec]" 1>&2
	echo "-l = Enter a custom LSLPP output file, must match lslpp -Lqc" 1>&2
	echo "-e = Enter a custom EMGR output file, must match emgr -lv3" 1>&2
	echo "-x = Skip EFix processing" 1>&2
	echo "-a = Show all fixed and non-fixed HIPER/Security vulnerabilities." 1>&2
	#echo "-o = Custom OS Level, example '6100' or '7100' (removed)" 1>&2
}



while getopts qasvxnd:f:g:t:l:e:o: opt; do
  case $opt in
    d)	DELIMITER=$OPTARG
    ;; 
    q)	QUIET=1
    ;;
    a)	SHOWALL=1
	;;
    s)	SKIPDOWNLOAD=1
    ;;
    v)	VERBOSE=1
    ;;
    f)	APARFILE=$OPTARG
		SKIPDOWNLOAD=1
	;;
	g)	LISTFILESET=$OPTARG
	;;
	t)	TYPE=$OPTARG
	;;
	l)	LSLPPFILE=$OPTARG
	;;
	e)	EMGRFILE=$OPTARG
	;;
	x)	SKIPEFIX=1
	;;
	n)  echo $VERSION
		exit 1
	;;
	o)	OSBASELEVEL=$OPTARG
	;;
    \?)
		echo "Invalid option: -$OPTARG" >&2
		usage
		exit 1
	;;
    :)
		echo "Option -$OPTARG requires an argument." >&2
		usage
		exit 1
	;;
    *)
		usage
		exit 1
	;;
  esac
done


# ----------------------------------------------------------------------------
# UNIT TESTS
# ----------------------------------------------------------------------------
tests()
{
	verifyVersionInRange "1.0.1.513" "0.9.8.0-0.9.8.1800" 
	echo "verifyVersionInRange '1.0.1.513' '0.9.8.0-0.9.8.1800' == "$?

	verifyVersionInRange "0.9.8.0" "0.9.8.0-0.9.8.1800" 
	echo "verifyVersionInRange '0.9.8.0' '0.9.8.0-0.9.8.1800' == "$?

	verifyVersionInRange "0.9.8.0" "0.9.8.0-0.9.8.1800" 
	echo "verifyVersionInRange '0.9.8.1800' '0.9.8.0-0.9.8.1800' == "$?

	verifyVersionInRange "0.8.8.0" "0.9.8.0-0.9.8.1800" 
	echo "verifyVersionInRange '0.8.8.1800' '0.9.8.0-0.9.8.1800' == "$?

	contains2 "hello-world" "-"
	echo "contains2 'hello-world' '-' == "$?

	verifyVersionInRange  "0.9.8.1" "<0.9.8.0"
	echo "verifyVersionInRange '0.9.8.1' '<0.9.8.0' == "$?

	verifyVersionInRange "0.9.8.0" "<0.9.8.0"
	echo "verifyVersionInRange '0.9.8.0' '<0.9.8.0' == "$?

	verifyVersionInRange "0.9.7.9" "<0.9.8.0" 
	echo "verifyVersionInRange '0.9.7.9' '<0.9.8.0' == "$?

	verifyVersionInRange "0.9.8.1" "<=0.9.8.0" 
	echo "verifyVersionInRange '0.9.8.1' '<=0.9.8.0'  == "$?

	verifyVersionInRange "0.9.8.0" "<=0.9.8.0" 
	echo "verifyVersionInRange '0.9.8.0' '<=0.9.8.0'  == "$?

	verifyVersionInRange "0.9.7.9" "<=0.9.8.0" 
	echo "verifyVersionInRange '0.9.7.9' '<=0.9.8.0' == "$?

	verifyVersionInRange "1.1.1.1" "1.1.1.0" 
	echo "verifyVersionInRange '1.1.1.1' '1.1.1.0' == "$?

	verifyVersionInRange "1.1.1.1" "1.1.1.1" 
	echo "verifyVersionInRange '1.1.1.1' '1.1.1.1' == "$?

	verifyVersionInRange "1.1.1.1" "1.1.1.x" 
	echo "verifyVersionInRange '1.1.1.1' '1.1.1.x' == "$?

	verifyVersionInRange "1.1.5.5" "1.1.x.x" 
	echo "verifyVersionInRange '1.1.5.5' '1.1.x.x' == "$?
}

# ----------------------------------------------------------------------------
# MAIN PROGRAM
# ----------------------------------------------------------------------------
main()
{
	#profileBegin 1
		#profileBegin 2
		downloadAPAR
		#profileEnd 2 ">>>flrtvc>>> Download APAR"

		#verify the APARFILE exists
		if [[ ! -e $APARFILE ]] ; then
			printf ">>>flrtvc>>> ERROR: Cannot find the file '%s'\n" $APARFILE
			exit 1
		fi

		#profileBegin 4
		if (( $SKIPEFIX != 1 )) ; then
			parseEFIX
		fi
		#profileEnd 4 ">>>flrtvc>>> Parse EFix"

		#profileBegin 5
		parseLSLPP
		#profileEnd 5 ">>>flrtvc>>> Parse LSLPP"

		#profileBegin 6
		parseAPARFile
		#profileEnd 6 ">>>flrtvc>>> Parse APAR"
	#profileEnd 1 "FLRTVC"
	#profileResults
}

# run the main program
main
#tests

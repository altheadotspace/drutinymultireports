#!/bin/bash

# For debugging
# set -x;

#questions to build the report

# Ask the user the application site name
read -p "What is the site name? " sitename

# Ask the user the environment
read -p "What is the environment? " environment

read -p "Please enter your choice (1=Drupal 8 or later site, 2=Drupal 7: " drupal

while [[ $drupal != 1 && $drupal != 2 ]]; do
  echo "Invalid selection "
  read -p "Please enter your choice (1=Drupal 8 or later site, 2=Drupal 7: " drupal
done

read -p "Please enter your choice (1=ALL domains, 2=ONLY WWW, or 3=WITHOUT WWW): " selection

while [[ $selection != 1 && $selection != 2 && $selection != 3 ]]; do
  echo "Invalid selection. Please choose 1, 2, or 3."
  read -p "Please enter your choice (1=ALL domains, 2=ONLY WWW, or 3=WITHOUT WWW): " selection
done

read -p "Exclude the Acquia domain (1=Yes, 2=No): " acquiadomain

while [[ $acquiadomain != 1 && $acquiadomain != 2 ]]; do
  echo "Invalid selection. Please choose 1, 2, or 3."
  read -p "Please enter your choice (1=Yes, 2=No): " acquiadomain
done

read -p "Please enter your format choice (1=HTML, 2=CSV table report, 3=Both): " format

while [[ $format != 1 && $format != 2 && $format != 3 ]]; do
  echo "Invalid selection. Please choose 1 or 2."
  read -p "Please enter your format choice (1=HTML, 2=CSV, 3=Both): " format
done

if [ "$sitename" == "" ] ; then
  echo 'missing the site name argument'
  exit
fi

if [ "$environment" == "" ] ; then
  echo 'missing the environment argument'
  exit
fi

read -p "Please enter how many sites do you want to create a report (0=ALL): " limitsites

while ! [[ -n "$limitsites" ]] && ! [[ "$limitsites" =~ ^[0-9]+$ ]]; do
    echo "Invalid selection. Please enter 0 if you want to create report for all sites or the number of sites you want to."
    read -p "Please enter how many sites do you want to create a report (0=ALL): " limitsites
done

echo " "

echo "The reports below cover the period of the past 7 days"

echo " "

read -p "Do you also want to run a load analysis report for this docroot? Please enter your choice (1=Yes, 2=No): " loadanalysis

while [[ $loadanalysis != 1 && $loadanalysis != 2 ]]; do
  echo "Invalid selection "
  read -p "Please enter your choice  Please enter your choice (1=Yes, 2=No): " loadanalysis
done

read -p "Do you also want to run a health analysis report for this docroot? Please enter your choice (1=Yes, 2=No): " healthanalysis

while [[ $healthanalysis != 1 && $healthanalysis != 2 ]]; do
  echo "Invalid selection "
  read -p "Please enter your choice  Please enter your choice (1=Yes, 2=No): " loadanalysis
done

read -p "Do you also want to run a traffic analysis report for this docroot? Please enter your choice (1=Yes, 2=No): " trafficanalysis

while [[ $trafficanalysis != 1 && $trafficanalysis != 2 ]]; do
  echo "Invalid selection "
  read -p "Please enter your choice  Please enter your choice (1=Yes, 2=No): " trafficanalysis
done

read -p "Do you also want to run a app analysis report for this docroot? Please enter your choice (1=Yes, 2=No): " appanalysis

while [[ $appanalysis != 1 && $appanalysis != 2 ]]; do
  echo "Invalid selection "
  read -p "Please enter your choice  Please enter your choice (1=Yes, 2=No): " appanalysis
done

# Display a message to let the user know that the script start the process
echo "--------    Running reports for, $sitename.$environment     --------------"

NAMEDETAIL="$sitename$environment-$(date +%Y%m%d%H%M%S)"

# Create folder to storage the reports
if [ ! -d "$sitename" ]; then
  mkdir "$sitename"
fi

cd $sitename

mkdir $NAMEDETAIL
cd $NAMEDETAIL

# getting the domain list
DOMAINLISTTEMP=domainlisttemp.txt
DOMAINLIST=domainlist.txt

if [ "$selection" == 1 ] ; then
    aht @$sitename.$environment do:li  > $DOMAINLISTTEMP
fi

if [ "$selection" == 2 ] ; then
    aht @$sitename.$environment do:li | grep www > $DOMAINLISTTEMP
fi

if [ "$selection" == 3 ] ; then
    aht @$sitename.$environment do:li | grep -v 'www\.' > $DOMAINLISTTEMP
fi

sed -i bak 's/[[:space:]]//g' $DOMAINLISTTEMP 

function validate_domains {
  local domains=$1
  local newlist=$2

  IFS=$'\n'

  for site in $(cat $domains)
  do
    if [[ "$site" == "*"* ]]
    then
      # echo "CONTINUE ----- $site"
      continue
    fi

    if [[ $acquiadomain == 1 ]]
    then
      if [[ "$site" == *"acquia-sites.com" || "$site" == *"acsitefactory.com" ]]
      then
        # echo "CONTINUE ----- $site"
        continue
      fi
    fi


    # echo "NO CONTINUE -------- $site"
    if [[ ! $site == "www."* ]]
    then
      # echo "$site -> doesn't have www"
      domainfind=false
      for domain in $(cat $domains)
      do
        if [[ "www.$site" == "$domain" ]]
        then
          if [[ -f $newlist ]]
          then
            findwww=$(grep "www.$site" $newlist)
          else
            findwww=""
          fi
          if [[ -z $findwww ]]
          then
            echo $domain >> $newlist
          fi
          domainfind=true
          break
        fi
      done
      
      if [[ $domainfind = false ]]
      then
        echo $site >> $newlist
      fi
    else
      # echo "$site -> Does it!!!"
      domainfind=$(grep "$site" $newlist)
      if [[ -z $domainfind ]]
      then
        echo $site >> $newlist
      fi
    fi
  done
}

validate_domains $DOMAINLISTTEMP $DOMAINLIST

rm $DOMAINLISTTEMP
rm *.*bak

COUNTDOMAIN=$(wc -l < "$DOMAINLIST")

SITES=$DOMAINLIST

# defining the site review profile depending of the drupal version
if [ "$drupal" == 1 ] ; then
    SITEREVIEWVERSION=site_review
    HEALTHANALYSISVERSION=health_analysis_d8

fi

if [ "$drupal" == 2 ] ; then
    SITEREVIEWVERSION=site_review_d7
    HEALTHANALYSISVERSION=health_analysis_d7

fi


# generating the html site load analysis
if [ "$loadanalysis" == 1 ] ; then
    IFS=$'\n'
    echo "----- Running load analysis for  $sitename.$environment ------"
    # Create folder to storage the reports
    load_analysis=load_analysis
    if [ ! -d "$load_analysis" ]; then
        mkdir "$load_analysis"
    fi
    cd $load_analysis
    drutinycs profile:run load_analysis aht:@$sitename.$environment -f html --no-interaction --reporting-period-start="-7 days"
    cd ..
fi


# generating the html health
if [ "$healthanalysis" == 1 ] ; then
    IFS=$'\n'
    echo "----- Running health analysis for  $sitename.$environment ------"
    # Create folder to storage the reports
    if [ ! -d "$HEALTHANALYSISVERSION" ]; then
        mkdir "$HEALTHANALYSISVERSION"
    fi
    cd $HEALTHANALYSISVERSION
    drutinycs profile:run $HEALTHANALYSISVERSION aht:@$sitename.$environment -f html --no-interaction --reporting-period-start="-7 days"
    cd ..
fi

# generating the html traffic_analysis
if [ "$trafficanalysis" == 1 ] ; then
    IFS=$'\n'
    echo "----- Running traffic analysis for  $sitename.$environment ------"
    # Create folder to storage the reports
    traffic_analysis=traffic_analysis
    if [ ! -d "$traffic_analysis" ]; then
        mkdir "$traffic_analysis"
    fi
    cd $traffic_analysis

    drutinycs profile:run traffic_analysis aht:@$sitename.$environment -f html --no-interaction --reporting-period-start="-7 days"
    cd ..
fi

# generating the html appanalysis
if [ "$appanalysis" == 1 ] ; then
    IFS=$'\n'
    echo "----- Running APP analysis for  $sitename.$environment ------"
    # Create folder to storage the reports
    app_analysis=app_analysis
    if [ ! -d "$app_analysis" ]; then
        mkdir "$app_analysis"
    fi
    cd $app_analysis

    drutinycs profile:run app_analysis aht:@$sitename.$environment -f html --no-interaction --reporting-period-start="-7 days"
    cd ..
fi



COUNTREPORT=1

# generating the html site review
if [ "$format" == 1 ] ; then
    IFS=$'\n'
    for site in $(cat "$SITES")
    do
        echo "----- $site site $COUNTREPORT of $COUNTDOMAIN ------"
        # Create folder to storage the reports
        if [ ! -d "$SITEREVIEWVERSION" ]; then
            mkdir "$SITEREVIEWVERSION"
        fi
        cd $SITEREVIEWVERSION

        drutinycs profile:run $SITEREVIEWVERSION aht:@$sitename.$environment --uri=$site -f html --no-interaction --reporting-period-start="-7 days"
        COUNTREPORT=$((COUNTREPORT+1))
        cd ..

    done
fi

# Create folder to storage the reports
if [ ! -d "$SITEREVIEWVERSION" ]; then
    mkdir "$SITEREVIEWVERSION"
fi
cd $SITEREVIEWVERSION


# generating the site review policies list
SITEREVIEWMAPPING="site_review_mapping.csv"
SITEREVIEWMAPPINGTEMP="site_review_mapping_temp.txt"

drutinycs profile:info $SITEREVIEWVERSION > $SITEREVIEWMAPPINGTEMP
cat $SITEREVIEWMAPPINGTEMP  | sed '/Acquia Cloud Site Review/,/Policies/d' | sed '1,6d' | sed -e :a -e '$d;N;2,3ba' -e 'P;D' | sed 's/    */|/g' | awk -F '|' '{print $1}' | sed 's/^..//' >> $SITEREVIEWMAPPING
rm $SITEREVIEWMAPPINGTEMP

# generating the csv report
if [[ $format -eq 2 || $format -eq 3 ]] ; then

    REPORTCSV="report_$NAMEDETAIL.csv"
    REPORTCSVTMP="report_CSVTEMP.csv"
    TEMP="temporary.txt"
    IFS=$'\n'

    #Print policies to the report csv file
    echo "Policies" > $REPORTCSV
    cat $SITEREVIEWMAPPING >> $REPORTCSV

    COUNT=0

    for site in $(cat "../$SITES")
    do

        echo "----- $site site $COUNTREPORT of $COUNTDOMAIN ------"

        # generating the html site review if user select both
        if [ "$format" == 3 ] ; then
            
            drutinycs profile:run $SITEREVIEWVERSION aht:@$sitename.$environment --uri=$site -f html --no-interaction --reporting-period-start="-7 days"
            
        fi

        #Print the site name in the next column
        sed -i bak "1s/$/;$site/" $REPORTCSV

        drutinycs profile:run $SITEREVIEWVERSION --no-interaction aht:@$sitename.$environment --uri=$site -f terminal > $TEMP

        cat $TEMP | sed '/## Issues.*$/,$d' | sed '/Purpose/,/Issue Summary/d' | sed '/^-/d' | sed 's/[[:blank:]]\{2,\}//g' | sed -e 's/|/;/g' -e 's/ ;/;/g' -e 's/; /;/g' | awk -F ';' '{print $1";"$3}' | sed '1d; 2d' | sed -e :a -e '$d;N;1,3ba' -e 'P;D' > $REPORTCSVTMP

        MAPPINCOUNT=2

        for line in $(cat $SITEREVIEWMAPPING); do

            REVIEW="$(grep $line $REPORTCSVTMP | awk -F ';' '{print $2}')"

            if [ -z "$REVIEW" ] ; then
                sed -i bak "${MAPPINCOUNT}s/$/;/" $REPORTCSV
            else
                sed -i bak "${MAPPINCOUNT}s/$/;$REVIEW/" $REPORTCSV
            fi

            MAPPINCOUNT=$((MAPPINCOUNT+1))
        done

        if [ "$limitsites" != 0 ] ; then
            # Using this variable to limit how many sites do you want to create report
            COUNT=$((COUNT+1))
            if [ "$COUNT" == $limitsites ] ; then
                rm $SITEREVIEWMAPPING
                rm $REPORTCSVTMP
                rm "${REPORTCSV}bak"
                rm $TEMP
                echo "Report ready"
                exit
            fi
        fi
    COUNTREPORT=$((COUNTREPORT+1))

    done
    rm $TEMP
    echo "Report ready"
fi

rm $SITEREVIEWMAPPING
rm $REPORTCSVTMP
rm "${REPORTCSV}bak"


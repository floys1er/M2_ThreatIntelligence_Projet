#!/bin/bash


#write every country targeted for every APT group from a country
myfunc() {
echo "You want to read $1.txt"

var="$1.txt"
cat $var | while read group; do i=$(echo "$group"); echo "$i"; grep -e "\"cfr-suspected-victims\",[0-9]*" $i | awk -F '"' '{print $8}' | tee /tmp/$i >> /tmp/countries ; proportion $i ; rm /tmp/$i;
done

}

#reads list of countries targeted by one APT group and write some stats for 'Region', into /tmp/region/ and 'Regime', into /tmp/regime  fields.
proportion() {

apt=$(cat $1 | grep -w -e "\"value\"" | awk -F '"' '{print $6}' | sed -E "s/([a-zA-Z]) ([A-Za-z0-9])/\1_\2/g" | sed -E "s/ |\[|\]//g")

echo "I am processing with group : $apt"

#verifying that the apt.txt file isn't empty
if [[ ! -z $(cat /tmp/$i) ]]
	then
		#loading amd processing info for each country in apt.txt
		cat /tmp/$i | while read country; do c=$(echo "$country" | sed -E "s/ /_/g");
		if [ -f $HOME/project/countries/$c.txt ]
			then
				grep -e "Region" $HOME/project/countries/$c.txt | sed -E "s/ /_/g" | awk '{print $2}' | sed s/\"//g >> /tmp/region/$apt.txt
				grep -e "Regime" $HOME/project/countries/$c.txt | sed -E "s/ /_/g" | awk '{print $2}' | sed s/\"//g >> /tmp/regimes/$apt.txt

			fi;done

	if [ -e /tmp/region/$apt.txt ]
		then
			cat /tmp/region/$apt.txt | awk '{a[$0]++}END{for(k in a){print k,a[k]}}' | sort -k2,2nr | sponge /tmp/region/$apt.txt
			cat /tmp/regimes/$apt.txt | awk '{a[$0]++}END{for(k in a){print k,a[k]}}' | sort -k2,2nr | sponge /tmp/regimes/$apt.txt
		fi
fi
}

#write some stats concerning military expenditures into /tmp/military
military_sorting() {

sed -e "s/ /_/g" /tmp/countries | sponge /tmp/countries

sort -u /tmp/countries | sed -E "s/ /_/g" | while read group; 
do
if [ -e $HOME/project/countries/$group.txt ]
        then
		#echo name of country, then number of attacks, then the parameter specified in country_list file
                echo "$group $(cat /tmp/countries | grep -e "$group" | sed -e "s/ /_/g" | wc -l) $(grep -e "Military" ../countries/$group.txt | awk -F '"' '{print $6}' | sed -e "s/ //g") "
fi;
done | sed "s/null/0.0/g" | sort -k3,3nr > /tmp/military


}

gdp_sorting() {

sed -e "s/ /_/g" /tmp/countries | sponge /tmp/countries

sort -u /tmp/countries | sed -E "s/ /_/g" | while read group;
do
if [ -e $HOME/project/countries/$group.txt ]
        then
		#echo name of country, then number of attacks, then the parameter specified in country_list file
                echo "$group $(cat /tmp/countries | grep -e "$group" | sed -e "s/ /_/g" | wc -l) $(grep -e "\"GDP" ../countries/$group.txt | awk -F '"' '{print $6}' | sed -e "s/ //g") "
fi;
done | sort -k3,3nr > /tmp/gdp


}


#delete all the files created with previous calls for this script
delete() {

cat sampleA.txt | while read actor;do 
if [ -e $actor.txt ]
	then
		rm $actor.txt
fi;
done

rm /tmp/military
rm /tmp/region/*
rm /tmp/regimes/*
rm /tmp/gdp

if [ ! -e /tmp/region/ ]
	then
		mkdir /tmp/region/
fi

if [ ! -e /tmp/regimes/ ]
        then
                mkdir /tmp/regimes/
fi
}

#function to copy data from some countries into other folder to deal with /tmp/countries notation; and adding Unknown for groups without specified targets
initialize() {

cp ../countries/United_States.txt ../countries/USA.txt
cp ../countries/United_Kingdom.txt ../countries/UK.txt
cp ../countries/United_Arab_Emirates.txt ../countries/UAE.txt


for i in $(seq 1 343 )
do
        if [ -f "$i.txt" ]
        then
                if [[ -z $(cat $i.txt | grep "\"cfr-suspected-victims\",0" $i.txt) ]]
                then
                        echo "[\"values\",$i,\"meta\",\"cfr-suspected-victims\",0]      \"Unknown\"" >> $i.txt
                fi
        fi
done

}


delete

initialize

#command to display every native country for every APT group
grep "\"country\"\]" [0-9]*.txt | awk '{print $2}' | sed -E "s/\"//g" | sed -E "s/,/\n/" | awk '{print $0}' | awk '{a[$0]++}END{for(k in a){print k,a[k]}}' | sort -k2,2nr > /tmp/groups_origin_countries

#we select countries with at least 4 APT groups
grep "\"country\"\]" [0-9]*.txt | awk '{print $2}' | sed -E "s/\"//g" | sed -E "s/,/\n/" | awk '{print $0}' | awk '{a[$0]++}END{for(k in a){print k,a[k]}}' | sort -k2,2nr | awk '{if ($2 >= 4) print $1}' > sampleA.txt

#matching every txt folder with their own country into country.txt
while read country; do c=$(echo "$country"); grep -w -e "\"$c\"" [0-9]*.txt | awk -F ":" '{print $1 }' | sort -u >> $c.txt; myfunc $c; done < sampleA.txt
military_sorting
gdp_sorting

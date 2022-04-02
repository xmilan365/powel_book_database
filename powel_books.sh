#!/bin/bash

source config.sh
log="${HOME}/logs/powel_books_"$(date +%Y%m%d%H%M%S)".log"
all_links="${HOME}/bin/powel_books/all_links.txt"

# FUNCTIONS ############################################################################################

logs () {
        RED='\033[0;31m'
        NC='\033[0m'
        echo -e "\n${RED}[$(date +%c)]: ${1}${NC}\n" >> ${log}
}

#######################################################

loop_links () {
#loop links through first 10 pages on web
	logs "Getting links from pages on the web"
	for i in {1..10}; do
	       	curl "https://www.powells.com/browse-book-genres/computers-and-internet?book_class=New&mpp=50&pg=$i" | grep "href=" | grep "/book/" | sed "s/^.*href=/https\:\/\/www\.powells\.com/" | sed "s/ .*$//" | sed 's/"//g' | uniq
	done > ${all_links} 2>>${log}
	logs "Links stored in ${all_links}"
}

#######################################################

insert_record () {
#insert records found in loop_links into database table, log messages in log.txt
	logs "Inserting record"
	docker exec -it oracle bash -c "
	    source /home/oracle/.bashrc
	    printf '%s\n' \\ \"
	    insert into powel_books (link, NAME, price, isbn, powel_id, timestamp)
	    values ('${book_link}','${book_name}', ${book_price}, '${book_isbn}', '${powel_id}', '${timestamp}');\" | sqlplus -s ${oracle_username}/${oracle_password}@ORCLCDB" >> ${log} 2>>${log}
}

#######################################################

loop_records () {
#loop through all links in txt file, call insert record function
	for i in $(cat ${all_links}); do
		logs "Creating record"
		book_link="${i}"
		book_price="$(curl ${book_link} | html2text | sed -n '/View Larger ImageView Larger Images/,$p' | sed -n '/Add_to_Cart/q;p' | tail -n+2 | head -n-2 | cut -b 2-)"
		book_name="$(echo ${book_link} | cut -d "/" -f 5 | sed 's/-/ /g' | rev | cut -d " " -f 2- | rev)"
		book_isbn="$(echo ${book_link} | cut -d "/" -f 5 | sed 's/-/ /g' | rev | cut -d " " -f 1 | rev)"
		powel_id="$(echo "PWL${RANDOM}$(date +%s%N | head -c10)")"
		timestamp="$(date +%s)"
		insert_record
	done 2>>${log}
}

#######################################################

make_stats () {
# create statistics about the script that will be logged in log
	logs "Creating statistics:"
	echo "#############################################################"
	echo "###  Process was done in $(((${finite_time} - ${initial_time})/60)) minutes" >>${log}
	echo "###  $(grep -c "1 row created" ${log}) records were added" >>${log}
	echo "#############################################################"
}

#######################################################

clean_up () {
	rm ${all_links}
}
# MAIN LOGIC ###########################################################################################

# Set beginning time
initial_time=$(date +%s)

# make a list of links
logs "Starting..."
loop_links

# Start looping through the list of links
logs "Inserting records to database"
loop_records

# Removing temporary files
logs "Cleaning up"
clean_up
logs "...Finished"

# Set finite time
finite_time=$(date +%s)

# Make final statistics
make_stats

# Notify when it's finished
spd-say Finished
zenity --info --text='Process is finished!'

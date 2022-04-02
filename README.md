# powel_books_database
This shell script will scrape data from powel books book website and store them in the database table.

In config.sh file, credentials oracle_username and oracle_password are stored. 

Main logic of the script is make list of configurable amount of book links using curl scraping, loop through every single record and insert it into database. The data that are inserted into the table are:
	-	sequence_id
	-	book_link
	-	book_name
	-	book_price
	-	book_isbn
	-	powel_id
	-	timestamp	

In the end, final statistics are made, for example, how long it takes, how many records were inserted into the table etc. Every temporary file is cleaned up and user is notified about finishing the script. All activities are logged in logfile. 

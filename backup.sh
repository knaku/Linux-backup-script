#!/bin/bash

menu=0
directory=ERROR:noInput
LOG=ERROR:noLogFileInput


menu1 ()			#Menu 1 - do a backup now
{
	clear

	printf "%b\n\n\nMenu 1"
	printf "%b\n\n\n\tPath of the directory you want to backup: "
	read -r dir
	directoryName=$( basename "$dir" )																								#getting basename
	filename="$directoryName-$(date "+%y%m%d").tar.gz"																#setting filename dynamically
	if [ -d $dir ]; then																															#checking if directory exists

		if [ -L $dir ]; then																														#Checking if directory is a symbolic link
			temp=$(readlink -f $dir)
			printf "%b\nThe directory is a symbolic link. Do you want to backup the origial folder ";  readlink -f $dir; printf " (Y/N)?"		#Getting full directory
			read -r answer
			if [ $answer == "y" ] || [ $answer = "Y" ]; then
				printf "%b\nDoing backup of $filename, stored at $directory"
				tar -chpzf $directory/$filename $directoryName															#compressing a making backup file

				logFunc "LOGGING" "Done a backup of a symbolic links original folder at $temp, stored at $directory"

			fi

		else
			temp=$(readlink -f $dir)
			printf "%b\n\n\nDo you want to backup ";  readlink -f $dir; printf " (Y/N)?"	#Getting full directory
			read -r answer
			if [ $answer = "y" -o $answer = "Y" ]; then
				printf "%b\nDoing backup of $filename, stored at $directory"
				tar -cpzf $directory/$filename $directoryName																#compressing a making backup file

				logFunc "LOGGING" "Done a backup of $temp, stored at $directory"

			fi
		fi
	else
			printf "%b\n\nCould not fin specified directory"
			temp=$(readlink -f $dir)																											#Getting full directory
			logFunc "ERROR" "Tried to backup $temp, but could not find directory and not backup was made"

			sleep 2
	fi
}

menu2 ()			#Menu 2 - plan backups with cron
{
	clear
	printf "%b\nMenu 2 - Plan a backup later today"
	printf "%b\n\nPath of the directory you want to backup: "
	read -r dir

	if [ -d $dir ]; then																															#checking if directory exists
		printf "%b\nTime of the planned backup (00:00-23:59): "
		read -r Time
		while :; do																																			#making sure that the time is entered within it limits and on the right format
		  if [[ $Time =~ ^([0-9]{2}):([0-9]{2})$ ]]; then
		    if (( BASH_REMATCH[2] < 60 ))\
		       && (( BASH_REMATCH[1] < 24 )); then
		       break
		    fi
		  fi
			printf "%b\nWrong format. Please use the HH:MM format: "
		  read -r Time

			logFunc "ERROR" "User entered an invalid time of or the wrong format, asked user to reenter time"
		done

		hour=${Time%:*};
		minute=${Time#*:};

		if [ -L $dir ]; then																														#checking if directory is a symbolic link
			printf "%b\n\tThe directory is a symbolic link. Do you want to backup the origial folder readlink -f $dir (Y/N)?"
			read -r answer
			if [ $answer == "y" ] || [ $answer = "Y" ]; then

				printf "%b\n\nThe backup will run at $Time. Do you want to add the planned backup (Y/N)?"
				if [ "$answer" == "y" ] || [ $answer = "Y" ]; then
					homeDir="$( realpath $HOME )";

					cronLine="$hour $minute"																									#setting together the line that will be entered into cron
					cronLine="$cronLine * * * "
					cronLine="$cronLine $home"
					cronFile="backupPlanned$hour$minute.sh"

					baseName=$( basename "$dir" )																							#getting basename
					directoryName=$HOME/$baseName
					filename="\$directoryName-dateOfBackup.tar.gz"

					printf "%b\nAdding backup of $filename, stored at $directory to cron with execution time $Time"

					printf "#!/bin/bash%b\n" >> $directory/$cronFile													#making .sh for cron to execute at a later time
					printf filename="$baseName-\$(date \"+%%y%%m%%d\".tar.gz)" >> $directory/$cronFile
					printf "%b\ntar -cpzf $directory/\$filename $directoryName" >> $directory/$cronFile

					chmod 711 $directory/$cronFile																						#setting execution rights to .sh

					(crontab -l 2>/dev/null printf "$cronLine")																#adding task to crontab

					logFunc "LOGGING" "User added a planned backup of a symbolic link at $hour:$minute of $directoryName stored at $directory"
				fi
			fi

		else
			printf "%b\n\nThe backup will run at $Time. Do you want to add the planned backup (Y/N)?"
			read -r answer
			if [ "$answer" == "y" ] || [ $answer = "Y" ]; then
				cronFile="backupPlanned$hour$minute.sh"
				cronLine="$hour $minute"																									#setting together the line that will be entered into cron
				cronLine="$cronLine * * * "
				cronLine="$cronLine $directory/$cronFile"
				user=$(id -un)

				baseName=$( basename "$dir" )																							#getting basename
				directoryName=$HOME/$baseName
				filename="\$directoryName-dateOfBackup.tar.gz"

				printf "%b\nAdding backup of $filename, stored at $directory to cron with execution time $Time"

				printf "#!/bin/bash%b\n" >> $directory/$cronFile													#making .sh for cron to execute at a later time
				printf filename="$baseName-\$(date \"+%%y%%m%%d\".tar.gz)" >> $directory/$cronFile
				printf "%b\ntar -cpzf $directory/\$filename $directoryName" >> $directory/$cronFile

				chmod 711 $directory/$cronFile																						#setting execution rights to .sh
				echo -e "\n\n$cronLine\n\n"
				(crontab -u $user -l; echo "$cronLine") | crontab -u $user -
				#(crontab -l 2>/dev/null printf "$cronLine") | 																#adding task to crontab

				logFunc "LOGGING" "User added a planned backup at $hour:$minute of $directoryName stored at $directory"
			fi
		fi
	else
		printf "%b\n\nDirectory not found. Please enter an actual directory"
		logFunc "ERROR" "User entered a non-existent directory"
		sleep 2
	fi
}

menu3 ()			#Menu 3 - restore a previous backup
{
	if [ "$(ls -A $directory)" ]; then																								#checks if it exists any backups in the backup folder
		printf "%b\n\n"

		ls -1 $directory																																#displays the contents of the backup directory
		printf "%b\n\nChoose backup you want to restore: "
		read -r backup

		fileDirectory="$directory/$backup"
		currentDirectory=$( pwd )

		if [ -f $fileDirectory ]; then																									#if specified directory is found extraction	is done
			tar zxvf "$fileDirectory" -C "$currentDirectory"
			logFunc "LOGGING" "Extracting $fileDirectory to $currentDirectory"
		else
			printf "%b\n\nCould NOT find the backup you specified"
			logFunc "ERROR" "Could not find $fileDirectory"
			sleep 2
		fi

	else
		printf "%b\n\nCould not find any backups in the backup folder $directory"
		logFunc "ERROR" "Could not find any backups in $directory"
		sleep 2
	fi
}


if [ -f "$HOME/.backup.conf" ]; then
	directory=$( head -1 $HOME/.backup.conf)
	printf  "%b\n\n\n\nReading from file"

 elif [ -d "$HOME/backups" ]; then
		directory=$HOME/backups
		printf "$HOME/backups" >> $directory/.backup.conf
		printf  "%b\n\n\n\nReading from file"
		logFunc "LOGGING" "Found backup folder at $HOME/backups and made a backup.conf"

 elif [ -d "/backups" ]; then
		directory="/backups"
		printf "backups" >> $directory/.backup.conf
		printf "%b\n\n\n\nReading from file"
		logFunc "LOGGING" "Found backup folder at /backups and made a backup.conf"

 else
	  haveDirectory=false
		printf "%b\n\n\nCould not find an existing backup folder.
				\nPlease choose either
					\n\t(1) /backups (NEED ROOT PRIVILEGES, will NOT run unless you ran the script as SU or SUDO) or
					\n\t(2) $HOME/backups or
					\n\tchoose your own directory.
					\n\nDirectory: "
		while [ $haveDirectory == false ];  do
			read -r directory
			case $directory in
				1)	mkdir /backups
					printf "/backups" >> $directory/.backup.conf
					haveDirectory=true
					logFunc "LOGGING" "Did not find a previous backup folder or config, user chose a new backup folder at /backups and created the backup.conf at $directory/.backup.conf" ;;
				2)	mkdir $HOME/backups
					printf "$HOME/backups" >> $directory/.backup.conf
					haveDirectory=true
					logFunc "LOGGING" "Did not find a previous backup folder or config, user chose a new backup folder at $HOME/backups and created the backup.conf at $directory/.backup.conf" ;;
				*)	haveDirectory=false
						if [ -d "$directory" ]; then
							mkdir $directory
							printf "$directory" >> $directory/.backup.conf
							haveDirectory=true
							logFunc "LOGGING" "Did not find a previous backup folder or config, user chose a new backup folder at $directory and created the backup.conf at $directory/.backup.conf"
						else
							directory="$( readlink -f $directory )"
							printf "%b\nCould not find the directory, make a new one (Y/N)?"
							read -r answer
							if [ $answer = "y" -o $answer = "Y" ]; then
								mkdir $directory
								printf "$directory" >> $directory/.backup.conf
								haveDirectory=true
								logFunc "LOGGING" "Could not find the directory the user provided, a new directory was made at $directory"
							else
								printf "%b\n\n\nDid not make a new directory. \nPlease enter directory again: "
								logFunc "ERROR" "Could not find provided directory, user choose to not create a new directory"
							fi
						fi ;;
			esac
		done
fi


logFunc () {
	DATE=$(date "+%F \t %T %z")
	printf "%b\n$DATE \t $1 \t $2" >> $LOG
}


LOG=$directory/backup.log
logFunc "LOGGING" "Backup and config directory set at initial load at $directory"
clear

sleep 1
clear
printf "ASO 2017-2018"
 printf "%b\nMartin Kvalvag"
 printf "%b\nBackup tool for directiories"
 printf "%b\n----------------------------"

until [ $menu == 4 ] ; do
	printf "%b\n\n   Menu"
	printf "%b\n\t1) Immediate backup"
	printf "%b\n\t2) Program a backup with cron"
	printf "%b\n\t3) Restore content of a backup"
	printf "%b\n\t4) Exit"
	printf "%b\n\n     Option: "

	read -r menu
	case $menu in
		1)	menu1 ; sleep 1;;
		2)	menu2 ; sleep 1;;
		3)	menu3 ; sleep 1;;
		4)	printf "%b\nExiting" ;;
	esac
	sleep 1
	clear
done

#!/bin/bash
#set -eo pipefail # Fail fast 

# Setup Details
# Setup users for backup
# Setup GPG Key
# Setup Backup Directory
## sudo mkdir -p /var/backups/mongodb
## chown mbackup:mbackup /var/backups/mongodb
## or whatever user plan to use for backups
# Desing notes
## using a combination of piped commands to reduce unencrypted files and reduce disk space usage etc. 

# TODO
# Add List option
# Add option to make output quiet

# Set defaults for variables that can be overidden on config file or command line options
DBHOST="127.0.0.1"

# Port that mongo is listening on
DBPORT="27017"

# Backup directory location e.g /backups
BACKUPDIR="/var/backups/mongodb"

# PATH to MONGO UTILS
MONGOPATH="/usr/bin/"

# To use a config file to set options
# Create a file "/etc/[default|sysconfig]/mbackup (use the relevant path for distro)
# Uncomment option to set for automated uses
#DBHOST="127.0.0.1"
#DBPORT="27017"
#BACKUPDIR="/var/backups/mongodb"
#DBNAME=""
#COLLECTION=""
#DBUSERNAME=""
#DBAUTHDB=""
#PREFIX="" # Prefix to use to label backup files
#DBPASSWORD=""
#DBAUTHDB="admin"
#PREFIX=""

# Add a verbose option but set default to quiet .
# Add a comment to say backingup please wait ...
# Add GPGIDENTITY
# USE PASWORD from file


for x in default sysconfig; do
  if [ -f "/etc/$x/mbackup" ]; then
    source /etc/$x/mbackup
  fi
done


while test $# -gt 0; do
  case "$1" in
    -dbhost)
      shift
      DBHOST=$1
      shift
      ;;
    -dbport)
      shift
      DBPORT=$1
      shift
      ;;
    -database)
      shift
      DBNAME=$1
      shift
      ;;
    -collection)
      shift
      COLLECTION=$1
      shift
      ;;
    -dbuser)
      shift
      DBUSERNAME=$1
      shift
      ;;
    -dbauthdb)
      shift
      DBAUTHDB=$1
      shift
      ;;
    -prefix)
      shift
      PREFIX=$1
      shift
      ;;
    -mongopath)
      shift
      MONGOPATH=$1
      shift
      ;;
    *)
      echo "$1 is not a recognized flag!"
      # Could add usage here
      exit 1;
      ;;
  esac
done

# using simple fall-through process to construct options to run Mongo Backup

# Do we need to use a username/password?
if [ "$DBUSERNAME" ]; then
    #OPT="$OPT --username=$DBUSERNAME --password=$DBPASSWORD"
    OPT="$OPT --username=$DBUSERNAME" # Should ask for password
    # Should have a way to pull this from a more secure file.
    if [ "DBAUTHDB" ]; then
        OPT="$OPT --authenticationDatabase=$DBAUTHDB"
    fi
fi

if [ "${PREFIX}" ] ; then 
  BACKUPFILE="${PREFIX}-${DBHOST}"
else
  BACKUPFILE="${DBHOST}"
fi

# Do we need to backup only a specific database?
if [ "$DBNAME" ]; then
  OPT="$OPT -d $DBNAME"
  BACKUPFILE="${BACKUPFILE}-${DBNAME}"
fi

# Do we need to backup only a specific collection?
if [ "$COLLECTION" ]; then
  OPT="$OPT --collection $COLLECTION"
  BACKUPFILE="${BACKUPFILE}-${COLLECTION}"
fi


# add hostname to backup file name?


# Check required directories
if [ ! -d "${BACKUPDIR}" ] ; then
  echo "${BACKUPDIR} does not exist.  Please please create the directory with write permissions for user $(whoami)before proceeding"
  exit 1
fi 

if [ ! -w "${BACKUPDIR}" ]; then 
	echo "${BACKUPDIR} is not writable by $(whoami). Please please create the directory with write permissions for user $(whoami) before proceeding" 
  exit 1 
fi 

echo "will run mongodump -h ${DBHOST}:${DBPORT} ${OPT} --gzip --archive | gpg --encrypt -r 'mbackup@auth0exercise.com' ${FULLFILEPATH}"



echo
echo "Backup of Database Server - $HOST on $DBHOST"
echo ======================================================================

echo "Backup Start $(date)"
echo ======================================================================

FULLFILEPATH="${BACKUPDIR}/${BACKUPFILE}-`date +%Y-%m-%d-%H-%M-%S`.gpg"

${MONGOPATH}/mongodump -h ${DBHOST}:${DBPORT} ${OPT} --gzip --archive | gpg --encrypt -r 'mbackup@auth0exercise.com' -o ${FULLFILEPATH}.processing
#SUCCESS="$?"
# Maybe set this as a SUCCESS and if not remove failed files
#echo "Success is $SUCCESS"
#if [ ${SUCCESS} -eq 0 ] ; then 
#  mv ${FULLFILEPATH}.processing ${FULLFILEPATH}
#  echo "${FULLFILEPATH} was backed up"
#else 
#  echo "There as a problem with the backup"
#  # Uncomment this is want to remove failed backup files
#  echo "Removing failed backup attempt file ${FULLFILEPATH}"
#  rm ${FULLFILEPATH}.processing
#fi

# Clean up
# remove any leftover processing files if something went wrong.
if [ -f ${FULLFILEPATH}.processing ] ; then 
  echo "Removing leftover processing file ${FULLFILEPATH}.processing"
  rm ${FULLFILEPATH}.processing
fi

#consider removing failed attempts.




# References
# https://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash
# https://google.github.io/styleguide/shellguide.html
# https://severalnines.com/database-blog/database-backup-encryption-best-practices
# https://severalnines.com/database-blog/tips-storing-mongodb-backups-cloud

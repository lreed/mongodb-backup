#!/bin/bash
set -eo pipefail # Fail fast 

# Setup Details
# Setup users for backup
# Setup GPG Key
# Setup Backup Directory
## sudo mkdir -p /var/backups/mongodb
## chown mbackup:mbackup /var/backups/mongodb
# Desing notes
## using a combination of piped commands to reduce unencrypted files and reduce disk space usage etc. 

# TODO
# Add List option
# Add option to make output quiet

# Set defaults
DBHOST="127.0.0.1"

# Port that mongo is listening on
DBPORT="27017"

# Backup directory location e.g /backups
BACKUPDIR="/var/backups/mongodb"


# Should really do this
# also need to have a way to use a secure file for dbpassword 
# could also add the code here to pull configs from a config file
# External config - override default values set above
for x in default sysconfig; do
  if [ -f "/etc/$x/automongobackup" ]; then
    # shellcheck source=/dev/null
    source /etc/$x/automongobackup
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
    *)
      echo "$1 is not a recognized flag!"
      # Could add usage here
      exit 1;
      ;;
  esac
done

# Could add option to create direcotry if it does not exist - or not..

# Use conditioanls to construct the query to use based on what options exist

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

echo "will run mongodump -h ${DBHOST}:${DBPORT} ${OPT} --gzip --archive | gpg --encrypt -r 'mbackup@auth0exercise.com' -o ${BACKUPFILE}-`date +%Y-%m-%d-%H-%M-%S`.gpg"



echo
echo "Backup of Database Server - $HOST on $DBHOST"
echo ======================================================================

echo "Backup Start $(date)"
echo ======================================================================

FULLFILEPATH="${BACKUPDIR}/${BACKUPFILE}-`date +%Y-%m-%d-%H-%M-%S`.gpg"

mongodump -h ${DBHOST}:${DBPORT} ${OPT} --gzip --archive | gpg --encrypt -r 'mbackup@auth0exercise.com' -o ${FULLFILEPATH} 

if [ $? -eq 0 ] ; then 
  echo "${FULLFILEPATH} was backed up"
else 
  echo "There as a problem with the backup"
fi

#mongodump -h 192.168.1.198 --authenticationDatabase "admin" --username=druser --db=exercise --collection=answers --gzip --archive | gpg --encrypt -r 'mbackup@auth0exercise.com' -o mongobackup-`date +%Y-%m-%d-%H-%M-%S`.gpg


#consider removing failed attempts.




# References
# https://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash
# https://google.github.io/styleguide/shellguide.html
# https://severalnines.com/database-blog/database-backup-encryption-best-practices
# https://severalnines.com/database-blog/tips-storing-mongodb-backups-cloud

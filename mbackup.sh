#!/bin/bash

# Setup Details
# Setup users for backup
# Setup GPG Key
# Setup Backup Directory
## sudo mkdir -p /var/backups/mongodb
## chown mbackup:mbackup /var/backups/mongodb
## or whatever user plan to use for backups
# Design notes
## using a combination of piped commands to reduce unencrypted files and reduce disk space usage etc. 

# TODO
# Add List option
# Add option to make output quiet
# Add option to input the -r identity of the GPG setup.... 

# Set default behavior of script to perform backups
BACKUP="true"

# Set defaults for variables that can be overridden on config file or command line options
DBHOST="127.0.0.1"

# Port that mongo is listening on
DBPORT="27017"

# Backup directory location e.g /backups
BACKUPDIR="/var/backups/mongodb"

# PATH to MONGO UTILS
MONGOPATH="/usr/bin"



# To use a config file to set options
# Create a file "/etc/[default|sysconfig]/mbackup (use the relevant path for distro)
# Uncomment and set option to use for automated uses
#BACKUP="true"
#DBHOST="127.0.0.1"
#DBPORT="27017"
#BACKUPDIR="/var/backups/mongodb"
#DBNAME=""
#COLLECTION=""
#DBUSERNAME=""
#DBAUTHDB=""
#PREFIX="" # Prefix to use to label backup files
#DBPASSWORD=""
#DBPASSFILE=""
#DBAUTHDB="admin"
#PREFIX=""

# Add a verbose option but set default to quiet .
# Add a comment to say backing up please wait ...
# Add GPGIDENTITY


for x in default sysconfig; do
  if [ -f "/etc/$x/mbackup" ]; then
    echo "NOTICE: Using parameters from config file /etc/$x/mbackup"
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
    -dbpassword)
      shift
      DBPASSWORD=$1
      shift
      ;;
    -dbpassfile)
      shift
      DBPASSFILE="${1}"
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
    -b | -backup )
      shift
      BACKUP="true"
      shift
      ;;
    -r | -restore )
      shift
      BACKUP="true"
      shift
      ;;
    *)
      echo "$1 is not a recognized flag!"
      # Could add usage here
      exit 1;
      ;;
  esac
done


backup () {
  # using simple fall-through process to construct options to run MongoDB Backup

  # Check required directories
  if [ ! -d "${BACKUPDIR}" ] ; then
    echo "${BACKUPDIR} does not exist.  Please please create the directory with write permissions for user $(whoami) before proceeding"
    exit 1
  fi

  if [ ! -w "${BACKUPDIR}" ]; then
    echo "${BACKUPDIR} is not writable by $(whoami). Please please create the directory with write permissions for user $(whoami) before proceeding"
    exit 1
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
  if [ "${COLLECTION}" ]; then
    OPT="${OPT} --collection ${COLLECTION}"
    BACKUPFILE="${BACKUPFILE}-${COLLECTION}"
  fi


  # Do we need to use a username/password?
  if [ "${DBUSERNAME}" ]; then
    # Set Username for Database Backups
    OPT="$OPT --username=$DBUSERNAME" # Should ask for password on command line in this case

    # Set DB to use for Credentials in Mongo
    if [ "${DBAUTHDB}" ]; then
        OPT="$OPT --authenticationDatabase=$DBAUTHDB"
    fi

    # Should have a way to pull this from a more secure file.
    # Use Full PATH for file
    # This should be the last options added before the pipe to gpg

    # Supply password for Database Backups
    # Use a command line password first if given
    if [ "${DBPASSWORD}" ] ; then 
      # Use a command line password first if given
      OPT="${OPT} -p ${DBPASSWORD}"
    else
      # Use a password supplied in a (secure?) file
      # This could be done better
      if [ "${DBPASSFILE}" ]; then
        if [ -s ${DBPASSFILE} ] ; then
          echo "NOTICE: Using contents of ${DBPASSFILE} for password for Backup"
          # Can't figure out the correct way to pass OPTS with "<" so will deal at execution time
	  #OPT="${OPT} < ${DBPASSFILE}"
	  use_dbpassfile="true"
        fi
      fi
    fi
  fi

  echo
  echo "Backup of Database Server - $HOST on $DBHOST"
  echo ======================================================================
  # Grab a timestamp to use as the start of backup operations
  echo "Backup Start $(date)"
  echo ======================================================================

  FULLFILEPATH="${BACKUPDIR}/${BACKUPFILE}-`date +%Y-%m-%d-%H-%M-%S`.gpg"

  # Call Mongodump with options
  # note the "--archive" allows output to be named and if not then goes to STDOUT so can pipe to gpg
  # Use Conditonal to deal with problems around file input for dbpassfile
  if [ ${use_dbpassfile} != "true" ] ; then
    echo "use_dbpassfile is ${use_dbpassfile}"
    ${MONGOPATH}/mongodump --host ${DBHOST}:${DBPORT} --gzip --archive $OPT | gpg --encrypt -r 'mbackup@auth0exercise.com' -o ${FULLFILEPATH}.processing
  else 
  ${MONGOPATH}/mongodump --host ${DBHOST}:${DBPORT} --gzip --archive ${OPT} < ${DBPASSFILE} | gpg --encrypt -r 'mbackup@auth0exercise.com' -o ${FULLFILEPATH}.processing
  fi

}

  clean_up () {
  # Clean up
  # remove any leftover processing files if something went wrong.
  if [ -f ${FULLFILEPATH}.processing ] ; then 
    echo "Removing leftover processing file ${FULLFILEPATH}.processing"
    rm ${FULLFILEPATH}.processing
  fi
}

# Main
if [ "${BACKUP}" ]; then
  backup
  clean_up
fi 

# If restore do restore
# restore



# Future improvements
# Add options for SSL connections
# Consider adding a simple way to include ad-hoc options on the command line instead of predefining every option. 
# Add loging options
# add options to include replicate sets etc.  "--oplog"

# References
# https://stackoverflow.com/questions/7069682/how-to-get-arguments-with-flags-in-bash
# https://google.github.io/styleguide/shellguide.html
# https://severalnines.com/database-blog/database-backup-encryption-best-practices
# https://severalnines.com/database-blog/tips-storing-mongodb-backups-cloud
# https://github.com/micahwedemeyer/automongobackup/blob/master/src/automongobackup.sh

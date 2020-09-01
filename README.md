# mongodb-backup
MongoDB backup 
./mbackup.sh  -dbhost HOSTNAME/IP -prefix PREFIX -dbuser DBUSER -database DBNAME -dbauthdb DBAUTH -collection COLLECTION


Setup Notes:

#On MongoDB host
Create user for Backup and Restores (druser)

e.g.
> db.createUser(
    {
      user: "druser",
      pwd:  passwordPrompt(),
      roles: [ { role: "backup", db: "admin" },
               { role: "restore", db: "admin" } ]
    }
  )

Creates druser / druser (Disaster Recover user for Backups and restores using Built-in roles)


# Setup User and GPG for doing the backups 

Create a user “mbackup” that will hold the GPG setup and manage the MongoDB Backups

$ sudo adduser  --gecos "MongoDB Backup User" mbackup

Create GPG keys / setup

Set the tty to the mbackup user (otherwise GPG key will break)

$ ls -ltr $(tty)
crw--w---- 1 ubuntu tty 136, 0 Aug 31 05:31 /dev/pts/0

$ sudo chown mbackup $(tty)
$ ls -ltr $(tty)
crw--w---- 1 mbackup tty 136, 0 Aug 31 05:32 /dev/pts/0

Run GPG Key Generation
(Install GPG v2.X+ if not already installed)

Become the mbackup user 
$ sudo su - mbackup

mbackup@ip-10-0-0-211:~$ gpg --full-generate-key
gpg (GnuPG) 2.2.4; Copyright (C) 2017 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

gpg: directory '/home/mbackup/.gnupg' created
gpg: keybox '/home/mbackup/.gnupg/pubring.kbx' created
Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection? 1
RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (3072) 
Requested keysize is 3072 bits
Please specify how long the key should be valid.
         0 = key does not expire
      <n>  = key expires in n days
      <n>w = key expires in n weeks
      <n>m = key expires in n months
      <n>y = key expires in n years
Key is valid for? (0) 1y
Key expires at Tue Aug 31 05:37:02 2021 UTC
Is this correct? (y/N) y

GnuPG needs to construct a user ID to identify your key.

Real name: Mongo Backup Key
Email address: mbackup@example.com
Comment: Mongo Backup Key
You selected this USER-ID:
    "Mongo Backup Key (Mongo Backup Key) <mbackup@example.com>"

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
gpg: /home/mbackup/.gnupg/trustdb.gpg: trustdb created
gpg: key 17E317AC8F549445 marked as ultimately trusted
gpg: directory '/home/mbackup/.gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as '/home/mbackup/.gnupg/openpgp-revocs.d/A48922F06E95061E2EDB46B517E317AC8F549445.rev'
public and secret key created and signed.

pub   rsa3072 2020-08-31 [SC] [expires: 2021-08-31]
      A48922F06E95061E2EDB46B517E317AC8F549445
uid                      Mongo Backup Key (Mongo Backup Key) <mbackup@example.com>
sub   rsa3072 2020-08-31 [E] [expires: 2021-08-31]

Set tty back to ubuntu user (or just log off and back on)

sudo chown ubuntu $(tty)

Setup Script Environment

Scp script file to target host, place in mbackup home directory, change ownership to mbackup user (or use tar ball or git clone etc.)

$ sudo chown mbackup:mbackup /home/mbackup/mbackup.sh 
$ sudo ls -ltr /home/mbackup/
total 8
-rwxr-xr-x 1 mbackup mbackup 7428 Aug 31 05:51 mbackup.sh

Create Backup file location

$ sudo mkdir -p /var/backups/mongodb
$ sudo chown mbackup:mbackup /var/backups/mongodb

Create config file
Copy details from example in the mbackup.sh script

$ sudo vim /etc/default/mbackup

# Uncomment and modify options to set for automated uses
#OPERATION="backup"
#DBHOST="127.0.0.1"
#DBPORT="27017"
#BACKUPDIR="/var/backups/mongodb"
#DBNAME=""
#COLLECTION=""
#DBUSERNAME=""
#DBAUTHDB=""
#PREFIX="" # Prefix to use to label backup files
#DBPASSWORD=""
#DBPASSFILE="/home/mbackup/dbpassfile"
#DBAUTHDB="admin"
#PREFIX=""
#GPGRECIPIENT=""

Set the GPGRECIPIENT so can use Encryption
(was created in earlier GPG setup steps)

GPGRECIPIENT="mbackup@example.com"

Become the mbackup user

$ sudo su - mbackup 

Create the dbpassfile file to store the MongoDB password for Backup User (druser)

$ vim ~/dbpassfile
druser

$ chmod 0600 ~/dbpassfile
$ ls -l ~/dbpassfile
-rw------- 1 mbackup mbackup 7 Aug 31 06:02 /home/mbackup/dbpassfile

Run a List option to check that defaults are working.

$ ./mbackup.sh -l 
Backup files currently in /var/backups/mongodb

Perform Backups

Create both a Backup of Database and a Collection

Set /etc/hosts entry for the remote DB host if not in DNS.
$ cat /etc/hosts |  grep remotedbhost
10.0.0.50 remotedbhost

Use mbackup script and specify options :
$ ./mbackup.sh --backup -dbhost remotedbhost -prefix mbackup -dbuser druser -database exercise -dbauthdb admin

NOTICE: Using parameters from config file /etc/default/mbackup

Backup of Database Server -  on remotedbhost
======================================================================
Backup Start 2020-09-01-20-14-18
======================================================================
Enter password:

2020-09-01T20:14:25.200+0000	writing exercise.answers to archive on stdout
2020-09-01T20:14:27.048+0000	[........................]  exercise.answers  45593/2014516  (2.3%)
{...}
2020-09-01T20:16:22.906+0000	[########################]  exercise.answers  2014516/2014516  (100.0%)
2020-09-01T20:16:23.550+0000	done dumping exercise.answers (2014516 documents)
/var/backups/mongodb/mbackup-remotedbhost-db_exercise-2020-09-01-20-14-18.gz.gpg was successfully created

Collection 
$ ./mbackup.sh --backup -dbhost remotedbhost -prefix mbackup -dbuser druser -database exercise -dbauthdb admin -collection answers 
NOTICE: Using parameters from config file /etc/default/mbackup

Backup of Database Server -  on remotedbhost
======================================================================
Backup Start 2020-09-01-20-17-19
======================================================================
Enter password:
2020-09-01T20:17:22.500+0000	writing exercise.answers to archive on stdout
2020-09-01T20:17:22.788+0000	[........................]  exercise.answers  22985/2014516  (1.1%)
{...}
2020-09-01T20:19:20.579+0000	[########################]  exercise.answers  2014516/2014516  (100.0%)
2020-09-01T20:19:21.217+0000	done dumping exercise.answers (2014516 documents)
/var/backups/mongodb/mbackup-remotedbhost-db_exercise-col_answers-2020-09-01-20-17-19.gz.gpg was successfully created

List the files using mbackup script

./mbackup.sh -l 
NOTICE: Using parameters from config file /etc/default/mbackup
Backup files currently in /var/backups/mongodb
mbackup-remotedbhost-db_exercise-col_answers-2020-09-01-20-17-19.gz.gpg
mbackup-remotedbhost-db_exercise-2020-09-01-20-14-18.gz.gpg

Test restore

Confirm mongodb has databases and collections with data:

Log into the remote db host 
$ ps -eaf | grep [m]ongod 
mongodb  16719     1  0 Aug26 ?        00:32:22 /usr/bin/mongod --config /etc/mongod.conf

Check the mongo shell
(admin / admin )

$ mongo  --authenticationDatabase "admin" -u "admin" -p
MongoDB shell version v4.4.0
Enter password: 
connecting to: mongodb://127.0.0.1:27017/?authSource=admin&compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("4c2fc50f-7cc2-4eea-a6c3-268a5f4353f1") }
MongoDB server version: 4.4.0
> 

> show dbs
admin     0.000GB
config    0.000GB
exercise  0.917GB
local     0.000GB
> use exercise
switched to db exercise
> db
exercise
> db.answers.find({Id:1185})
{ "_id" : ObjectId("5f46a49b43fbe85d62748250"), "Id" : 1185, "OwnerUserId" : 60, "CreationDate" : "2008-08-04T12:28:03Z", "ParentId" : 1180, "Score" : 1, "Body" : "<p>The trick to that is to use URL rewriting so that <strong>name.domain.com</strong> transparently maps to something like <strong>domain.com/users/name</strong> on your server.  Once you start down that path, it's fairly trivial to implement.</p>" }
> 


Drop the Database

> db.dropDatabase()
{ "dropped" : "exercise", "ok" : 1 }
> db.answers.find({Id:1185})
> show dbs
admin   0.000GB
config  0.000GB
local   0.000GB
> 


Restore database

On host running mbackup (not Mongohost) 
As mbackup user
Look for backup files 

$ ./mbackup.sh -l 
NOTICE: Using parameters from config file /etc/default/mbackup
Backup files currently in /var/backups/mongodb
mbackup-remotedbhost-db_exercise-col_answers-2020-09-01-20-17-19.gz.gpg
mbackup-remotedbhost-db_exercise-2020-09-01-20-14-18.gz.gpg

Use the file for the Database not the collection
mbackup-remotedbhost-db_exercise-2020-09-01-20-14-18.gz.gpg

Decrypt the file:
Assuming in mbackup user home directory for now

 mbackup@ip-10-0-0-211:~$ ls -lh decrypted_mongo_database.gz 
-rw-rw-r-- 1 mbackup mbackup 556M Sep  1 20:46 decrypted_mongo_database.gz

Do Restore

mbackup@ip-10-0-0-211:~$ mongorestore --host remotedbhost --username=druser --authenticationDatabase=admin  --gzip --archive=./decrypted_mongo_database.gz
Enter password:

2020-09-01T20:49:09.429+0000	preparing collections to restore from
2020-09-01T20:49:09.446+0000	reading metadata for exercise.answers from archive './decrypted_mongo_database.gz'
2020-09-01T20:49:09.459+0000	restoring exercise.answers from archive './decrypted_mongo_database.gz'
2020-09-01T20:49:12.406+0000	exercise.answers  76.6MB
2020-09-01T20:49:15.406+0000	exercise.answers  155MB
{...}
2020-09-01T20:50:12.098+0000	finished restoring exercise.answers (2014516 documents, 0 failures)
2020-09-01T20:50:12.098+0000	2014516 document(s) restored successfully. 0 document(s) failed to restore.

Check database

(on Mongdb host)

Mongo shell
> show dbs
admin     0.000GB
config    0.000GB
exercise  0.917GB
local     0.000GB

> use exercise 
switched to db exercise
> db.answers.find({Id:1185})
{ "_id" : ObjectId("5f46a49b43fbe85d62748250"), "Id" : 1185, "OwnerUserId" : 60, "CreationDate" : "2008-08-04T12:28:03Z", "ParentId" : 1180, "Score" : 1, "Body" : "<p>The trick to that is to use URL rewriting so that <strong>name.domain.com</strong> transparently maps to something like <strong>domain.com/users/name</strong> on your server.  Once you start down that path, it's fairly trivial to implement.</p>" }
> 

Repeat for collection instead of entire database:

Drop collection answers

> show collections 
answers
> db.answers.drop()
true
> show collections
> show dbs
admin   0.000GB
config  0.000GB
local   0.000GB
> 

Restore from collection Backup 

On mbackup host and user 

mbackup@ip-10-0-0-211:~$ ./mbackup.sh -l 
NOTICE: Using parameters from config file /etc/default/mbackup
Backup files currently in /var/backups/mongodb
mbackup-remotedbhost-db_exercise-col_answers-2020-09-01-20-17-19.gz.gpg
mbackup-remotedbhost-db_exercise-2020-09-01-20-14-18.gz.gpg
Use the collection backup file
 mbackup-remotedbhost-db_exercise-col_answers-2020-09-01-20-17-19.gz.gpg

Decrypt:

mbackup@ip-10-0-0-211:~$ gpg --decrypt --pinentry-mode loopback --output decrypted_mongo_collection.gz /var/backups/mongodb/mbackup-remotedbhost-db_exercise-col_answers-2020-09-01-20-17-19.gz.gpg 
gpg: encrypted with 3072-bit RSA key, ID 168408887D9BA77D, created 2020-08-31
      "Mongo Backup Key (Mongo Backup Key) <mbackup@auth0exercise.com>"
mbackup@ip-10-0-0-211:~$ ls -lh decrypted_mongo_collection.gz 
-rw-rw-r-- 1 mbackup mbackup 556M Sep  1 20:58 decrypted_mongo_collection.gz

Restore:

mbackup@ip-10-0-0-211:~$ mongorestore --host remotedbhost --username=druser --authenticationDatabase=admin  --gzip --archive=./decrypted_mongo_collection.gz
Enter password:

2020-09-01T20:59:11.779+0000	preparing collections to restore from
2020-09-01T20:59:11.797+0000	reading metadata for exercise.answers from archive './decrypted_mongo_collection.gz'
2020-09-01T20:59:11.809+0000	restoring exercise.answers from archive './decrypted_mongo_collection.gz'
2020-09-01T20:59:14.762+0000	exercise.answers  76.0MB
{...}
2020-09-01T21:00:14.517+0000	finished restoring exercise.answers (2014516 documents, 0 failures)
2020-09-01T21:00:14.517+0000	2014516 document(s) restored successfully. 0 document(s) failed to restore.

Check mongodb on the db host

 > show dbs
admin     0.000GB
config    0.000GB
exercise  0.918GB
local     0.000GB
> use exercise
switched to db exercise
> show collections 
answers
> db.answers.find({Id:1185})
{ "_id" : ObjectId("5f46a49b43fbe85d62748250"), "Id" : 1185, "OwnerUserId" : 60, "CreationDate" : "2008-08-04T12:28:03Z", "ParentId" : 1180, "Score" : 1, "Body" : "<p>The trick to that is to use URL rewriting so that <strong>name.domain.com</strong> transparently maps to something like <strong>domain.com/users/name</strong> on your server.  Once you start down that path, it's fairly trivial to implement.</p>" }
> 

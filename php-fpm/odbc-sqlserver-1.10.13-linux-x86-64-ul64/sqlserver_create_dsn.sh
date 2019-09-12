#!/bin/sh
#
#  Copyright (c) 1999-2015 Easysoft Ltd. All rights reserved.
#
if [ "$ECHO" = "" ];then
  echo "error - ECHO not defined, expect it to be exported"
  exit 2
fi
if [ "$TESTEXISTS" = "" ];then
  echo "error - TESTEXISTS not defined, expect it to be exported"
  exit 2
fi
#
# Check for stty
#
stty 1>/dev/null 2>/dev/null
if [ $? -eq 0 ];then
  ECHOOFF="stty -echo"
  ECHOON="stty echo"
else
  ECHOOFF=""
  ECHOON=""
fi
#
if [ $# -ne 2 ];then
  cmdlinestr="incorrect number of parameters"
  cmdline_error=1
else
  INSTALLPATH=$1
  UNIXODBCFILE=$2
fi
#
# If command line error
#
if [ "$cmdline_error" = "1" ];then
  $ECHO "\"$*\""
  $ECHO "Invalid command line, $cmdlinestr"
  $ECHO "Usage:"
  $ECHO "sqlserver_create_dsn install_path uodbc_file"
  exit 1
fi
#
# test if the SHELL handles -r
THISSHELL=/bin/sh
$ECHO "read -r result; echo \$result" > /tmp/esreadtest.sh
res=`$ECHO "hello" | $THISSHELL /tmp/esreadtest.sh 2>&1`
rm /tmp/esreadtest.sh
if [ x"$res" = "xhello" ]; then
    READR="-r"
else
    $ECHO "This shell doesn't allow escape characters, so if it is "
    $ECHO "necessary to use the '\' character when responding to "
    $ECHO "prompts, prefix with an additional '\' to escape the "
    $ECHO "character."
    $ECHO
    $ECHO "For example to connect to the instance MYINSTANCE"
    $ECHO "on the server MYSERVER, enter MYSERVER\\\\\\MYINSTANCE"
    $ECHO
    READR=" ";
    $ECHO "Any key to continue:\c"
    read answer
    $ECHO
fi
#
TDSHELPER="$INSTALLPATH/sqlserver/bin/tdshelper"
if [ ! -x "$TDSHELPER" ];then
  $ECHO "Cannot find executable $INSTALLPATH/sqlserver/bin/tdshelper"
  $ECHO "Aborting Easysoft ODBC-SQL Server DSN Creation"
  exit 1
fi
#
if [ ! "$TESTEXISTS" "$UNIXODBCFILE" ];then
  $ECHO "Cannot find $UNIXODBCFILE"
  $ECHO "Aborting Easysoft ODBC-SQL Server DSN Creation"
  exit 1
fi
UNIXODBCPATH=`cat $UNIXODBCFILE`
ODBCINST="$UNIXODBCPATH/bin/odbcinst"
if [ ! -x "$ODBCINST" ];then
  $ECHO "Cannot find an executable $ODBCINST"
  $ECHO "Aborting Easysoft ODBC-SQL Server DSN Creation"
  exit 1
fi
ISQL="$UNIXODBCPATH/bin/isql.sh"
if [ ! -x "$ISQL" ];then
  ISQL="$UNIXODBCPATH/bin/isql"
  if [ ! -x "$ISQL" ];then
    $ECHO "Cannot find an executable isql program"
    $ECHO "WARNING: This script will be unable to test the created DSN"
    ISQL=""
  fi
  LDPATHS="$UNIXODBCPATH/lib:$INSTALLPATH/lib"
  LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$LDPATHS"
  export LD_LIBRARY_PATH
  SHLIB_PATH="$SHLIB_PATH:$LDPATHS"
  export LIBPATH
  LIBPATH="$LIBPATH:$LDPATHS"
  export LIBPATH
  DYLD_LIBRARY_PAYH="$DYLD_LIBRARY_PATH:$LDPATHS"
  export DYLD_LIBRARY_PATH
fi
cat <<EOF
Test Connection to SQL Server
============================

If you currently have a SQL Server instance available on your network
this install can now interactively create a working DSN on this machine 
which will connect to it. However, you should make sure before you 
continue with this DSN creation:

o you know the name of the server that you wish to connect to.
o you know the instance or server port that you wish to connect to.
o you have available a username and password to logon to the instance.
o you know what language you wish to use (if not the default)
o you know what database you wish to use (if not the default)

You can elect to skip this process and create the DSN yourself afterwards -
this is not an essential part of the installation, it is just a script
to help you set up your first DSN and test it.

First we will attempt to see if there are any listening SQL Server instances 
on your network

EOF
$ECHO "Using $TDSHELPER -i -c 1"
$ECHO "===================================================================="
$TDSHELPER -i -c 1
$ECHO "===================================================================="
answer="hoho"
while [ \( "$answer" != "y" \) -a \( "$answer" != "n" \) ]
do
  $ECHO "Do you have a SQL Server installed we can access?\n(q=quit this step) [y] (y/n): \c"
  read answer
  if [ "$answer" = "" ];then
    answer="y"
  fi
  if [ \( "$answer" = "n" \) -o \( "$answer" = "q" \) ];then
    sysconfdir=`$ODBCINST -j | grep SYSTEM | awk -F: '{print $2}'`

    cat <<EOF

A demo data source has been created in $sysconfdir
which you may use as an example for creating your own post installation.

EOF
    exit 0
  fi
done
answer=""
while [ "$answer" = "" ]
do
  cat <<EOF

Enter the name (or IP address) of the machine where the SQL Server instance 
is installed. If you are using a non-default port (the default is 1433) then 
enter this as server:port e.g. myserver:2466. If you are using a SQLEXPRESS 
connection then use the normal form to name the server, e.g. server\SQLEXPRESS 
and let the driver find the necessary port.

EOF
  $ECHO "Server (q=quit) : \c"
  read $READR answer
  if [ "$answer" = "q" ];then
    exit 0
  fi
  if [ "$answer" != "" ];then
    server=`$ECHO $answer | awk -F: '{print $1}'`
    port=`$ECHO $answer | awk -F: '{print $2}'`
    #$ECHO "$server, \"$port\""
    #$ECHO "Attempting to contact the Server..."
	if [ "$port" = "" ];then
    	$ECHO "Using $TDSHELPER -v -s \"$server\""
	else
    	$ECHO "Using $TDSHELPER -v -s \"$server\" -n \"$port\""
	fi
    $ECHO "==============================================================="
	if [ "$port" = "" ];then
    	$TDSHELPER -v -s "$server"
	else
    	$TDSHELPER -v -s "$server" -n "$port"
	fi
    result=$?
    $ECHO "==============================================================="
    if [ $result -ne 0 ];then
      cat <<EOF

Failed to contact the Server. Please examine the output above.
The Server should be the name (or IP address) of the machine where the
server is installed. If you enter a name then this name must be able to be
resolved into an IP address using either DNS or a local hosts file.
If you got an error mentioning gethostbyname then the system failed to
resolve $server into an IP Address.

If you got a connection refused error then perhaps you specified the
wrong machine or the wrong port.

If you cannot resolve this issue you can enter q to quit this part of
the process.
EOF
    answer=""
    fi
  fi
done
cat <<EOF

Server = '$server'
Port = $port

The second step is to authenticate with the Server. You need a valid
user name and password for the instance running on $server.

EOF
user=""
auth=""
loggedon="n"
while [ "$loggedon" = "n" ]
do
  $ECHO "Please enter a valid username and password for the instance on  $server"
  if [ "$user" != "" ];then
    $ECHO "Username (enter q to abort) [$user] : \c"
  else
    $ECHO "Username (enter q to abort) : \c"
  fi
  read $READR answer
  if [ "$answer" = "q" ];then
    $ECHO "DSN creation aborted at user request"
    exit 0
  elif [ "$answer" != "" ];then
    user="$answer"
  fi
  $ECHO "Password : \c"
  $ECHOOFF
  read $READR auth
  $ECHOON
  $ECHO
  if [ "$port" = "" ];then
   	$ECHO "Using $TDSHELPER -v -s \"$server\" -u \"$user\" -a XXXXXX"
  else
   	$ECHO "Using $TDSHELPER -v -s \"$server\" -n \"$port\" -u \"$user\" -a XXXXXX"
  fi
  $ECHO "===================================================================="
  if [ "$port" = "" ];then
   	$TDSHELPER -v -s "$server" -u "$user" -a "$auth"
  else
   	$TDSHELPER -v -s "$server" -n "$port" -u "$user" -a "$auth"
  fi
  result=$?
  $ECHO "===================================================================="
  if [ $result -eq 0 ];then
    $ECHO "Test Successful"
    loggedon="y"
  else
    cat <<EOF

Failed to authenticate user $user on $server.
Please examine the output above to identify the problem. 

EOF

  fi
done
cat <<EOF

Successfully connected and authenticated with:

Server = '$server'
Port = $port
User = $user
Auth = XXXXXX

The third step is to optionally select the default database to use with this
connection to $server.

First probe the server to find the available databases:
EOF

$ECHO
if [ "$port" = "" ];then
 $ECHO "Using $TDSHELPER -s \"$server\" -u \"$useri\" -a XXXXXX -d"
else
 $ECHO "Using $TDSHELPER -s \"$server\" -n \"$port\" -u \"$user\" -a XXXXXX -d"
fi
$ECHO "===================================================================="
if [ "$port" = "" ];then
 $TDSHELPER -s "$server" -u "$user" -a "$auth" -d
else
 $TDSHELPER -s "$server" -n "$port" -u "$user" -a "$auth" -d
fi
$ECHO "===================================================================="

database=""

cat <<EOF

Please enter the name of the required database on $server or leave blank to
use the database default.

EOF
if [ "$database" != "" ];then
  $ECHO "Default database (q=quit) [$database] : \c"
else
  $ECHO "Default database (q=quit) : \c"
fi
read answer
if [ "$answer" = "q" ];then
  $ECHO "DSN creation aborted at user request"
  exit 0
elif [ "$answer" != "" ];then
  database="$answer"
fi
$ECHO
cat <<EOF

The fourth step is to optionally select the language to use with this
connection to $server.

First probe the server to find the available languages:
EOF

$ECHO
if [ "$port" = "" ];then
 $ECHO "Using $TDSHELPER -s \"$server\" -u \"$user\" -a XXXXXX -l"
else
 $ECHO "Using $TDSHELPER -s \"$server\" -n \"$port\" -u \"$user\" -a XXXXXX -l"
fi
$ECHO "===================================================================="
if [ "$port" = "" ];then
 $TDSHELPER -s "$server" -u "$user" -a "$auth" -l
else
 $TDSHELPER -s "$server" -n "$port" -u "$user" -a $auth -l
fi
$ECHO "===================================================================="

language=""

cat <<EOF

Please enter the name of the language on $server or leave blank to
use the default.

EOF
if [ "$language" != "" ];then
  $ECHO "Language (q=quit) [$language] : \c"
else
  $ECHO "Language (q=quit) : \c"
fi
read answer
if [ "$answer" = "q" ];then
  $ECHO "DSN creation aborted at user request"
  exit 0
elif [ "$answer" != "" ];then
  language="$answer"
fi
$ECHO
cat <<EOF

Server = '$server'
Port = $port
User = $user
Auth = XXXXXX
Language = $language
Database = $database

This script can now create a local DSN which
you can use later to connect from your ODBC applications.

EOF
answer="hoho"
while [ \( "$answer" != "y" \) -a \( "$answer" != "n" \) ]
do
  $ECHO "Do you want to create a DSN you can use later? [y] (y/n) : \c"
  read answer
  if [ "$answer" = "" ];then
    answer="y"
  fi
  if [ "$answer" = "n" ];then
    cat <<EOF

You may want to make a note of the attributes above for when you create
a DSN yourself.

Exiting DSN creation.

EOF
    exit 0
  fi
done
dsnname=""
while [ "$dsnname" = "" ]
do
  $ECHO "Enter a name for this DSN : \c"
  read dsnname
done
file="dsn_$$"
$ECHO "[$dsnname]" > $file
$ECHO "Driver = Easysoft ODBC-SQL Server" >> $file
$ECHO "Description = SQL Server DSN created during installation" >> $file
$ECHO "Server = $server" >> $file
if [ "port" != "" ];then
$ECHO "Port = $port" >> $file
fi
$ECHO "User = $user" >> $file
$ECHO "Password = $auth" >> $file
if [ "language" != "" ];then
$ECHO "Language = $language" >> $file
fi
if [ "database" != "" ];then
$ECHO "Database = $database" >> $file
fi
$ECHO "Logging = 0" >> $file
$ECHO "LogFile =" >> $file
$ECHO "QuotedId = Yes" >> $file
$ECHO "AnsiNPW = Yes" >> $file
$ECHO "Mars_Connection = No" >> $file
if [ "$UODBCSCRIPT" != "" ];then
	"$UODBCSCRIPT" dsn $file "$PRODUCTLONG" "$DRIVER" 0
else
	./uodbc dsn $file "$PRODUCTLONG" "$DRIVER" 0
fi
#ODBCSEARCH="ODBC_SYSTEM_DSN"        # create system dsn
#export ODBCSEARCH
#$ODBCINST -s -i -f $file
#result=$?
#if [ "$result" -ne 0 ];then
#  $ECHO "Failed to create DSN"
#  $ECHO "The DSN entry we would have created can be found in $file"
#  exit 0
#fi
if [ "$ISQL" = "" ];then

We did not find an executable isql so this script is not going to test
the DSN.

else
  cat <<EOF

We can now attempt to demonstrate the SQL Server by retrieving version
information from $server.

EOF
  answer="hoho"
  while [ \( "$answer" != "y" \) -a \( "$answer" != "n" \) ]
  do
    $ECHO "Do you want to attempt to get server version info back [y] (y/n) : \c"
    read answer
    if [ "$answer" = "" ];then
      answer="y"
    fi
    if [ "$answer" = "n" ]; then
      cat <<EOF

You can use
$ISQL -v $dsnname
or
$ISQL -v $dsnname $targetuser $targetauth

to issue SQL to your remote DSN.

DSN creation complete.

EOF
      exit 0
    fi
  done
  tablefile="tables_$$.sql"
  $ECHO "select @@VERSION as Version\n\n" > $tablefile
  $ISQL -v -b $dsnname $targetuser $targetauth < $tablefile
  $ECHO				# get past isql prompt
fi

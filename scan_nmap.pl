#!/usr/bin/perl
use DBI;

$mysql_host='localhost';
$mysql_db='nmap';
$mysql_user='root';
$mysql_password='';

$dbh = DBI->connect("DBI:mysql:$mysql_db:$mysql_host",$mysql_user, $mysql_password)
	    or die "Error connecting to database";

$q="drop table if exists host,service;";
$rv=$dbh->do($q) or die "Не могу выполнить: ".$dbh->errstr;
$q="create table `host`  (
  id int auto_increment,
  name varchar(50),
  ds TINYINT,
  vs TINYINT,
  cl TINYINT,
  primary key (id),
  index name (name));";
$rv=$dbh->do($q) or die "Не могу выполнить: ".$dbh->errstr;

$q="create table `service` (
  id int auto_increment,
  id_host int,
  port int,
  proto varchar(10),
  state varchar(10),
  service varchar(20),
  primary key (id));";
$rv=$dbh->do($q) or die "Не могу выполнить: ".$dbh->errstr;

open R, "<roles.conf";

while(<R>) {
  chomp;
  if (/^\s*#/) {
    next;
  };
  if (/^(\S+):/) { 

    
#    // add previos host type;
    $sth = $dbh->prepare('UPDATE host set ds=?,vs=?,cl=? where id=?');
    $sth->execute( $is_ds,$is_vs,$is_cl, $host_id );

#
    $host=$1;
    $is_ds=0;
    $is_vs=0;
    $is_cl=0;
    $is_basevs=0;

#    // add new host
    print "\n$host\n";
    $sth = $dbh->prepare('INSERT INTO host ( name ) VALUES ( ? )');
    $sth->execute( $host );
    $host_id=$sth->{mysql_insertid};
    $port=0;
    open NMAP, "nmap $host |";
    while(<NMAP>) {
       chomp;
       if (/^$/) {
         $port=0;
       };
       if ($port==1) {
	 print "$_\n";
         ($prt,$state,$service)=split /\s+/;
         ($pp,$proto)=split('/',$prt);
         $sth = $dbh->prepare('INSERT INTO service ( id_host, port,proto,state,service ) VALUES ( ?, ?, ?, ?, ? )');
	 $sth->execute( $host_id, $pp, $proto, $state, $service );
	 #print "$pp - $proto - $state - $service\n";
       };
       if (/^PORT/) {
         $port=1;
       };

    };
    close NMAP;
  };
  if (/^\s+.*(\.ds\.)/) { 
     $is_ds=1;
  };
  if (/^\s+.*(\.vs\.)/) { 
     $is_vs=1;
  };
  if (/^\s+.*(base-vs\.)/) { 
     $is_cl=1;
  };

};

#    // add last host type;
$sth = $dbh->prepare('UPDATE host set ds=?,vs=?,cl=? where id=?');
$sth->execute( $is_ds,$is_vs,$is_cl, $host_id );

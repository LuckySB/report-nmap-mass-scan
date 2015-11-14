#!/usr/bin/perl
use DBI;

$mysql_host='localhost';
$mysql_db='nmap';
$mysql_user='root';
$mysql_password='';

$dbh = DBI->connect("DBI:mysql:$mysql_db:$mysql_host",$mysql_user, $mysql_password)
            or die "Error connecting to database";

$rep=$ARGV[0];
$serv=$ARGV[1];
$state=$ARGV[2];

if (($rep=~/^sh/) or ($rep=~/^li/)) {
  if ($serv=~/\w+/) {$col='service'};
  if ($serv=~/\d+/) {$col='port'};
  if ($state=~/-\w+/) {$n='!=';$state=~s/^-//;} else {$n='='};
  if ($rep=~/^li/) {$select='name'} else {$select='name,port,state,service'};
  show_service_state($select,$serv,$col,$state,$n);
} elsif ($rep=~/^ho/ ) {
  host($serv);
} elsif ($rep=~/^su/) {
  if ($serv=~/\w+/) {$col='and service=? '};
  if ($serv=~/\d+/) {$col='and port=? '};
  if (($serv eq 'all') or (not defined $serv)) {$col='and 1=?'; $serv=1;};
  summ($serv,$col);
} else {
  print "Usage:\n";
  print "\n$0 show <service> [-]<state>\n";
  print "\n$0 list <service> [-]<state>\n";
  print "   show host with service in state <state>\n";
  print "   list only hostname with service in state <state>\n";
  print "   -<state> mean is not in state\n";
  print "\n$0 host <hostname>\n";
  print "   show service on host\n";
  print "   accepted mysql wildcards\n";
  print "\n$0 summ <service>\n";
  print "   summary port stat\n";
};

$dbh->disconnect;

sub show_service_state {
   my ($select,$serv,$col,$state,$n) = @_;
   my $q="select concat(if(ds,' ds ',''),if(cl,' cl ',''),if(vs,' vs ','')) as t, $select from service,host where host.id=id_host and $col=? and state$n? order by t,name";
   my $sth=$dbh->prepare($q);
   $sth->execute($serv,$state) or die "Не могу выполнить: ".$sth->errstr;
   while (my @row = $sth -> fetchrow_array) {
     print "@row\n";
   };
};

sub host {
   my ($host) = @_;
   my $q="select name, port,proto,state,service from service,host where host.id=id_host and name like ? order by name,port";
   my $sth=$dbh->prepare($q);
   $sth->execute('%'.$host.'%') or die "Не могу выполнить: ".$sth->errstr;
   while (my @row = $sth -> fetchrow_array) {
     print "@row\n";
   };
};

sub summ {
   my ($serv,$col) = @_;
   my $q="select concat(if(ds,' ds ',''),if(cl,' cl ',''),if(vs,' vs ','')) as t, port, service,state,count(*) from host,service where host.id=id_host $col group by t,port,state order by t,port";
   my $sth=$dbh->prepare($q);
   $sth->execute($serv) or die "Не могу выполнить: ".$sth->errstr;
   while (my @row = $sth -> fetchrow_array) {
     print "@row\n";
   };
};


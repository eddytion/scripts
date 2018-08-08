#!/usr/bin/perl 

print "Enter hostname: \t";
my $host = <>;
chomp($host);

print "Enter username: \t";
my $username = <>;
chomp($username);

print "Enter password: \t";
my $password = <>;
chomp($password);

my $date = `date +%Y-%m-%d`;
chomp($date);

my $curl_file = "/tmp/curl.out.$date";
my $workdir = "/tmp/$username";
system("mkdir -p $workdir");

system("export ftp_proxy=proxy:8080");
system("export ftps_proxy=proxy:8080");
system("export http_proxy=proxy:8080");
system("export https_proxy=proxy:8080");

system("curl -v -k --ftp-ssl-reqd ftp://$host --user $username:$password > $curl_file");

my @a_files = `cat $curl_file  | awk {'print \$9'}`;
chomp(@a_files);

foreach $file (@a_files)
{
  system("curl -o $workdir/$file -O -v -k --ftp-ssl-reqd ftp://$host/$file --user $username:$password");
}

print "All files downloaded in $workdir \n";
system("ls -l $workdir");

#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use threads;

my $script = $ARGV[0];
my $serverlist = $ARGV[1];

sub rip()
{
    my $server = shift;
    my $scr = shift;
    system("$scr $server");
}

my @a_servers = `cat $serverlist`;
my @a_threads;

chomp(@a_servers);
for my $i (@a_servers)
{
    push @a_threads, threads::async { &rip($i, $script); }
}

foreach(@a_threads)
{
    $_->threads::join();
}

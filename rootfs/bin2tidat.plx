#!/usr/bin/perl -w

use File::Basename qw(dirname basename);
use File::stat;
use bytes;
use strict;

my $start_addr = 0x81000000;
my $length     = 0;

my @file_list = ();

# Process args
my $arg;
foreach $arg (@ARGV) {

  if ($arg =~ m/--start-addr/) {
    $arg =~ s,--final-script=,,;
    $start_addr = $arg + 0;
    next;
  }

  # else an input file
  push @file_list, $arg;
}

my $file;
foreach $file (@file_list) {
  my $fh_in;
  my $fh_out;
  my $buf;
  my $size;
  my $outfile = $file . ".dat";

  open($fh_in, "< $file") or die("cannot open file '$file'\n");
  $size = (stat($fh_in))->size;
  $size = min($size, $length) if ($length > 0);

  open($fh_out, "> $outfile") or die("cannot open file $outfile\n");

  printf $fh_out "1651 6 %8.8X 0 %8.8X\n", $start_addr, $size;

  for (; $size > 0; $size--) {
    read($fh_in, $buf, 1);
    printf $fh_out "0x%2.2X\n", ord($buf);
  }

  close($fh_in);
  close($fh_out);
}


#!/usr/bin/perl -w
# vi: set ts=4:
#
#***************************************************************
#
# Copyright (c) 2001 David Schleef     <ds@schleef.org>
# Copyright (c) 2001 Erik Andersen     <andersen@codepoet.org>
# Copyright (c) 2001 Stuart Hughes     <stuarth@lineo.com>
# Copyright (c) 2002-2005 VirtualLogix <sebastien.laborie@virtuallogix.com>
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#***************************************************************
#

# TODO -- use strict mode...
#use strict;

use Getopt::Long;
use File::Find;

# Set up some default values

my $all=0;
my $basedir="";
my $kernelsyms="";
my $cross="";
my $errsyms=0;
my $root=0;
my $stdout=0;
my $verbose=0;
my $kversion="";

# get command-line options

Getopt::Long::Configure ("bundling");

my %opt;

GetOptions(
	\%opt,
	"all|a" => \$all,
	"basedir|b=s" => \$basedir,
	"kernelsyms|F=s" => \$kernelsyms,
	"crosscompile|c=s" => \$cross,
	"errsyms|e" => \$errsyms,
	"root|r" => \$root,
	"stdout|n" => \$stdout,
	"verbose|v" => \$verbose,
	"version|V",
	"help|h",
);

if (defined $opt{help}) {
    print
	"$0 [OPTION]... KERNEL_VERSION\n",
	"\t-a --all\t\tSearch for modules specified in base directory\n",
	"\t-b --basedir\t\tModules base directory\n",
	"\t-F --kernelsyms\t\tKernel symbol file\n",
	"\t-c --crosscompile\tCross-compilation prefix\n",
	"\t-e --errsyms\t\tShow unresolved symbols\n",
	"\t-r --root\t\tAllow modules to be not owned by root\n",
	"\t-n --stdout\t\tWrite to stdout instead of modules.dep\n",
	"\t-v --verbose\t\tPrint out lots of debugging stuff\n",
	"\t-V --version\t\tPrint the release version\n",
	"\t-h --help\t\tShow this help screen\n",
    ;
    exit 0;
}

if (defined $opt{version}) {
    print "Perl depmod version 2.4.x\n";
    exit 0;
}

if (!$all || !$basedir || !$kernelsyms) {
  die "cross depmod requires -a -b and -F options to be specified\n";
}

if (!@ARGV) {
  die "cross depmod requires the kernel version to be specified\n"
}

$kversion=$ARGV[0];
$basedir="$basedir/lib/modules/$kversion";

if (! $stdout) {
    open(MODDEP, ">$basedir/modules.dep");
    select(MODDEP);
}

# Find the list of .o files living under $basedir 
if ($verbose) { warn "Locating all modules in $basedir\n"; }
my($file) = "";
my(@liblist) = ();
find sub { 
	if ( -f $_  && ! -d $_ ) { 
		$file = $File::Find::name;
		if ( $file =~ /\.k?o$/ ) {
			push(@liblist, $file);
			if ($verbose) { warn "$file\n"; }
		}
	}
}, $basedir;
if ($verbose) { warn "Finished locating modules\n"; }

@output=`cat System.map`;
$c6x_coff = grep m/ _c6x_/, @output;

foreach $obj ( @liblist, $kernelsyms ){
    # turn the input file name into a target tag name
    # vmlinux is a special that is only used to resolve symbols
    if($obj eq "System.map") {
        $tgtname = "vmlinux";
    } else {
        ($tgtname) = $obj =~ m-(/lib/modules/.*)$-;
	# Force all modules to have at least one undefined symbol in
	# order to be listed in the modules.dep file.
	if ($c6x_coff){
	  push @{$dep->{$tgtname}}, "_printk";
	} else {
	  push @{$dep->{$tgtname}}, "printk";
	}
    }

    warn "MODULE = $tgtname\n" if $verbose;

    # get a list of symbols
        if($obj eq "System.map") {
	    @output=`cat $obj`;
	} else {
	    @output=`${cross}nm $obj`;
	}
        if ($c6x_coff){
	  $ksymtab=grep m/ ___ksymtab/, @output;
	} else {
	  $ksymtab=grep m/ __ksymtab/, @output;
	}

    # gather the exported symbols
	if($ksymtab){
        # explicitly exported
        foreach ( @output ) {
	  if ($c6x_coff){
            / ___ksymtab(.*)$/ and do {
                warn "sym = $1\n" if $verbose;
                $exp->{$1} = $tgtname;
            };
	  } else {
            / __ksymtab_(.*)$/ and do {
                warn "sym = $1\n" if $verbose;
                $exp->{$1} = $tgtname;
            };
	  }
        }
	} else {
        # exporting all symbols
        foreach ( @output) {
            / [ABCDGRST] (.*)$/ and do {
                warn "syma = $1\n" if $verbose;
                $exp->{$1} = $tgtname;
            };
        }
	}
    # gather the unresolved symbols
    foreach ( @output ) {
      if ($c6x_coff){
        !/ ___this_module/ && / U (.*)$/ and do {
            warn "und = $1\n" if $verbose;
            push @{$dep->{$tgtname}}, $1;
        };
      } else {
        !/ __this_module/ && / U (.*)$/ and do {
            warn "und = $1\n" if $verbose;
            push @{$dep->{$tgtname}}, $1;
        };
      }
    }
}


# reduce dependencies: remove unresolvable and resolved from vmlinux
# remove duplicates
foreach $module (keys %$dep) {
    $mod->{$module} = {};
    foreach (@{$dep->{$module}}) {
        if( $exp->{$_} ) { 
            warn "resolved symbol $_ in file $exp->{$_}\n" if $verbose;
            next if $exp->{$_} =~ /vmlinux/;
            $mod->{$module}{$exp->{$_}} = 1;
        } else {
            warn "unresolved symbol $_ in file $module\n" if $errsyms;
        }
    }
}

# compute recursive dependencies
sub flatdeps
{
    my ($module, %deps) = @_;

    foreach my $d ( keys %deps ) {
        $mod->{$module}{$d} = 1;
        flatdeps($module, %{$mod->{$d}});
    }
}

foreach $module ( keys %$mod )  {
    flatdeps($module, %{$mod->{$module}});
}

# resolve the dependencies for each module
foreach $module ( keys %$mod )  {
    @sorted = sort bydep keys %{$mod->{$module}};
    print "$module:\t";
    print join(" \\\n\t",@sorted);
    print "\n\n";
}

sub bydep
{
    foreach my $f ( keys %{$mod->{$b}} ) {
        if($f eq $a) {
            return 1;
        }
    }
    foreach my $f ( keys %{$mod->{$a}} ) {
        if($f eq $b) {
            return -1;
        }
    }
    return 0;
}

__END__

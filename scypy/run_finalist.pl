#!/usr/bin/perl

use strict;
use Data::Dumper;

my $run = 2;
my %avg = ();

for (<>) {

    my $parts = $_;
    my $cmd = "./run.sh $parts";
    my $avg = 0.0;

    for (my $i=0; $i<$run; $i++) {
        my $res = `$cmd`;
        if ($res =~ /ROI: (.*)/) {
            $avg += $1 * 1.0;
        } else {
            last;
        }
    }
    
    $avg{$parts} = $avg / $run;
}

sort(%avg);
print Dumper(\%avg);

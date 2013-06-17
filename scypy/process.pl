#!/usr/bin/perl

use strict;
use Data::Dumper;
use Text::CSV;
use Switch;
use JSON::XS;
use Date::Parse;
use MIME::Base64;
use List::Util qw(reduce max min);
use CapitalD::Process qw(init_places extract_loans);

## Load up the zips
my $loan_file           = $ARGV[0];
my $training_init       = $ARGV[1];
my $feature_set         = $ARGV[2];
my $debug               = ($ARGV[3] eq "DEBUG")? 1: 0;

#Required labels
my @on_places = (
    'str_rep',
    'loan_amnt',
    'zip',
    'term',
    'apr',
    'grade',
    'annual_inc',
    'sub_grade',
    'purpose',
    'is_inc_v',
    'emp_length',
    'home_ownership',
    'dti',
    'fico_range_low',
    'inq_last_6mths',
    'revol_bal',
    'revol_util',
    'total_bc_limit',
    'num_rev_accts',
    'pub_rec_bankruptcies',
    'tax_liens',
    );

if (!$loan_file) {
    die("Usage: perl process.pl loan_file training_init featured DEBUG?")
}

my @actually_on_places = (
    1,
);

my $number_on_places = init_places($feature_set, \@actually_on_places);
my $data = extract_loans($loan_file, $training_init, \@actually_on_places, \@on_places, $debug);

print(scalar(@$data),",",$number_on_places-1,"\n");
for (my $jj=0; $jj<scalar(@actually_on_places); $jj++) {
    if ($actually_on_places[$jj]) {
        my $p = $on_places[$jj];
        print $p,", ";
    }
}
    
print("value\n");
foreach my $r (@$data) {
    for (my $j=0; $j<scalar(@$r); $j++) {
        if ($j == 0) {
            if ($debug) { 
                printf("%s, ", Dumper(@$r[$j]));
            } else {
                my $enc = encode_base64(@$r[$j], "|");
                chomp($enc);
                printf("%s, ", $enc);
            }
        } elsif ($j < $number_on_places) {
            printf("%.2f, ", @$r[$j]);
        } else {
            printf("%.2f", @$r[$j]);
        }
    }
    print("\n");
}


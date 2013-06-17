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
use Test::More tests => 23;

## Load up the zips
my $loan_file           = "./t/TestData.csv";
my $loan_file_if        = "./t/TestDataInFunding.csv";
my $feature_set         = "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1";
my $debug               = 0;
my $EPSILON             = 0.0001; 

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

my @zips = (
    256350774,
    749084515,
    977558772,
    730011377,
    377083616,
    489566469,
    397400770,
    902983762,
    804548275,
    184130875,
    );

my @rates = (
    7.9588405932002,
    5.48185830281838,
    6.88754364874644,
    7.10918000677152,
    5.16060903948194,
    7.48888315418048,
    5.26374359109043,
    6.8730160266451,
    -60.712,
    6.46509983012142,
    );

my @zips_if = (
    717637534,
    186227547,
    580489706,
    819838046,
    698320850,
    12939519,
    237864773,
    );

my @actually_on_places = (
    1,
);

my $number_on_places = init_places($feature_set, \@actually_on_places);

ok( defined($number_on_places) && $number_on_places == scalar(@actually_on_places), 'Does init_places Work?' );
ok( $number_on_places == 21, 'Number of on places' );

my $data = extract_loans($loan_file, "0", \@actually_on_places, \@on_places, $debug);
ok( defined($data) && scalar(@zips) == scalar(@$data), 'Number returned Base?' );
for (my $i=0; $i < scalar(@$data); $i++) {
    ok ( $data->[$i]->[2] == $zips[$i], "Zip right: " . $data->[$i]->[0]);
    ok ( abs($data->[$i]->[21] - $rates[$i]) < $EPSILON, "ROI right: " . $data->[$i]->[0]);
}

$data = extract_loans($loan_file_if, "1", \@actually_on_places, \@on_places, $debug);
ok( defined($data) && scalar(@zips_if) == scalar(@$data), 'Number returned IF?' );
for (my $i=0; $i < scalar(@$data); $i++) {
    ok ( $data->[$i]->[2] == $zips_if[$i], "Zip right: " . $data->[$i]->[0]);
}

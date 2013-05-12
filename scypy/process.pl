#!/usr/bin/perl

use strict;
use Data::Dumper;
use Text::CSV;
use Switch;
use Date::Parse;
use List::Util qw(reduce max);

## Load up the zips

my $zip_file            = $ARGV[0];
my $loan_file           = $ARGV[1];
my $training_init       = $ARGV[2];
my $debug               = $ARGV[3];
my $city                = {};
my $CURRENT_TIME        = time();

if (!$loan_file) {
    die("Usage: perl process.pl zip_file loan_file training_init")
}

my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
    or die "Cannot use CSV: ".Text::CSV->error_diag ();

open my $fh, "<:encoding(utf8)", $zip_file or die "test.csv: $!";
while ( my $row = $csv->getline( $fh ) ) {
    $city->{uc($row->[3]." " . $row->[1])} = $row->[0];
}
$csv->eof or $csv->error_diag();
close $fh;

my $status;
my @data = ();
my @targets = ();
my $procossor_place_rev = {};
my @procossor_place = ();
my %processors = (
    'id' => \&get_id,
    'member_id' => \&get_member_id,
    'loan_amnt' => \&get_loan_amnt,
    'funded_amnt' => \&get_funded_amnt,
    'funded_amnt_inv' => \&get_funded_amnt_inv,
    'term' => \&get_term,
    'apr' => \&get_apr,
    'int_rate' => \&get_int_rate,
    'installment' => \&get_installment,
    'grade' => \&get_grade,
    'sub_grade' => \&get_sub_grade,
    'emp_name' => \&get_emp_name,
    'emp_length' => \&get_emp_length,
    'home_ownership' => \&get_home_ownership,
    'annual_inc' => \&get_annual_inc,
    'is_inc_v' => \&get_is_inc_v,
    'accept_d' => \&get_accept_d,
    'exp_d' => \&get_exp_d,
    'list_d' => \&get_list_d,
    'issue_d' => \&get_issue_d,
    'loan_status' => \&get_loan_status,
    'pymnt_plan' => \&get_pymnt_plan,
    'url' => \&get_url,
    'desc' => \&get_desc,
    'purpose' => \&get_purpose,
    'title' => \&get_title,
    'addr_city' => \&get_addr_city,
    'addr_state' => \&get_addr_state,
    'acc_now_delinq' => \&get_acc_now_delinq,
    'acc_open_past_24mths' => \&get_acc_open_past_24mths,
    'bc_open_to_buy' => \&get_bc_open_to_buy,
    'percent_bc_gt_75' => \&get_percent_bc_gt_75,
    'bc_util' => \&get_bc_util,
    'dti' => \&get_dti,
    'delinq_2yrs' => \&get_delinq_2yrs,
    'delinq_amnt' => \&get_delinq_amnt,
    'earliest_cr_line' => \&get_earliest_cr_line,
    'fico_range_low' => \&get_fico_range_low,
    'fico_range_high' => \&get_fico_range_high,
    'inq_last_6mths' => \&get_inq_last_6mths,
    'mths_since_last_delinq' => \&get_mths_since_last_delinq,
    'mths_since_last_record' => \&get_mths_since_last_record,
    'mths_since_recent_inq' => \&get_mths_since_recent_inq,
    'mths_since_recent_loan_delinq' => \&get_mths_since_recent_loan_delinq,
    'mths_since_recent_revol_delinq' => \&get_mths_since_recent_revol_delinq,
    'mths_since_recent_bc' => \&get_mths_since_recent_bc,
    'mort_acc' => \&get_mort_acc,
    'open_acc' => \&get_open_acc,
    'pub_rec_gt_100' => \&get_pub_rec_gt_100,
    'pub_rec' => \&get_pub_rec,
    'total_bal_ex_mort' => \&get_total_bal_ex_mort,
    'revol_bal' => \&get_revol_bal,
    'revol_util' => \&get_revol_util,
    'total_bc_limit' => \&get_total_bc_limit,
    'total_acc' => \&get_total_acc,
    'initial_list_status' => \&get_initial_list_status,
    'out_prncp' => \&get_out_prncp,
    'out_prncp_inv' => \&get_out_prncp_inv,
    'total_pymnt' => \&get_total_pymnt,
    'total_pymnt_inv' => \&get_total_pymnt_inv,
    'total_rec_prncp' => \&get_total_rec_prncp,
    'total_rec_int' => \&get_total_rec_int,
    'total_rec_late_fee' => \&get_total_rec_late_fee,
    'last_pymnt_d' => \&get_last_pymnt_d,
    'last_pymnt_amnt' => \&get_last_pymnt_amnt,
    'next_pymnt_d' => \&get_next_pymnt_d,
    'next_pymnt_amnt' => \&get_next_pymnt_amnt,
    'last_credit_pull_d' => \&get_last_credit_pull_d,
    'last_fico_range_high' => \&get_last_fico_range_high,
    'last_fico_range_low' => \&get_last_fico_range_low,
    'total_il_high_credit_limit' => \&get_total_il_high_credit_limit,
    'mths_since_oldest_il_open' => \&get_mths_since_oldest_il_open,
    'num_rev_accts' => \&get_num_rev_accts,
    'mths_since_recent_bc_dlq' => \&get_mths_since_recent_bc_dlq,
    'pub_rec_bankruptcies' => \&get_pub_rec_bankruptcies,
    'num_accts_ever_120_pd' => \&get_num_accts_ever_120_pd,
    'chargeoff_within_12_mths' => \&get_chargeoff_within_12_mths,
    'collections_12_mths_ex_med' => \&get_collections_12_mths_ex_med,
    'tax_liens' => \&get_tax_liens,
    'mths_since_last_major_derog' => \&get_mths_since_last_major_derog,
    'num_sats' => \&get_num_sats,
    'num_tl_op_past_12m' => \&get_num_tl_op_past_12m,
    'mo_sin_rcnt_tl' => \&get_mo_sin_rcnt_tl,
    'tot_hi_cred_lim' => \&get_tot_hi_cred_lim,
    'tot_cur_bal' => \&get_tot_cur_bal,
    'avg_cur_bal' => \&get_avg_cur_bal,
    'num_bc_tl' => \&get_num_bc_tl,
    'num_actv_bc_tl' => \&get_num_actv_bc_tl,
    'num_bc_sats' => \&get_num_bc_sats,
    'pct_tl_nvr_dlq' => \&get_pct_tl_nvr_dlq,
    'num_tl_90g_dpd_24m' => \&get_num_tl_90g_dpd_24m,
    'num_tl_30dpd' => \&get_num_tl_30dpd,
    'num_tl_120dpd_2m' => \&get_num_tl_120dpd_2m,
    'num_il_tl' => \&get_num_il_tl,
    'mo_sin_old_il_acct' => \&get_mo_sin_old_il_acct,
    'num_actv_rev_tl' => \&get_num_actv_rev_tl,
    'mo_sin_old_rev_tl_op' => \&get_mo_sin_old_rev_tl_op,
    'mo_sin_rcnt_rev_tl_op' => \&get_mo_sin_rcnt_rev_tl_op,
    'total_rev_hi_lim' => \&get_total_rev_hi_lim,
    'num_rev_tl_bal_gt_0' => \&get_num_rev_tl_bal_gt_0,
    'num_op_rev_tl' => \&get_num_op_rev_tl,
    'tot_coll_amt' => \&get_tot_coll_amt,
    );

my @forced_places = (
    'id',
    'str_rep',
    'payoff',
    'cost',
    'funded_amnt',
    'zip',
#    'loan_amnt',
#    'term',
#    'apr',
#    'int_rate',
    'grade',
#    'annual_inc',
    'sub_grade',
    'purpose',
#    'is_inc_v',
    'emp_length',
    'home_ownership',
#    'installment',
#    'acc_now_delinq',
#    'percent_bc_gt_75',
#    'dti',
#    'delinq_2yrs',
#    'delinq_amnt',
    'fico_range_low',
#    'fico_range_high',
#    'inq_last_6mths',
#    'mths_since_last_delinq',
#    'mths_since_last_record',
#    'mths_since_recent_inq',
#    'mths_since_recent_loan_delinq',
#    'mths_since_recent_revol_delinq',
#    'mths_since_recent_bc',
#    'total_bal_ex_mort',
#    'revol_bal',
#    'total_bc_limit',
#    'total_acc',
#    'mths_since_oldest_il_open',
#    'num_rev_accts',
#    'pub_rec_bankruptcies',
 #   'num_accts_ever_120_pd',
 #   'chargeoff_within_12_mths',
#    'collections_12_mths_ex_med',
#    'tax_liens',
#    'num_tl_op_past_12m',
#    'tot_cur_bal',
#    'avg_cur_bal',
#    'pct_tl_nvr_dlq',
#    'num_tl_90g_dpd_24m',
#    'num_tl_30dpd',
#    'num_tl_120dpd_2m',
#    'num_il_tl',
#    'mo_sin_old_il_acct',
#    'num_actv_rev_tl',
#    'total_rec_int',
    );

my $first = 1;

## Total interest recieved
my $CLASS_TARGET_FIELD_REC_INC = "total_rec_int";
my $CLASS_TARGET_FIELD_REC_PRC = "total_rec_prncp";
my $CLASS_TARGET_FIELD_GIVEN = "funded_amnt";
my $CLASS_ACCEPT_FIELD = "loan_status";

## Classification
#my $CLASS_TARGET_FIELD = "loan_status";

## Compute Annual RR
## Look at loan amounts by band

sub get_net_return {
    my $row = shift;

    my $issue_d = str2time($row->[$procossor_place_rev->{"issue_d"}]);
    my $last_payment_d = str2time($row->[$procossor_place_rev->{"last_pymnt_d"}]);
    my $len = ($last_payment_d - $issue_d);
    my $mon = int($len/2629743);
    if ($len > 31556926) { # we use loans > 1 year
        my $interest = $row->[$procossor_place_rev->{"total_rec_int"}];
        my $late_fee = $row->[$procossor_place_rev->{"total_rec_late_fee"}];
        my $princip = $row->[$procossor_place_rev->{"funded_amnt"}];
        my $charged_off = uc($row->[$procossor_place_rev->{"loan_status"}]) eq "CHARGED OFF";
        #my $default = $row->[$procossor_place_rev->{"total_rec_prncp"}] - $row->[$procossor_place_rev->{"funded_amnt"}];    

        my $default = max(0,($row->[$procossor_place_rev->{"installment"}] * $mon) - 
            ($row->[$procossor_place_rev->{"total_rec_prncp"}] + $row->[$procossor_place_rev->{"total_rec_int"}]));
        if ($charged_off) {
            $default = $row->[$procossor_place_rev->{"funded_amnt"}] -
                ($row->[$procossor_place_rev->{"total_rec_prncp"}] + $row->[$procossor_place_rev->{"total_rec_int"}])
        }

        my $ret = (1.0 + (($interest + $late_fee - $default) / ($princip * 1.00)) * $princip / ($princip * 1.)) ** 12.0 - 1;
        #print($ret," ",$default," ",$mon,"\n");
        return $ret;
    } else {
        return undef;
    }
}

sub get_zip {
    my $row = shift;
    my $city_a = uc($row->[$procossor_place_rev->{"addr_city"}]);
    my $state = uc($row->[$procossor_place_rev->{"addr_state"}]);
    my $zip = $city->{"$city_a $state"};
    if (!$zip) {
        $zip = 10000 * (reduce { $a += ord($b); return $a } 0, split(//, ($city_a . " " . $state)));
    }
    return $zip;
}

sub get_payoff {
    my $row = shift;
    return ($row->[$procossor_place_rev->{"total_rec_prncp"}] + $row->[$procossor_place_rev->{"total_rec_int"}]);
}

sub get_cost {
    my $row = shift;
    return ($row->[$procossor_place_rev->{"funded_amnt"}]);
}

open $fh, "<:encoding(utf8)", $loan_file or die "test.csv: $!";
while ( my $row = $csv->getline( $fh ) ) {

    if (!$first) {
        my $y = $training_init;
        my $keep = undef;
        my $X = {};
        my $next_x = 0;
        my $city_state;
        my $zip;

        $y = get_net_return($row);
        $zip = get_zip($row);
        if (defined($y)) {
            $keep = 1;
        }

        my $payoff = get_payoff($row);
        my $cost = get_cost($row);

        for (my $i=0; $i<scalar(@$row); $i++) {
            if ($processors{$procossor_place[$i]}) {
                my $res = $processors{$procossor_place[$i]}->($row->[$i]);
                                
                if (defined $res) {
                    # Add it to the feature set.
                    $X->{$procossor_place[$i]} = $res;
                    $next_x++;
                }
            }
        }
    
        my $vr = [];
        if (defined($y) && $keep > 0) {
            foreach my $k (@forced_places) {
                if (defined $X->{$k}) {
                    push @$vr, $X->{$k};
                } else {
                    if ($k eq "str_rep") {
                        if ($training_init > 0) {
                            my $s = join("-", ($row->[5],$row->[7],$row->[11]));
                            push @$vr, $s;
                        } else {
                            push @$vr, "";
                        }
                    } elsif ($k eq "zip") {
                        if (!$zip) {
                            die("\nEXCEPT $k\n");
                        } else {
                            push @$vr, $zip;
                        }
                    } elsif ($k eq "payoff") {
                        push @$vr, $payoff;
                    } elsif ($k eq "cost") {
                        push @$vr, $cost;
                    } else {
                        print(Dumper($X));
                        die("\nEXCEPT $k\n");
                        push @$vr, 0;
                    }
                }
            }
        
            ## Add the target here
            if (scalar @$vr == @forced_places && defined($y)) {
                push @$vr, $y;
                push @data, $vr;
            }
        }
    } else {
        $first = 0;
        for (my $i=0; $i<scalar(@$row); $i++) {
            $procossor_place[$i] = $row->[$i];
            $procossor_place_rev->{$row->[$i]} = $i;
            
            #print("    '" . $row->[$i] . "' => \\&get_" . $row->[$i],",\n");
        }
    }
}
$csv->eof or $csv->error_diag();
close $fh;

if ($debug) {
    foreach my $k (@forced_places) {
        print $k,",";
    }
    print("\n");
}

print(scalar(@data),",",scalar(@forced_places)-1,"\n");

foreach my $p (@forced_places) {
    if ($p ne "str_rep") {
        print $p,", ";
    }
}

print("value\n");

foreach my $r (@data) {
    for (my $j=0; $j<scalar(@$r); $j++) {
        if ($j == 0) {
            printf("%d, ", @$r[$j]);
        } elsif ($j == 1) {
            if ($training_init > 0) {
                printf("\'%s\', ", @$r[$j]);
            }
        } elsif ($j < scalar(@forced_places)) {
            printf("%.2f, ", @$r[$j]);
        } else {
            printf("%.2f", @$r[$j]);
        }
    }
    print("\n");
}

sub get_id{
    my $l = shift;
    return $l;
}
sub get_member_id{return undef}
sub get_loan_amnt{
    my $l = shift;
    return $l;
}
sub get_funded_amnt{
    my $l = shift;
    switch ($l) {
        case {0 < $l && $l <= 1000} { return 100; }
        case {1000 < $l && $l <= 2000} { return 200; }
        case {2000 < $l && $l <= 5000} { return 300; }
        case {5000 < $l && $l <= 10000} { return 400; }
        case {10000 < $l && $l <= 20000} { return 500; }
        case {20000 < $l && $l <= 40000} { return 600; }
        case {40000 < $l} { return 700; }
    }
    return undef;
}
sub get_funded_amnt_inv{
    my $l = shift;
    return $l;
}
sub get_term{
    my $l = shift;
    if ($l =~ /(\d\d) months/) {
        return $1;
    } elsif ($l =~ /(\d\d)/) {
        return $1;
    }
    return undef;
}
sub get_apr{
    my $l = shift;
    if ($l =~ /(.*)?\%/) {
        return $1;
    } elsif ($l =~ /(.*)?\.(.*)/) {
        return $1.".".$2;
    }
    return undef;
}
sub get_int_rate{
    my $l = shift;
    if ($l =~ /(.*)?\%/) {
        return $1;
    } elsif ($l =~ /(.*)?\.(.*)/) {
        return $1.".".$2;
    }
    return undef;
}

sub get_exp_default_rate{return undef;}
sub get_service_fee_rate{return undef;}

sub get_installment{
    my $l = shift;
    return $l;
}
sub get_grade{
    my @l = split //, shift;
    #return reduce { $a + ord($b) } 0, split //, $l;
    return ord($l[0])
}
sub get_sub_grade{
    my @l = split //, shift;
    return ord($l[0]) * 10000 + ord($l[1])
}
sub get_emp_name{return undef}
sub get_emp_length{
    my $l = shift;
    if ($l =~ /(\d+)(\+?) year/) {
        return $1;
    }
    return 0;
}
sub get_home_ownership{
    my $l = shift;
    switch ($l) {
        case "MORTGAGE"{ return 100; }
        case "RENT"{ return 200; }
        case "OWN"{ return 300; }
        case "NONE"{ return 400; }
        case "OTHER"{ return 500; }
    }
    return undef;

}
sub get_annual_inc{
    my $l = shift;
    return $l;
}
sub get_is_inc_v{
    my $l = shift;
    return ($l eq "TRUE")? 1.0: 0.0;
}
sub get_accept_d{return undef}
sub get_exp_d{return undef}
sub get_list_d{return undef}
sub get_issue_d{    
    my $l=shift;
    my $time = str2time($l);
    return $time;
}
sub get_loan_status{
    my $l = shift;
    switch ($l) {
        case "Charged Off"{ return 100; }
        case "Fully Paid"{ return 200; }
        case "Current"{ return undef; }
    }
    return undef;
}
sub get_pymnt_plan{
    my $l = shift;
    return ($l eq "TRUE")? 1.0: 0.0;
}
sub get_url{return undef}
sub get_desc{return undef}
sub get_purpose{
    my $l = shift;
    switch ($l) {
        case "debt_consolidation" { return 10000; }
        case "credit_card" { return 10100; }
        case "other" { return 10200; }
        case "home_improvement" { return 10300; }
        case "major_purchase" { return 10400; }
        case "small_business" { return 10500; }
        case "car" { return 10600; }
        case "wedding" { return 10700; }
        case "medical" { return 10800; }
        case "moving" { return 10900; }
        case "house" { return 11000; }
        case "vacation" { return 12000; }
        case "educational" { return 13000; }
        case "renewable_energy" { return 14000; }
    }
    return 0;
}
sub get_title{return undef}
sub get_addr_city{
    my $l = shift;
    return $l;
}
sub get_addr_state{return undef}
sub get_acc_now_delinq{
    my $l = shift;
    return $l;
}
sub get_acc_open_past_24mths{return undef}
sub get_bc_open_to_buy{return undef}
sub get_percent_bc_gt_75{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_bc_util{return undef}
sub get_dti{
    my $l = shift;
    return int($l);
}
sub get_delinq_2yrs{
    my $l = shift;
    return $l;
}
sub get_delinq_amnt{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_earliest_cr_line{return undef}
sub get_fico_range_low{
    my $l = shift;
    switch ($l) {
        case {0 < $l && $l <= 200} { return 100; }
        case {200 < $l && $l <= 300} { return 200; }
        case {300 < $l && $l <= 400} { return 300; }
        case {400 < $l && $l <= 400} { return 400; }
        case {500 < $l && $l <= 600} { return 500; }
        case {600 < $l && $l <= 700} { return 600; }
        case {700 < $l} { return 700; }
    }
    return undef;
}
sub get_fico_range_high{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_inq_last_6mths{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mths_since_last_delinq{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mths_since_last_record{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mths_since_recent_inq{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mths_since_recent_loan_delinq{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mths_since_recent_revol_delinq{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mths_since_recent_bc{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mort_acc{return undef}
sub get_open_acc{return undef}
sub get_pub_rec_gt_100{return undef}
sub get_pub_rec{return undef}
sub get_total_bal_ex_mort{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_revol_bal{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_revol_util{
    my $l = shift;
    if ($l =~ /(.*)?\%/) {
        return $1;
    }
    return undef;
}
sub get_total_bc_limit{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_total_acc{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_initial_list_status{return undef}
sub get_out_prncp{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_out_prncp_inv{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_total_pymnt{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_total_pymnt_inv{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_total_rec_prncp{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_total_rec_int{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_total_rec_late_fee{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_last_pymnt_d{return undef}
sub get_last_pymnt_amnt{return undef}
sub get_next_pymnt_d{return undef}
sub get_next_pymnt_amnt{return undef}
sub get_last_credit_pull_d{return undef}
sub get_last_fico_range_high{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_last_fico_range_low{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_total_il_high_credit_limit{return undef}
sub get_mths_since_oldest_il_open{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_num_rev_accts{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mths_since_recent_bc_dlq{return undef}
sub get_pub_rec_bankruptcies{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_num_accts_ever_120_pd{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_chargeoff_within_12_mths{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_collections_12_mths_ex_med{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_tax_liens{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mths_since_last_major_derog{return undef}
sub get_num_sats{return undef}
sub get_num_tl_op_past_12m{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mo_sin_rcnt_tl{return undef}
sub get_tot_hi_cred_lim{return undef}
sub get_tot_cur_bal{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_avg_cur_bal{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_num_bc_tl{return undef}
sub get_num_actv_bc_tl{return undef}
sub get_num_bc_sats{return undef}
sub get_pct_tl_nvr_dlq{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_num_tl_90g_dpd_24m{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_num_tl_30dpd{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_num_tl_120dpd_2m{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_num_il_tl{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mo_sin_old_il_acct{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_num_actv_rev_tl{
    my $l = shift;
    return ($l ne "")? $l: 0.0;
}
sub get_mo_sin_old_rev_tl_op{return undef}
sub get_mo_sin_rcnt_rev_tl_op{return undef}
sub get_total_rev_hi_lim{return undef}
sub get_num_rev_tl_bal_gt_0{return undef}
sub get_num_op_rev_tl{return undef}
sub get_tot_coll_amt{return undef}

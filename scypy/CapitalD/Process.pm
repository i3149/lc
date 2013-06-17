package CapitalD::Process;

require Exporter;

use strict;
use Data::Dumper;
use Text::CSV;
use Switch;
use JSON::XS;
use Date::Parse;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use MIME::Base64;
use List::Util qw(reduce max min);

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(init_places extract_loans);

my $loan_file           = $ARGV[1];
my $training_init       = $ARGV[2];
my $feature_set         = $ARGV[3];
my $debug               = $ARGV[4];
my $CURRENT_TIME        = time();

my $status;
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

my $number_on_places = 0;
sub init_places {
    my ($feature_set, $actually_on_places) = @_; 
    my @features = split(/,/, $feature_set);
    foreach my $f (@features) {
        push @$actually_on_places, $f;
    }

    foreach my $onp (@$actually_on_places) {
        if ($onp) {
            $number_on_places++;
        }
    }

    return $number_on_places;
}

# @TODO -- rename: calc_loan_duration_months
sub get_months {
    my $max = $_[0];
    my $invest = $_[1];
    my $rate = $_[2] / 12.0; #Get monthly rate from anual
    my $total_int_rec = $_[3];
    my $payment = $_[4];

    my $month = 0;
    my $int_rec = 0;

    for my $i (1 .. $max) {
        $month=$i;        
        my $interest = (($rate / 100.0) * $invest * 100.0) / 100.0;
        # @TODO -- make?? my $interest = (($rate * 1.0) * ($invest * 1.0)) / 100.0;
    
        my $current_payment = $payment - $interest;

        $invest -= $current_payment;
        $int_rec += $interest;

        if ($int_rec >= $total_int_rec) {
            last;
        }
    }

    return $month;
}

## Compute Annual RR
## Look at loan amounts by band
## Correct for Fully Paid and Charged off. Not correct for current.
sub get_net_return {
    my $row = shift;

    my $issue_d = str2time($row->[$procossor_place_rev->{"issue_d"}]);
    my $term = get_term($row->[$procossor_place_rev->{"term"}]);
    my $last_payment_d = str2time($row->[$procossor_place_rev->{"last_pymnt_d"}]);
    my $len = ($last_payment_d - $issue_d);
    my $max_mon = int($len/2629743); ### Number of seconds in a month

    if ($term > 36) {
        return undef;
    }

    my $id = $row->[$procossor_place_rev->{"id"}];
    my $payment = $row->[$procossor_place_rev->{"installment"}];
    my $rate = $row->[$procossor_place_rev->{"int_rate"}];
    my $interest = $row->[$procossor_place_rev->{"total_rec_int"}];
    my $late_fee = $row->[$procossor_place_rev->{"total_rec_late_fee"}];
    my $princip = $row->[$procossor_place_rev->{"funded_amnt"}];

    ## @TODO make be get_payoff()
    my $recieved = $row->[$procossor_place_rev->{"total_rec_prncp"}] + $row->[$procossor_place_rev->{"total_rec_int"}];

    my $mon = get_months($max_mon, $princip, $rate, $interest, $payment);
    my $charged_off = uc($row->[$procossor_place_rev->{"loan_status"}]) eq "CHARGED OFF";
    my $current = uc($row->[$procossor_place_rev->{"loan_status"}]) eq "CURRENT";
    my $fully_paid = uc($row->[$procossor_place_rev->{"loan_status"}]) eq "FULLY PAID";

    if ($current) { # we use loans >= 1 year
        if ($mon >= 12) {
            my $rata = $mon/($term*1.0);
            my $ret = ( ($recieved / ($princip * $rata)) ** (1.0 / ( $mon / 12.0 ) ) ) - 1;
            return min(1.0*$rate, $ret * 100.0);
        } else {
            return undef;
        }
    } else { ## Here we use charged_off or fully paid 
        if (($mon > 0) && ($fully_paid || $charged_off)) { 
            my $ret = ( ($recieved / ($princip * 1.0)) ** (1.0 / ( $mon / 12.0 ) ) ) - 1;
            return $ret * 100.0;
        } else {
            return undef;
        }
    }
}

## Returns a hash of city + state.
sub get_zip {
    my $row = shift;
    my $city_a = uc($row->[$procossor_place_rev->{"addr_city"}]);
    my $state = uc($row->[$procossor_place_rev->{"addr_state"}]);
    my $zip = md5_hex("$city_a $state");
    $zip =~ s/[a-z]//g;
    return substr($zip, 0, 9);
}

sub get_payoff {
    my $row = shift;
    return ($row->[$procossor_place_rev->{"total_rec_prncp"}] + $row->[$procossor_place_rev->{"total_rec_int"}]);
}

sub get_cost {
    my $row = shift;
    return 1.0 * ($row->[$procossor_place_rev->{"funded_amnt"}]);
}

## @TODO -- test on str to float conversions
sub get_extra_info {
    my ($row,$payoff,$cost) = @_;
    my $ee = {
        "grade" => $row->[$procossor_place_rev->{"grade"}],
        "int" => 1.0 * $row->[$procossor_place_rev->{"int_rate"}],
        "id" => $row->[$procossor_place_rev->{"id"}],
        "payoff" => $payoff,
        "cost" => $cost,
        "term" => 1.0 * get_term($row->[$procossor_place_rev->{"term"}]),
    };
    return encode_json($ee);
}

sub extract_loans {

    my ($loan_file, $training_init, $actually_on_places, $on_places, $debug) = @_;
    my $first = 1;
    my @data = ();
    my $csv = Text::CSV->new ( { binary => 1 } )  # should set binary attribute.
        or die "Cannot use CSV: ".Text::CSV->error_diag ();

    open my $fh, "<:encoding(utf8)", $loan_file or die "$loan_file: $!";
    while ( my $row = $csv->getline( $fh ) ) {

        if (!$first) {
            my $y = $training_init;
            my $keep = undef;
            my $X = {};
            my $next_x = 0;
            my $city_state;
            my $zip;
            
            if (!$y) {
                $y = get_net_return($row);
            }
            $zip = get_zip($row);
            if (defined($y)) {
                $keep = 1;
            }
            
            if (get_term($row->[$procossor_place_rev->{"term"}]) != 36) {
                $keep = 0;
            }
            
            my $payoff = ($y == 1)? "0": get_payoff($row);
            my $cost = get_cost($row);
            my $extra_info = get_extra_info($row, $payoff, $cost);
            
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
                for (my $jj=0; $jj<scalar(@$actually_on_places); $jj++) {
                    if ($actually_on_places->[$jj]) {
                        my $k = $on_places->[$jj];
                        
                        if (defined $X->{$k}) {
                            push @$vr, $X->{$k};
                        } else {
                            if ($k eq "str_rep") {
                                push @$vr, $extra_info;
                            } elsif ($k eq "zip") {
                                if (!$zip) { #@TODO -- need special treetment?
                                    die("\nEXCEPT $k\n");
                                } else {
                                    push @$vr, $zip;
                                }
                            } else {
                                print(Dumper($X));
                                die("\nEXCEPT $k\n");
                                push @$vr, 0;
                            }
                        }
                    }
                }
                
                ## Add the target here
                if (scalar @$vr == $number_on_places && defined($y)) {
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

    return \@data;
}
    
sub get_id{
    my $l = shift;
    return $l;
}
sub get_member_id{return undef}
sub get_loan_amnt{
    my $l = shift;
    switch ($l) {
        case {0 < $l && $l <= 1000} { return 100; }
        case {1000 < $l && $l <= 2000} { return 200; }
        case {2000 < $l && $l <= 5000} { return 300; }
        case {5000 < $l && $l <= 10000} { return 400; }
        case {10000 < $l && $l <= 20000} { return 500; }
        case {20000 < $l && $l <= 40000} { return 600; }
        case {40000 > $l} { return 700; }
    }
    return undef;
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
        case {40000 > $l} { return 700; }
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
        return int($1);
    } elsif ($l =~ /(.*)?\.(.*)/) {
        return int($1);
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
        case {$l > 700} { return 700; }
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
    if ($l == "") { return 0; }
    switch ($l) {
        case {0 < $l && $l <= 1000} { return 100; }
        case {1000 < $l && $l <= 2000} { return 200; }
        case {2000 < $l && $l <= 5000} { return 300; }
        case {5000 < $l && $l <= 10000} { return 400; }
        case {10000 < $l && $l <= 20000} { return 500; }
        case {20000 < $l && $l <= 40000} { return 600; }
        case {40000 < $l && $l <= 50000} { return 700; }
        case {50000 < $l && $l <= 60000} { return 800; }
        case {60000 < $l && $l <= 70000} { return 900; }
        case { $l > 70000 } { return 1000; }
    }
    return undef;
}
sub get_revol_util{
    my $l = shift;
    if ($l =~ /(.*)?\%/) {
        return int($1);
    }
    return 0;
}
sub get_total_bc_limit{
    my $l = shift;
    if ($l == "") { return 0; }
    switch ($l) {
        case {0 < $l && $l <= 1000} { return 100; }
        case {1000 < $l && $l <= 2000} { return 200; }
        case {2000 < $l && $l <= 5000} { return 300; }
        case {5000 < $l && $l <= 10000} { return 400; }
        case {10000 < $l && $l <= 20000} { return 500; }
        case {20000 < $l && $l <= 40000} { return 600; }
        case {$l > 40000} { return 700; }
    }
    return undef;
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

1;

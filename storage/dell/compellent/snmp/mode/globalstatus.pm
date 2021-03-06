#
# Copyright 2020 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package storage::dell::compellent::snmp::mode::globalstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("global status is '%s'", $self->{result_values}->{status});
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return "'" . $self->{global}->{display} . "': ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];

     $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{status} =~ /unknown/',
            warning_default => '%{status} =~ /nonCritical|other/',
            critical_default => '%{status} =~ /critical|nonRecoverable/',
            set => {
                key_values => [ { name => 'status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $states = {
    1 => 'other', 2 => 'unknown',
    3 => 'ok', 4 => 'nonCritical',
    5 => 'critical', 6 => 'nonRecoverable'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_ctlrOneModel = '.1.3.6.1.4.1.674.11000.2000.500.1.2.13.1.7.1';
    my $oid_ctlrTwoModel = '.1.3.6.1.4.1.674.11000.2000.500.1.2.13.1.7.2';
    my $oid_buildNumber = '.1.3.6.1.4.1.674.11000.2000.500.1.2.7.0';
    my $oid_globalStatus = '.1.3.6.1.4.1.674.11000.2000.500.1.2.6.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_ctlrOneModel, $oid_ctlrTwoModel, $oid_buildNumber, $oid_globalStatus
        ],
        nothing_quit => 1
    );

    my $global_status = $states->{ $snmp_result->{$oid_globalStatus} };
    
    my $display = $snmp_result->{$oid_ctlrOneModel};
    if (!defined($display)) {
        $display = $snmp_result->{$oid_ctlrTwoModel};
    }
    $display .= '.' . $snmp_result->{$oid_buildNumber};
    $self->{global} = {
        display => $display,
        status => $global_status
    };
}

1;

__END__

=head1 MODE

Check the overall status of Dell Compellent.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /nonCritical|other/').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /critical|nonRecoverable/').
Can used special variables like: %{status}

=back

=cut
    

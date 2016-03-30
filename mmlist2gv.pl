#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';

our $DOMAIN="stura.htw-dresden.de";
our $MM_PREFIX = "/usr/local/mailman";
our $MAILHIER = {};
our $MM_SHIER = {};


sub mailtree {
    my $list = shift;
    my $output = qx/$MM_PREFIX\/bin\/find_member "^$list\@$DOMAIN" | grep -iv "$list\@$DOMAIN" | sed -E 's|^ +||' /;
    my @members = split /\n/, $output;
    my $listhier = {};
    return undef unless @members;
    for my $member (@members) {
        next unless defined $member;
        $listhier->{$member} = &mailtree($member);
    }
    return $listhier;
}

sub draw_mmtree {
    my $list  = shift;
    my $mailhier = shift;
    $MM_SHIER->{$list} = [];
    for my $member (keys %{$mailhier->{$list}}) {
        push $MM_SHIER->{$list}, $member;
        #say "\"".$member . "\" -> \"" . $list . "\";";
        &draw_mmtree($member, $mailhier->{$list});
    }
}
my $output;
unless (@ARGV) {
    $output = qx/$MM_PREFIX\/bin\/list_lists | grep -oE ".*\ -" | sed -E 's|^ +||' |  sed -E 's| -.*\$||'/;
    chomp($output);
} else {
    $output = $ARGV[0];
}

my @lists = split /\n/, $output ;
for my $list (@lists) {
    $MAILHIER->{$list} = {};
    $MAILHIER->{$list} = &mailtree($list);
#    my $output = qx/$MM_PREFIX\/bin\/find_member "^$list\@$DOMAIN" | grep -v "$list\@$DOMAIN" | sed -E 's|^ +||' /;
#    my @members = split /\n/, $output;
#    for my $member (@members) {
#        next unless defined $member;
#        $MAILHIER->{$list}->{$member} = undef;
#    }
}
for my $list (keys %{$MAILHIER}) {
    $MM_SHIER->{$list} = [];
    for my $member (keys %{$MAILHIER->{$list}}) {
        #say "\"".$member . "\" -> \"" . $list . "\";";
        push $MM_SHIER->{$list}, $member;
        &draw_mmtree($member, $MAILHIER->{$list});
    }
}
say "digraph \"maillist_hier\" {";
say "overlap=false;";
say "rankdir=BT";
for my $list (keys %{$MM_SHIER}) {
    foreach (@{$MM_SHIER->{$list}}) {
        say "\"". $_ . "\" -> \"" . $list . "\";";
    }
}
say "}";

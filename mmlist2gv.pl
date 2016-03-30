#! /usr/bin/env perl

use strict;
use warnings;
use feature 'say';

our $DOMAIN="stura.htw-dresden.de";
our $MM_PREFIX = "/usr/local/mailman";
our $MAILHIER = {};
our $MM_SHIER = {};


sub mmtree_hash {
    my $list = shift;
    my $output = qx/$MM_PREFIX\/bin\/find_member "^$list\@$DOMAIN" | grep -iv "$list\@$DOMAIN" | sed -E 's|^ +||' /;
    my @members = split /\n/, $output;
    my $listhier = {};
    return undef unless @members;
    for my $member (@members) {
        next unless defined $member;
        $listhier->{$member} = &mmtree_hash($member);
    }
    return $listhier;
}

sub mmtree_array {
    my $list  = shift;
    my $mailhier = shift;
    $MM_SHIER->{$list} = {
        nomail => [],
        mail => []
    };
    for my $member (keys %{$mailhier->{$list}}) {
        my $output = qx/$MM_PREFIX\/bin\/list_members -n "$member" | sed -E 's|\@$DOMAIN||g'/;
        my @nomailmembers = split /\n/, $output;

        if ($list ~~ @nomailmembers) {
            push $MM_SHIER->{$list}->{nomail}, $member;
        } else {
            push $MM_SHIER->{$list}->{mail}, $member;
        }
        &mmtree_array($member, $mailhier->{$list});
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
    $MAILHIER->{$list} = &mmtree_hash($list);
}
for my $list (keys %{$MAILHIER}) {
#for my $list (@lists) {
    mmtree_array($list, $MAILHIER);
}
say "digraph \"maillist_hier\" {";
say "overlap=false;";
say "rankdir=BT";
for my $list (keys %{$MM_SHIER}) {
    foreach (@{$MM_SHIER->{$list}->{mail}}) {
        say "\"". $_ . "\" -> \"" . $list . "\" [color=green];";
    }
    foreach (@{$MM_SHIER->{$list}->{nomail}}) {
        say "\"". $_ . "\" -> \"" . $list . "\" [color=red, style=dashed];";
    }
}
say "}";

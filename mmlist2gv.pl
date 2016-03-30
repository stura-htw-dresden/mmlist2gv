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
    $MM_SHIER->{$list} = [];
    for my $member (keys %{$mailhier->{$list}}) {
        push $MM_SHIER->{$list}, $member;
        #say "\"".$member . "\" -> \"" . $list . "\";";
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
    mmtree_array($list, $MAILHIER);
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

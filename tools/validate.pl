#!/usr/bin/perl

eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
    if 0; # not running under some shell

use strict;
use warnings;

use YAML::Tiny;
use JSON;
use Data::Dumper;

my $src = 'tocalls.yaml';
my $out_dir = 'generated';

sub print_out($$)
{
	my($fn, $s) = @_;
	open(F, ">$fn") || die "Could not open $fn for writing: $!\n";
	print F $s;
	close(F) || die "Could not close $fn after writing: $!\n";
}

# main

warn "Reading and parsing YAML from $src ...\n";
my $yaml = YAML::Tiny->new;
my $c = YAML::Tiny->read($src);
if (!defined $c) {
	die "Failed to read in $src: " . YAML::Tiny->errstr . "\n";
}
warn "  ... parsed successfully.\n";

# get the first document of YAML
$c = $c->[0];

# validate main sections
die "Class definitions not found!\n" if (!defined $c->{'classes'});
die "TOCALL definitions not found!\n" if (!defined $c->{'tocalls'});
warn "  ... main sections found.\n";

# validate classes
my $count_class = 0;
my %class_keys = (
	'class' => 1,
	'shown' => 1,
	'description' => 1
);

my %classes;
foreach my $c (@{ $c->{'classes'} }) {
	$count_class++;
	foreach my $r (keys %class_keys) {
		die sprintf("Class '%s' is missing key '%s'\n", $c->{'class'}, $r)
			if (!defined $c->{$r});
	}
	foreach my $r (keys %{ $c }) {
		die sprintf("Class '%s' has unknown  key '%s'\n", $c->{'class'}, $r)
			if (!defined $class_keys{$r});
	}
	
	$classes{$c->{'class'}} = $c;
}
warn "  ... $count_class device classes found.\n";

# validate tocalls
my $count_tocall = 0;
my %tocall_keys = (
	'tocall' => 1,
	'vendor' => 1,
	'model' => 1,
	'class' => 1,
	'os' => 1,
	'messaging' => 1,
);
my %tocall_keys_mandatory = (
	'tocall' => 1
);

my %tocalls;
foreach my $t (@{ $c->{'tocalls'} }) {
	$count_tocall++;
	foreach my $r (keys %tocall_keys_mandatory) {
		die sprintf("Tocall '%s' is missing key '%s'\n", $t->{'tocall'}, $r)
			if (!defined $t->{$r});
	}
	foreach my $r (keys %{ $t }) {
		die sprintf("Tocall '%s' has unknown  key '%s'\n", $t->{'tocall'}, $r)
			if (!defined $tocall_keys{$r});
	}
	
	if (defined $t->{'class'} && !defined $classes{ $t->{'class'} }) {
		die sprintf("Tocall '%s' has unknown class '%s'\n", $t->{'tocall'}, $t->{'class'});
	}
	
	$tocalls{$t->{'tocall'}} = $t;
}
warn "  ... $count_tocall tocalls found.\n";

#print Dumper($c);


warn "Converting...\n";

my $json_tree = {
	'classes' => \%classes,
	'tocalls' => \%tocalls
};

print_out("$out_dir/tocalls.json", encode_json($json_tree));
print_out("$out_dir/tocalls.pretty.json", to_json($json_tree, { pretty => 1 } ));

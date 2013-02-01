#!/usr/bin/perl -w

# Autoren: Dominik Joho, Zeno Gantner
#
# Aufgabe P1.3
# Berechnen von Default-Logik-Erweiterungen

use strict;
use Formula;
Formula->init;
use Clauses;
use Zchaff;
use DefaultRule;
use DefaultLogic;

my $DEBUG = 0;

my @default_rules;
my $background = Clauses->new;

my $id = 0;   # Zähler-Variable für die Regel-IDs

LINE:
while (<>) {
    next LINE if /^\s*#/;  # ignoriere Kommentarzeilen
    next LINE if /^\s*$/;  # ignoriere Leerzeilen
    my $line = $_;
    chomp $line;   # entferne Zeilenende
    if ($line =~ s/^D\s+//) {
	# Default-Regel
	my $rule = DefaultRule->new($line, $id++);
	push @default_rules, $rule;
    } elsif ($line =~ s/^W\s+//) {
	# Hintergrundwissen
	my $formula = $line;
	my $result = Formula->new($formula);
	if ($result) {
	    # Formel ist syntaktisch korrekt.
	    my @clauses = $result->clauses;
	    $background->add(@clauses);
	} else {
	    warn "Formel $formula ist syntaktisch nicht korrekt.\n";
	}   
    } else {
	warn "Fehler beim Einlesen der Default-Theorie. Zeile: $line\n";
    }
}

print "Finde Erweiterungen ...\n" if $DEBUG;

my $result = [];
my $dummy = [];    # speichert die Wissenbasen der verschiedenen Erweiterungen. Hier nicht benötigt.
DefaultLogic::extension([], \@default_rules, $background, $result, $dummy);

my %extensions;

# Iteriere über gefundene Erweiterungen:
foreach my $extension (@$result) {
    my @sorted_extension = sort @$extension; # sortiere die Regeln in der Erweiterung
    my $string = '';
    foreach my $rule_id (@sorted_extension) {# iteriere über Regeln in der Erweiterung
	$string .= ''.($rule_id+1).' ';      # erstelle geordnete Auflistung der Regeln in einem String
    }
    unless (defined $extensions{$string}) {
	print "$string\n";                   # Ausgabe, falls diese (geordnete) Abfolge von Regeln bisher nicht ausgegeben wurde.
    }
    $extensions{$string}=1;                  # merke diese Erweiterung
}


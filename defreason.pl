#!/usr/bin/perl -w

# Autoren: Dominik Joho, Zeno Gantner
#
# Aufgabe P1.3
# skeptisches und leichtgläubiges Schließen

use strict;
use Formula;
Formula->init;
use Clauses;
use Zchaff;
use DefaultRule;
use DefaultLogic;

my $DEBUG = 0;

my $f;             # zu prüfende aussagenlogische Formel
my @neg_f_clauses; # Klauseln der negierten Formel
if (defined $ARGV[1]) {
    $f = pop @ARGV;
    my $f_neg = '~'.$f;
    my $formula = Formula->new($f_neg);
    @neg_f_clauses = $formula->clauses;
} else {
    die "Aufruf: defreason.pl <default theory> <formula>.\n";
}

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

my $result = [];        # Liste der Erweiterungen.
my $extension_kb = [];  # Liste der Wissensbasen

DefaultLogic::extension([], \@default_rules, $background, $result, $extension_kb);

my $sceptical = 1;
my $credulous = 0;

my %extensions;                    # Hash, in dem die bereits besuchten Erweiterungen gemerkt werden
my @extension_kb = @$extension_kb; # Zuweisung, um sich spätere Dereferenzierungen zu sparen

my $i = 0; # Zählervariable für den passende Zugriff auf die Wissensbasen der einzelnen Erweiterungen
EXTENSION:
 foreach my $extension (@$result) {
    my @sorted_extension = sort @$extension;

    my $string = '';
    foreach my $rule_id (@sorted_extension) {	
	$string .= ''.($rule_id+1).' ';
    }
    unless (defined $extensions{$string}) { # nur Auswertung falls diese Erweiterung noch nicht betrachtet
	my $kb = $extension_kb[$i];
	$kb->add(@neg_f_clauses);
	$kb->write_to_file('tmp.zchaff');
	if (Zchaff::sat('tmp.zchaff')) {
	    $sceptical = 0;
	} else {
	    $credulous = 1;
	}
	last EXTENSION if ($credulous and (not $sceptical)); # Abbruch falls alles schon klar
    }
    $extensions{$string}=1;   # merke diese Auswertung
    $i++;
}

print 'Formula is credulous conclusion: ' .($credulous?'Yes':'No'). "\n";
print 'Formula is skeptical conclusion: ' .($sceptical?'Yes':'No'). "\n";


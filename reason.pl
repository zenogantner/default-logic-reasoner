#!/usr/bin/perl -w

# Autoren: Dominik Joho, Zeno Gantner
#
# Aufgabe P1.1
# Schließen in Aussagenlogik
#

# Mögliche Verbesserungen:
#  - Beim Einlesen von Formeln: T aus Konkunktionen und F aus Disjunktionen sofort entfernen.
#  - Wissensbasis zwischenspeichern, nur mit aktueller Formel zusammenkopieren
#    (so kann man sich die wiederholte Umwandlung in Klauselform sparen)
#  - Tautologien sollen immer aus der Wissensbasis folgen.

use strict;
use Formula;
Formula->init;
use Clauses;
use Zchaff;

my $DEBUG = 0; # falls diese Konstante auf 1 gesetzt wird gibt es ausführlichere Ausgaben.

# Name der Wissenbasis-Datei auf als Parameter => Merke den Namen
my $kb_filename = 'default.kb';
if (defined $ARGV[0]) {
    $kb_filename = $ARGV[0];
}
$kb_filename .= '.zchaff';
print "Klauseldatei: $kb_filename\n" if $DEBUG;


my $f; # zu prüfende aussagenlogische Formel
if (defined $ARGV[1]) {
    $f = pop @ARGV;
}

# Lese die Wissensbasis Zeile für Zeile ein:
my $clauses = Clauses->new;

LINE:
while (<>) {
    next LINE if /^\s*#/;  # ignoriere Kommentarzeilen
    next LINE if /^\s*$/;  # ignoriere Leerzeilen
    chomp $_; # entferne Zeilenende
    my $formula = $_;
    my $result = Formula->new($formula);

    if ($result) {
	# Formel ist syntaktisch korrekt.
        print "Wandle in Klauselform um..." if $DEBUG;
	my @clauses = $result->clauses;
        $clauses->add(@clauses);
        print "\n" if $DEBUG;
    } else {
	warn "Formel $formula ist syntaktisch nicht korrekt.\n";
    }   

    print "\n" if $DEBUG;
}

$f = "~$f";    # negiere Formel, um sie zur Wissenbasis hinzuzufügen.
my $result = Formula->new($f);
if ($result) {
    # Formel ist syntaktisch korrekt.
    my @clauses = $result->clauses;
    $clauses->add(@clauses);

} else {
    warn "Formel $f ist syntaktisch nicht korrekt.\n";
}   

$clauses->write_to_file($kb_filename);
if (Zchaff::sat($kb_filename)) {
    print "No.\n";
} else {
    # Wenn Klauselmenge aus Wissensbasis und negierter Formel nicht erfüllbar ist,
    # so folgt die Formel aus der Wissensbasis.
    print "Yes.\n";
}

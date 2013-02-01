package Clauses;

# Autoren: Dominik Joho, Zeno Gantner
#
# Package/Klasse zum Handhaben von Klauselmengen.
#
#Clauses
# Methoden:
#->new			      Konstruktor
#->add(array)		      fügt weitere Klauseln hinzu
#->varnum		      gibt Zahl der vorkommenden Variablen zurück
#->clausenum		      gibt Zahl der Klauseln zurück
#->delete_duplicates	      löscht doppelt vorkommend Klauseln
#->write_to_file(filename)    schreibt die Klauseln im zchaff-Format in
#                             eine Datei
#->get_clauses
#->set_clauses
#->clone                      erstellt volle Kopie eines Objekts
#
# Interne Funktionen:
# clauseFormat                wandelt Klauseln der Form "a b c" in die Form "1 2 3" um.

#
# Konstruktor für Objekte vom Typ Clause
#
sub new($){
    my $type = shift;

    my %data;
    $data{'clauses'} = [];

    my $self = \%data;

    bless $self;
    return $self;
}

# 
# Füge neue Klauseln zur Klauselmenge hinzu.
#
# add: ARRAY OF STRING -> .
#
# Argumente:
#  @new_clauses     Array mit den hinzuzfügenden Klauseln
sub add($@){
    my $self = shift;
    my @new_clauses = @_;

    my @clauses = $self->get_clauses;

    push @clauses, @new_clauses;

    $self->set_clauses(\@clauses);
}

#
# Gibt die Zahl der verwendeten Variablen in einer Klauselmenge zurück.
#
# varnum:  -> INT
#
# In Wirklichkeit ist es nicht die Zahl der Variablen, sondern die
# höchste Index-Nummer der vorkommenden Variablen.
# Für eine Klauselmenge, in der nur die Variable "z" vorkommt, erhalten
# wir den Wert 26.
# Dies ist notwendig, da zchaff sonst mit einer Fehlermeldung abbricht.
#
sub varnum($) {
    my $self = shift;
    my @clauses = $self->get_clauses;

    my $max = 0;

    foreach my $clause (@clauses) {
	my @literals = split ' ', $clause;

	foreach my $literal (@literals) {
	    my $number;
	    if ($literal =~ /^(-?)([a-z])$/) {
		$number = ord($2) - 96;
	    } else {
		warn "Fehler in Clauses.varnum: Literal-Match fehlgeschlagen. Literal: $literal.\n";
	    }
	    if ($number>$max) {
		$max=$number;
	    }
	}

    }

    return $max;
}

#
# Gibt die Anzahl der Klauseln in der Klauselmenge zurück.
#
# clausenum: . -> INT
#
sub clausenum($) {
    my $self = shift;

    my @clauses = $self->get_clauses;
    my $num = @clauses;
    return $num;
}

#
# Löscht mehrfach vorkommende Klauseln aus der Klauselmenge.
#
# delete_duplicates: . -> .
#
sub delete_duplicates {
    my $self = shift;

    my @clauses = $self->get_clauses;

    my %clause_hash;
    foreach my $clause (@clauses) {
	$clause_hash{$clause} = 1;
    } 
    @clauses = keys(%clause_hash);

    $self->set_clauses(\@clauses);
}

#
# Speichert die Klauselmenge im Dateiformat von zchaff ab.
#
# write_to_file: STRING -> .
#
# Argumente:
#  $filename        Name der Datei, in der Klauseln gespeichert werden sollen.
#
sub write_to_file {
    my $self = shift;
    my $filename = shift;

    $self->delete_duplicates;
    my $clausenum = $self->clausenum;     # aktualisiere Zahl der Klauseln.

    my $varnum = $self->varnum;
    open KB_FILE, ">$filename";               # öffne Wissenbasis-Datei
    print KB_FILE "p cnf $varnum $clausenum\n";  # schreibe Startzeile
    my @clauses = $self->get_clauses;

    foreach my $clause (@clauses) {
	print KB_FILE clauseFormat($clause);     # schreibe Klausel in Datei
    }

    print KB_FILE "\n";
    close KB_FILE; # schließe Wissensbasis-Datei
}

#
# Erstelle eine Kopie der Klauselmenge und gib sie zurück.
#
# clone: . -> Clauses
#
sub clone($) {
    my $self = shift;
    
    my @clauses = $self->get_clauses;
    my $copy = Clauses->new;
    $copy->add(@clauses);
    return $copy;
}


#
# Gebe Klauseln zurück.
#
# get_clauses: -> ARRAY OF STRING
#
sub get_clauses($) {
    my $self = shift;

    my $ref = $$self{'clauses'};
    my @clauses = @$ref;

    return @clauses;
}

#
# Setze Klauseln
#
# set_clauses: REFARRAY -> .
#
# Argumente
#  $clauses        Klauselmenge, die das Objekt übernehmen soll
#
sub set_clauses($$) {
    my $self = shift;
    my $clauses = shift;

    $$self{'clauses'} = $clauses;
}

#
# Schreibt eine Klausel in das von zchaff erwartete Format um.
#
# clauseFormat: STRING -> STRING
#
# Schreibt die mit den Buchstaben a-z benannten Variablen in Zahlen
# 1-26 um.
#
sub clauseFormat {
    my $clause = shift;

    my @literals = split ' ', $clause;
    my $result = '';
    
    foreach my $literal (@literals) {
	$literal =~ /^(-?)([a-z])$/;
	my $number = ord($2) - 96;
	$result .= "$1$number ";
    }
    $result .= "0\n";
    return $result;
}

1;

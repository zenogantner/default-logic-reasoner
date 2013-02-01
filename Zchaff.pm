package Zchaff;

# Autoren: Dominik Joho, Zeno Gantner
#
# Dieses Package enthält die Funktion sat, welche verwendet wird,
# um die Erfüllbarkeit einer Klauselmenge mit Hilfe von zchaff
# zu prüfen.

#
# Prüfe auf Erfüllbarkeit.
#
# sat FILENAME -> BOOL
#
# Prüft durch den Aufruf von zchaff, ob ein Menge von Klauseln,
# welche in der Datei steht, deren Name an die Funktion übergeben wird,
# erfüllbar ist.
#
sub sat($) {
    my $filename = shift;

    my $zchaff_out = `./zchaff $filename`; # rufe zchaff auf und speichere die Ausgabe
    $zchaff_out =~ /RESULT:\s+(SAT|UNSAT)/s or warn "Fehler beim Aufrufen von zchaff.\n";
    if ($1 eq 'UNSAT') {
	return 0;
    } elsif ($1 eq 'SAT') {
	return 1;
    } else {
	warn "Fehler beim Aufrufen von zchaff.\n";
	return -1;
    }    
}

1;

package Formula;

# Package/Klasse für das Einlesen und Umformen von aussagenlogischen Formeln.
#
# Autoren: Dominik Joho, Zeno Gantner
#
# Methoden:
#->new(input)	    Konstruktor, erstellt neues Formel-Objekt gemäß Eingabe
#->new_from_tree    alternativer Konstruktor
#->string	    gibt String-Repräsentation des Syntaxbaumes zurück
#->tree		    gibt Referenz auf den Syntaxbaum der Formel zurück
#->to_nnf	    wandelt die Formel in NNF um
#->to_cnf	    wandelt die Formel in KNF um
#->clauses	    gibt die in der Formel enthaltenen Klauseln zurück
#->init	  	    Klassenmethode zur Initialisierung des Parsers
#->get_state        gibt Status des Objekts zurück ('parsed', 'nnf', 'cnf')

# Anmerkung:
#  - Die Unterroutinen tree2string, cnf, nnf, cnf_ersetzen, is_... usw. sind nicht als Methoden, auch nicht als statische
#    Methoden, definiert. Sie können von außerhalb des Pakets nicht sinnvoll aufgerufen werden.


require Parse::RecDescent;

# Initialisierung der Klasse
sub init{

# Definiere Grammatik für die Zeilen in der Wissenbasis-Datei:
    my $grammar = q {
      phi:
          '(' phi '+' phi ')'   { ['+', $item[2], $item[4]] }
	| '(' phi '*' phi ')'   { ['*', $item[2], $item[4]] }
	| '(' phi '->' phi ')'  { ['+', ['!', $item[2]], $item[4]] }   # wandle Implikation gleich in Disjunktion um
	| '(' phi '<->' phi ')' { ['+', ['*', $item[2], $item[4]],
	    			        ['*', ['!', $item[2]],
				        ['!', $item[4]] ] ] }
  	      # a <-> b entspricht ((a*b)+(~a*~b))
	      # zusätzlich, damit wir den worst case für KNF besser testen können ;-)
	| '~' '~' phi           { $item[3] }
        | '~' phi               { ['!', $item[2]] }
        | 'T'                   { ['+', \'a', ['!', \'a']] }
        | 'F'                   { ['*', \'a', ['!', \'a']] }
        | /[a-z]/               { \$item[1] }
    };

    # Erzeuge Parser für die definierte Grammatik:
    $parser = Parse::RecDescent->new($grammar) or die "Fehlerhafte Grammatik-Definition!\n";
}

#
# Gebe Referenz auf das Parser-Objekt dieser Klasse zurück.
#
# get_parser: . -> Parse::RecDescent
sub get_parser($) {
    return $parser;
}

#
# Konstruktor für Objekte vom Typ Formula
#
# new: STRING -> Formula
#
# Argument
#  $input      vollständig geklammerter aussagenlogischer Ausdruck
#
sub new {
    my $type = shift;
    my $input = shift;

    my %data;

    my $tree = $parser->phi(\$input); # parse Formel, Ergebnis: Syntaxbaum
    if ($tree and ($input eq '')) {
	# Formel ist syntaktisch korrekt.
	
	$data{'tree'} = $tree;
	$data{'state'} = 'parsed';

	my $self = \%data;
	bless $self;
	return $self;
    } else {
	return 0;
    }
}

#
# Erstellt neues Objekt aus Syntaxbaum.
#
# Argument
#  $tree      Syntaxbaum einer aussagenlogischen Formel
#
sub new_from_tree($$) {
    my $type = shift;
    my $tree = shift;

    my %data;

    $data{'tree'} = $tree;
    $data{'state'} = 'parsed';

    my $self = \%data;
    bless $self;
    return $self;
}

#
# Gebe internen Status (leer, 'parsed', 'nnf', 'cnf') des Objekts zurück.
#
# get_state: . -> STRING
#
sub get_state($) {
    my $self = shift;
    return $$self{'state'};
}

#
# Gebe den Syntaxbaum als String aus.
#
# string: . -> STRING
#
# Der Syntaxbaum wird als geklammerter, LISP-artiger Ausdruck mit den Operatoren +, *, ! ausgegeben.
#
sub string($) {
    my $self = shift;

    my $tree = $$self{'tree'};
    return tree2string($tree);
}

#
# Gebe Referenz auf die Referenzen-/Variablenliste zurück, die den Syntaxbaum innerhalb des Objekts repräsentiert.
#
# tree: . -> (REFARRAY|STRING)
#
sub tree($) {
    my $self = shift;
    return $$self{'tree'};
}

#
# Wandle Formel in NNF um.
#
# to_nnf: . -> .
#
sub to_nnf($) {
    my $self = shift;

    my $nnf = nnf($$self{'tree'});
    $$self{'state'} = 'nnf';
    $$self{'tree'} = $nnf;
}

#
# Wandle Formel in KNF um.
#
# to_cnf: . -> .
#
sub to_cnf($) {
    my $self = shift;

    return 1 if ($$self{'state'} eq 'cnf');

    unless ($$self{'state'} eq 'nnf') {
	$self->to_nnf;
    }
    my $cnf = cnf($$self{'tree'});
    $$self{'state'} = 'cnf';
    $$self{'tree'} = $cnf;
}

#
# Gibt Klauseln der Formel als Array von Strings zurück.
#
# clauses: . -> ARRAY OF STRING
#
sub clauses($) {
    my $self = shift;
    
    unless ($$self{'state'} eq 'cnf') {
	$self->to_cnf;
    }

    return get_clauses($$self{'tree'});
}




# FUNKTIONEN
# NICHT VON AUSSERHALB DES PAKETS AUFRUFEN!!!



# Funktion zur Berechnung der konjunktiven Normalform.
#
# cnf: (REFARRAY|REFSCALAR) -> (REFARRAY|REFSCALAR)
#
# cnf gibt zum Syntaxbaum einer aussagenlogischen Formel in Negations-Normalform
# den Syntaxbaum einer äquivalenten Formel in konjunktiver Normalform zurück.
#
sub cnf {
   my $node = shift;

   my $mod = 1;

   do {
       # Ersetze "schlechte" oder-Vorkommen:
       ($mod, $node) = cnf_ersetzen($node);
   } while ($mod); # ersetze so lange, bis keine Ersetzung mehr möglich

   return $node;
}


# Hilfsfunktion zur Berechnung der konjunktiven Normalform.
#
# cnf: (REFARRAY|REFSCALAR) -> (REFARRAY|REFSCALAR)
#
# Überprüft einen Knoten im Syntaxbaum, ob er eine Disjunktion von Konjunktionen
# ist. In diesem Fall wird der Knoten "ausmultipliziert" (vgl. Schöning: Logik für Informatiker, S. 29)
# und die drei darunter liegenden Teilbäume in KNF umgewandelt,
# ansonsten die beiden darunter liegenden Knoten ausgewertet.
# Falls es sich bei dem Knoten um ein Blatt des Syntaxbaumes (also ein Literal)
# handelt, so ist nichts mehr zu tun.
# 
# "Premature optimization is the root of all evil." -- Sir Charles Anthony Richard Hoare
#
# Das lässt sich bestimmt noch optimieren. Ist aber sowieso NP-vollständig.
#
sub cnf_ersetzen {
    my $node = shift;

    if ( is_disj($node) ) { # "schlechte" Teilformeln?
	
       my $left = $$node[1];   # Referenz auf linke Formel
       my $right = $$node[2];  # Referenz auf rechte Formel
       if ( is_conj($right) ) {
	   return (1, ['*', ['+', cnf($left), cnf($$right[1]) ], ['+', cnf($left), cnf($$right[2]) ] ]);
	   # ersetze ((F+(G*H)) durch ((F+G)*(F+H))
       } elsif ( is_conj($left) ) {
	   return (1, ['*', ['+', cnf($$left[1]), cnf($right) ], ['+', cnf($$left[2]), cnf($right) ] ]);
	   # ersetze ((F*G)+H) durch ((F+H)*(G+H))       
       } else {
	   # keine Disjunktion von Konjunktionen?
	   my ($lmod, $lcnf) = cnf_ersetzen($left);
	   my ($rmod, $rcnf) = cnf_ersetzen($right);
	   return (($lmod or $rmod), ['+', $lcnf, $rcnf]);
       }
   } elsif ( is_conj($node) ) {
       return (0, ['*', cnf($$node[1]), cnf($$node[2]) ]);
   } elsif ( is_neg($node) or is_var($node) ) {
       # Literale: Variablen oder negierte Variablen
       #           Hier kann nichts mehr umgeformt werden.
       return (0, $node);
   } else {
       warn "Fehler in cnf_ersetzen.\n";
   }
}   

#
# Funktion zur rekursiven Berechnung der Negativ-Normalform.
#
# nnf: (REFARRAY|REFSCALAR) -> (REFARRAY|REFSCALAR)
#
# nnf gibt zum Syntaxbaum einer beliebigen aussagenlogischen Formel (lediglich
# Negation, Konjunktion und Disjunktion sind als Operatoren erlaubt)
# den Syntaxbaum einer äquivalenten Formel in Negativ-Normalform zurück.
#
sub nnf {
    my $node = shift;

    if (is_conj($node)) {
	return ['*', nnf($$node[1]), nnf($$node[2])];
    } elsif (is_disj($node)) {
	return ['+', nnf($$node[1]), nnf($$node[2])];
    } elsif (is_neg($node)) {
	my $f = $$node[1];
	if (is_var($f)) {
	    return $node;       # negiertes Literal unverändert zurückgeben
	} elsif (is_neg($f)) {
	    return nnf($$f[1]); # 2 Negationen eliminieren, Rest zurückgeben
	} elsif (is_conj($f)) {
	    # negierte Konjunktion: Negation rein
	    return ['+', nnf(['!', $$f[1]]), nnf(['!', $$f[2]])];
	} elsif (is_disj($f)) {
	    # negierte Disjunktion: Negation rein
	    return ['*', nnf(['!', $$f[1]]), nnf(['!', $$f[2]])];
	} else {
	    warn "Fehler in nnf.\n";
	}
    } elsif (is_var($node)) {
	return $node;
    } else {
	$string = tree2string($node);
	warn "Fehler in nnf. node is $string\n";
    }
}

#
# Funktion zur Überführung eines Syntaxbaumes in einen String.
# Wird von der Methode string aufgerufen.
#
# tree2string: (REFARRAY|REFSCALAR) -> STRING
#
# tree2string erzeugt aus der Syntaxbaum-Repräsentation einer aussagenlogischen
# Formel, die Variablen, Konjunktionen, Disjunktionen und Negationen enthalten
# kann, einen String, der wie ein Lambda-Term der Formel aussieht, also ähnlich
# wie ein Scheme-Ausdruck aussieht:
#   Zum Beispiel wird für den Syntaxbaum der Formel (a+~b) die Zeichenkette
#   (+ a (! b)) produziert.
#
sub tree2string {
    my $node = shift;
    
       
    if (is_conj($node)) {
	return '(* ' . tree2string($$node[1]) . ' ' . tree2string($$node[2]) . ')';
    } elsif (is_disj($node)) {
	return '(+ ' . tree2string($$node[1]) . ' ' . tree2string($$node[2]) . ')';
    } elsif (is_neg($node)) {
	return '(! ' . tree2string($$node[1]) . ')';
    } elsif (is_var($node)) {
	return $$node;
    } else {
	warn "Fehler in tree2string. node ist $node\n";
    }
}

#
# Prüfe ob Syntaxbaum eine Negation als Wurzel hat.
#
# is_neg: (REFARRAY|REFSCALAR) -> BOOL
#
# Gibt 1 bzw. true zurück, wenn der gegebene Syntaxbaum als
# Wurzel ein Negationssymbol hat.
#
sub is_neg {
    my $node = shift;

    return ((ref($node) eq 'ARRAY') and ($$node[0] eq '!'));
}

#
# Prüfe ob Syntaxbaum eine Konjunktion als Wurzel hat.
#
# is_conj: (REFARRAY|REFSCALAR) -> BOOL
#
# Gibt 1 bzw. true zurück, wenn der gegebene Syntaxbaum als
# Wurzel ein Konjunktionssymbol hat.
#
sub is_conj {
    my $node = shift;

    return ((ref($node) eq 'ARRAY') and ($$node[0] eq '*'));
}


#
# Prüfe ob Syntaxbaum eine Disjunktion als Wurzel hat.
#
# is_disj: (REFARRAY|REFSCALAR) -> BOOL
#
# Gibt 1 bzw. true zurück, wenn der gegebene Syntaxbaum als
# Wurzel ein Disjunktionssymbol hat.
#
sub is_disj {
    my $node = shift;

    return ((ref($node) eq 'ARRAY') and ($$node[0] eq '+'));
}

#
# Prüfe ob Syntaxbaum eine Variable ist.
#
# is_var: (REFARRAY|REFSCALAR) -> BOOL
#
# Gibt 1 bzw. true zurück, wenn der gegebene Syntaxbaum eine
# Variable repräsentiert.
#
sub is_var {
    my $node = shift;

    return (ref($node) eq 'SCALAR');
}

#
# Gibt für eine Formel in konjunktiver Normalform (bzw. für deren Syntaxbaum)
# die zugehörige Klauselmenge zurück.
#
# get_clauses: (REFARRAY|REFSCALAR) -> ARRAY OF STRING
#
# Die Literale in jeder Klausel sind sortiert, zuerst die
# negativen Klauseln, dann die positiven, jeweils alphabetisch sortiert.
#
sub get_clauses {
    my $node = shift;

    my @clauses;

    if ( is_disj($node) ) {
	my @clause = disj2clause($node);  # wandle Disjunktion in Klausel um
	@clause = sort @clause;           # sortiere Literale in der Klausel
	my $clause = shift @clause;       # Schreibe erstes Literal in die String-Repräsentation der Klausel
	my $last = $clause;               # merke letztes Literal
        foreach my $literal (@clause) {
	    unless ($literal eq $last) {  # falls Literal noch nicht im String
		$clause .= ' '.$literal;  #  ... hänge es an den String an
		$last = $literal;         # merke letztes Literal
	    }
        }
	push (@clauses, $clause) unless is_tautology($clause);

    } elsif ( is_conj($node) ) {
	my @left_clauses = get_clauses($$node[1]);
	my @right_clauses = get_clauses($$node[2]);
	@clauses = sort (@left_clauses, @right_clauses); #TO DO: ist das hier nötig????
    } elsif ( is_var($node) or is_neg($node) ) {
        @clauses = (disj2clause($node));	
    } else {
	warn "Fehler in get_clauses!\n";
    }
    
    return @clauses;
}

#
# Wandelt eine Disjunktion von Literalen in eine Klausel um
#
# disj2clause: REFARRAY -> (STRING|ARRAY OF STRINGS)
#
sub disj2clause {
    my $node = shift;

    if ( is_disj($node) ) {
	# "echte" Disjunktion: zerlegen
	return ( disj2clause($$node[1]), disj2clause($$node[2]) );
    }
    if ( is_var($node) ) {
	# Variable: Variablennamen zurückgeben
	return ($$node);
    } elsif ( is_neg($node)) {
	# negierte Variable: Variablennamen mit vorgesetztem Minus zurückgeben
        my $var = $$node[1];
	return ('-'.$$var);
    } else {
	warn "Fehler in disj2clause!\n";
	return 0;
    }
}

#
# Prüfe, ob Klausel eine Tautologie ist.
#
# is_tautology: STRING -> BOOL
#
sub is_tautology($) {
    my $clause = shift;
    
    my @literals = split ' ', $clause; # Schreibe alle Literale der Klausel in die Liste @literals
    my %variables;     # Hash, welches die in der Klausel vorkommenden Variablen und ihr "Vorzeichen" enthalten wird.
    
  LITERAL:
    foreach my $literal (@literals) {
	$literal =~ /^(-?)([a-z])$/;
	my $minus;
	if ( $1 eq '-') {
	    $minus = '-';
	} elsif ( $1 eq '') {
	    $minus = '+';
	} else {
	    warn "Fehler in Funktion is_tautology\n";
	}
	my $variable = $2;
	if ( defined $variables{$variable} ) {
	    unless ($minus eq $variables{$variable}) {
		# Falls Variable schon mit anderem Vorzeichen in der Klausel vorkommt, gib "wahr" zurück.
		return 1;
	    }
	} else {
	    $variables{$variable} = $minus; # merke Variable mit Vorzeichen
	}
    }

    # Falls keine Variable mit beiden Vorzeichen vorkommt, gibt "falsch" zurück.
    return 0;
}

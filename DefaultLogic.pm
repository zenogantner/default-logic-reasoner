package DefaultLogic;

# Package für Default-Logik-Operationen
#
# Autoren: Dominik Joho, Zeno Gantner
use Zchaff;
use DefaultRule;

# Prototypen-Definitionen:
sub anwendbar($$$);
sub extension($$$$$);
sub beta_consistent($$);
sub remove_element($$);

#
# Rekursive Funktion zur Berechnung der Erweiterungen einer Default-Theorie.
#
# Parameter
#  $used_rules        Liste der schon angewandten Regeln
#  $available_rules   Liste der noch verfügbaren Regeln
#  $kb                aus den bisherigen Regelanwendungen abgeleitete Klauselmenge
#  $result            Referenz auf die Liste der Erweiterungen (bzw. ihrer Regeln)
#  $extension_kb      Referenz auf die Liste der Wissensbasen der einzelnen Erweiterungen
sub extension($$$$$) {
    my $used_rules = shift;
    my $available_rules = shift;
    my $kb = shift;
    my $result = shift;
    my $extension_kb = shift;

    my @used_rules = @$used_rules;
    my @available_rules = @$available_rules;

    my $end = 1;

    # Überprüfe alle noch nicht angewandten Regeln auf ihre Anwendbarkeit:
    foreach my $rule (@available_rules) {
	if (anwendbar($rule, $used_rules, $kb)) {
	    my $new_kb = $kb->clone;
	    $new_kb->add($rule->get_conclusion);
	    if (beta_consistent($used_rules, $new_kb)) {
		print $rule->string." anwendbar\n" if $DEBUG;
		my @new_used_rules = @used_rules;
		push @new_used_rules, $rule;
		my @new_available_rules = remove_element($rule, $available_rules);

		extension(\@new_used_rules, \@new_available_rules, $new_kb, $result, $extension_kb);

		$end = 0;
	    } else {
		print $rule->string." nicht anwendbar weil alte Beta-Konsistenz verletzt.\n" if $DEBUG;
	    }
	} else {
	    print $rule->string." nicht anwendbar.\n" if $DEBUG;
	}
    }

    if ($end) {
	my @extension;
	foreach my $rule (@used_rules) {
	    push @extension, $rule->get_id;
	}
	push @$result, \@extension;
	push @$extension_kb, $kb;
    }

}


# Prüft, ob eine Regel in der momentanen Situation anwendbar ist.
# (ausgenommen die Konsistenzbedingungen der vorherigen Regeln)
#
# anwendbar: DefaultRule, REFARRAY of DefaultRule, Clauses -> BOOL
#
# Wichtig: $kb wird nicht von dieser Prozedur verändert!!
# Argumente:
#  $rule          zu prüfende Regel
#  $used_rules    bereits angewandte Regeln
#  $kb            Wissensbasis
sub anwendbar($$$) {
    my $rule = shift;
    my $used_rules = shift;
    my $kb = shift;

    my $kb_copy = $kb->clone;

    $kb_copy->add($rule->get_neg_precondition);
    $kb_copy->write_to_file('tmp.zchaff');           # Lässt sich die Vorbedingung aus der Wissensbasis ableiten?
    my $precond_ok = not Zchaff::sat('tmp.zchaff');  # Vorbedingung ok?
    unless ($precond_ok) {
	return 0;     # falls nicht, gleich Abbruch und Rückgabe "false"
    }

    $kb_copy = $kb->clone;
    $kb_copy->add($rule->get_consistence);           # Lässt sich die Konsistenzbedingung nicht widerlegen?
    $kb_copy->write_to_file('tmp.zchaff');
    my $cons_ok = Zchaff::sat('tmp.zchaff');         # Konsistenzbedingung ok?

    return $cons_ok;
}


#
# Prüfe, ob die vorgenommene Regelanwendung die Konsistenzbedingungen der vorher angewandten Regeln
# verletzt.
#
# beta_consistent: Clauses -> BOOL
#
# Argumente:
#  $used_rules            alte Regeln
#  $kb                    aktuelle Wissensbasis
sub beta_consistent($$) {
    my $used_rules = shift;
    my $kb = shift;

    # Prüfe, ob Konsistenzbedingungen der alten Regeln nach der Anwendung der aktuellen noch gelten würden:
    foreach my $used_rule (@$used_rules) {
	my $kb_beta = $kb->clone;	   # kopiere Wissensbasis (um Konsistenzregeln zu prüfen)
	$kb_beta->add($used_rule->get_consistence);
	$kb_beta->write_to_file('tmp.zchaff');
	unless ( Zchaff::sat('tmp.zchaff') ) {
	    # Falls nicht erfüllbar: Konsistenzregel wurde verletzt.
	    return 0;
	}	
    }

    # Falls alle Konsistenzbedingungen der bereits verwendeten Regeln nicht widerlegbar sind, gebe "wahr" zurück:
    return 1;
}

#
# Entferne ein Element aus einer Liste.
#
# remove_element: DefaultRule, ARRAY OF DefaultRule -> ARRAY OF DefaultRule
sub remove_element($$) {
    my $element = shift;
    my $list = shift;

    my @result_list;

    foreach my $e (@$list) {
	unless ($e->get_id == $element->get_id) {
	    push @result_list, $e;
	}
    }

    return @result_list;
}

1;

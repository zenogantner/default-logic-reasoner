package DefaultRule;

# Package/Klasse zum Einlesen und Speichern von Default-Regeln
#
# Autoren: Dominik Joho, Zeno Gantner

use Formula;
Formula->init;

# Konstruktor für Objekte vom Typ DefaultRule
sub new{
    my $type = shift;
    my $line = shift;
    my $id = shift;

    my %data;
    my $parser = Formula->get_parser;
    my $line_copy = $line;
    my ($not_alpha, $beta, $gamma);
    # Vorbedingung muss gelten, sollte deswegen später in negierter Form
    # in unsere Wissenbasis:
    $line = '~'.$line;
    unless ($not_alpha = $parser->phi(\$line)) {
	warn "Ungültige Default-Regel: $line_copy.\n";
	return 0;
    }
    # Konsistenzbedingung darf nicht widerlegbar sein, für die spätere
    # Verwendung ist es günstiger, sie in nicht negierter Form zu speichern:
    unless ($beta =  $parser->phi(\$line)) {
	warn "Ungültige Default-Regel: $line_copy.\n";
	return 0;
    }
    unless ($gamma = $parser->phi(\$line) and ($line eq '')) {
	warn "Ungültige Default-Regel: $line_copy.\n";
	return 0;
    }
    
    my @np   = Formula->new_from_tree($not_alpha)->clauses;
    my @cons = Formula->new_from_tree($beta)->clauses;
    my @conc = Formula->new_from_tree($gamma)->clauses;

    $data{'neg_precondition'} = \@np;
    $data{'consistence'} =  \@cons;
    $data{'conclusion'} = \@conc;
    $data{'id'} = $id;

    my $self = \%data;

    bless $self;
    return $self;
}

sub get_neg_precondition {
    my $self = shift;
    my $ref = $$self{'neg_precondition'};
    my @clauses = @$ref;
    return @clauses;
}
sub get_consistence {
    my $self = shift;
    my $ref = $$self{'consistence'};
    my @clauses = @$ref;
    return @clauses;
}
sub get_conclusion {
    my $self = shift;
    my $ref = $$self{'conclusion'};
    my @clauses = @$ref;
    return @clauses;
}

sub get_id {
    my $self = shift;
    return $$self{'id'};
}

sub string {
    my $self = shift;
    my $string = 'Regel '.$self->get_id.': ';
    foreach my $clause ($self->get_neg_precondition) {
	$string .= $clause.", ";
    }
    $string .= "|";
    foreach $clause ($self->get_consistence) {
	$string .= $clause.", ";
    }
    $string .= "|";
    foreach $clause ($self->get_conclusion) {
	$string .= $clause.", ";
    }
    $string .= "\n";
    return $string;
}

1;

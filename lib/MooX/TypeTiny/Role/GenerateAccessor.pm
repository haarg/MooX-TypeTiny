package MooX::TypeTiny::Role::GenerateAccessor;
use Moo::Role;
use Sub::Quote qw(quotify sanitize_identifier);
use Scalar::Util qw(blessed);

around _generate_isa_check => sub {
  $Error::TypeTiny::CarpInternal{$_} = 1
    for grep /\A(?:MooX?|Method::Generate)::/, keys %Carp::CarpInternal;

  my $orig = shift;
  my $self = shift;
  my ($name, $value, $check, $init_arg) = @_;
  return $self->$orig(@_)
    unless blessed $check && $check->isa('Type::Tiny');

  my $var = '$isa_check_for_'.sanitize_identifier($name);
  $self->{captures}->{$var} = \$check;

  my $varname = defined $init_arg
    ? sprintf('$args->{%s}', quotify($init_arg))
    : sprintf('$self->{%s}', quotify($name));

  my $assertion = $check->inline_assert(
    $value,
    $var,
    mgaca           => 0,
    attribute_name  => $name,
    attribute_step  => 'isa check',
    varname         => $varname,
  );
  $assertion =~ s/;\z//;
  return $assertion;
};

around _generate_coerce => sub {
  $Error::TypeTiny::CarpInternal{$_} = 1
    for grep /\A(?:MooX?|Method::Generate)::/, keys %Carp::Internal;

  my $orig = shift;
  my $self = shift;
  my ($name, $value, $coerce, $init_arg) = @_;
  return $self->$orig(@_)
    unless blessed $coerce && $coerce->isa('Type::Coercion');

  my $var = '$coercion_for_'.sanitize_identifier($name);
  $self->{captures}->{$var} = \$coerce;
  $coerce->can_be_inlined ? $coerce->inline_coercion($value) : "${var}->coerce(${value})"
};

1;

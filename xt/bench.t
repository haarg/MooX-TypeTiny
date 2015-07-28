use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Type::Tiny;
use Sub::Quote qw(qsub);
use Types::Standard qw(Int Num);
use Dumbbench;
use Dumbbench::Instance::PerlSub;

use Data::Dumper;

my $int;
BEGIN {
  $int = Int->plus_coercions(Num,=> qsub q{ int $_ });
}

BEGIN {
  package MooClassMXTT;
  use Moo;
  use MooX::TypeTiny;

  has attr_isa        => (is => 'rw', isa => $int );
  has attr_coerce     => (is => 'rw', coerce => $int->coercion );
  has attr_isa_coerce => (is => 'rw', isa => $int, coerce => $int->coercion );
}

BEGIN {
  package MooClass;
  use Moo;

  has attr_isa        => (is => 'rw', isa => $int );
  has attr_coerce     => (is => 'rw', coerce => $int->coercion );
  has attr_isa_coerce => (is => 'rw', isa => $int, coerce => $int->coercion );
}

my $goto = MooClassMXTT->new;
my $wanto = MooClass->new;

for my $attr (qw(attr_isa attr_coerce attr_isa_coerce)) {
  for my $value (1, 1.2, "welp") {
    eval { $wanto->$attr($value) };
    eval { $goto->$attr($value) };

    my $bench = Dumbbench->new(
      target_rel_precision => 0.005,
      initial_runs         => 20,
    );
    $bench->add_instances(
      Dumbbench::Instance::PerlSub->new(
        name => 'orig',
        code => sub { eval { $wanto->$attr($value) } },
      ),
      Dumbbench::Instance::PerlSub->new(
        name => 'got',
        code => sub { eval { $goto->$attr($value) } },
      ),
    );
    $bench->run;

    my %results = map { $_->name => $_->result->number } $bench->instances;
    cmp_ok $results{got}, '<=', $results{orig},
      "improved speed checking $attr with $value";
  }
}

done_testing;

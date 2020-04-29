use strict;
use warnings;
use Test::More;

BEGIN { ::diag "starting"; }
BEGIN {
    package MyParent;
    use Moo;
    use MooX::TypeTiny;
    use Types::Standard 'Str';

    BEGIN { ::diag "looking for subs"; }
    # dirty namespace::clean reimplementation
    my %subs;
    BEGIN {
      no strict 'refs';
      $subs{$_} = 1 for grep defined &{$_}, keys %{__PACKAGE__ . '::'};
    }

    BEGIN { ::diag "got subs: " . join(' ', sort keys %subs); }

    has mystr => (
        is => 'ro',
        isa => Str,
    );

    BEGIN { ::diag "deleting subs"; }
    BEGIN {
        no strict 'refs';
        delete ${__PACKAGE__.'::'}{$_} for keys %subs;
    }
    BEGIN { ::diag "deleted subs"; }
}

BEGIN {
    package MyChild;
    use parent 'MyParent';
}

ok defined &MyParent::new, 'cleaning does not remove constructor';

my $parent = MyParent->new(mystr => 'hi');
is $parent->mystr, 'hi', 'cleaned class constructs properly';

my $child = MyChild->new(mystr => 'morehi');
is $child->mystr, 'morehi', 'cleaned child class constructs properly';

done_testing;

#!/usr/bin/env perl
use strict; use warnings; use v5.30;
=head1 TASK08 Наследование
Есть следующие классы:
package AA;
sub func { print “AA\n” }
package BB;
use parent ‘AA’;
sub func { print “BB\n”; shift->SUPER::func(@_); }
package CC;
use parent ‘AA’;
sub func { print “CC\n”; shift->SUPER::func(@_); }
package DD;
use parent qw/BB CC/;
sub func { print “DD\n”; shift->SUPER::func(@_); }
В каких классах и в каком порядке будут вызваны функции func, если
вызвать DD->func?
По какому принципу мы должны построить наследование, если нам
необходимо, чтобы при вызове DD->func, были вызваны функции по
всех этих классах, и не меняя иерархию наследования?
=head1 DESCRIPTION
Вызоовутся DD, BB, AA
У SUPER нет функционала для нескольких родителей, вызвать нужно ручками
Ниже упрощённый вариант, как релизовать DD->func, чтобы вызвались все
Отдельно для себя нужно решить, хочется ли вызывать AA->func два раза
=cut
{
    package AA;
    sub func { print "AA\n"; }

    package BB;
    push our @ISA, "AA"; # use parent "AA";
    sub func { print "BB\n"; shift->SUPER::func(@_); }

    package CC;
    push our @ISA, "AA"; # use parent "AA";
    sub func { print "CC\n"; shift->SUPER::func(@_); }

    package EE; # вспомогательный класс с пустой функцией
    sub func {}

    package DD;
    push our @ISA, qw/BB CC/; # use parent qw/BB CC/;

    sub func {    
        say "DD";
        my $class = shift;
        unshift @CC::ISA, "EE";     # если не нужно, чтобы AA->func вызывалась 2 раза
        $_->func(@_) for @ISA;
        shift @CC::ISA;             # восствнвливаем как было
    }
}

DD->func;
 
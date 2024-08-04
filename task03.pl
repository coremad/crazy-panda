#!/usr/bin/env perl
use strict; use warnings; use v5.30;
=head1 TASK03  Типы объявления переменных
Чем отличаются между собой переменные, объявленные с помощью my,
our,local, state?
    func() for 1..10;
    sub func {
        XXX $var;
        $var++;
        say “A=$var”;
    }
Что и почему выведется, если в качестве XXX подставлять
вышеуказанные 4 типа объявления переменных?
=head1 ANSWERE
См. код ниже
В случае my выведутся "A=1" 10 раз, т.к. у переменных my область ви

=cut

for (qw / my our local state /) {
    no warnings 'redefine';
    say "output for $_ :";
    ( my $sub =  q /
        sub func {
            XXX $var;
            $var++;
            say "A=$var";
        }; /
    ) =~ s/XXX/$_/ ;
    eval $sub;
    func() for 1..10;
    say "-----\n";
}

say "\$main::var => $main::var\n";

=head1 Как вы объясните странные результаты выдачи в таком случае?
    sub func {
        my $var if 0;
        $var++;
        say “A=$var”;
    }

=head1 ANSWERE
В актуальных версиях Perl использовать объявление my() в false-контексте в явном виде
больше нельзя, это приведёт к фатальной ошибке компиляции.
Странность можно объяснить тем, что переменная создаётся, но не инициализируется.
Раньше это иногда использавали для объявления статических пременных.
Но это не официальная фича с предсказуемым поведением, сейчас разумнее для этого
использовать state
Код ниже иллюстрирует неожиданнсти применения такого трюка.
=cut

say "output for my() in a false conditional: ";

my $false;

sub func {
    my $var if $false;        
    $var++;
    say "A=$var";
}

func;
func;

exit 0;


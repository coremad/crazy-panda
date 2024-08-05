#!/usr/bin/env perl
use strict; use warnings; use v5.10;
=head1 * Раздача карт
Есть стандартная колода из 52 карт. Надо перемешать и раздать на 9
человек по 2 карты и положить 5 карт отдельно. Приведите код, который
выполнит данные действия.
=head1 DESCRIPTION
=cut

my @suits   = qw/♠ ♥ ♦ ♣/;
my @ranks   = qw/A K Q J 10 9 8 7 6 5 4 3 2/;
my $gamers  = 9; 
my $buyin   = 5;
my $cards   = 2;

my ( @deck, @gamers, @buyin );

sub gen_deck {  # получение чистой колоды
    @deck = map { my $t = $_; map {"$t$_"} @suits } @ranks;
}

sub fisher_yates_shuffle { # Тасование Фишера — Йетса / Тасование Кнута    
    for (my $i = @deck; --$i; ) {
        my $j = int rand ($i+1);
        next if $i == $j;
        @deck[$i,$j] = @deck[$j,$i];
    }
}

sub split_deck { # раздвоение колоды
    @deck = map { @deck[$_, @deck/2 + $_] } 0 .. @deck/2 - 1;
}

sub deal($) { # простая выдача эн карт
    die "looks like a scam" if $_[0] > @deck || $_[0] < 1;
    splice @deck, 0, $_[0];
}

sub deal_rand($) { # выдача эн случайных карт
    my ($numb, $total, @cards) = (shift, scalar @deck, ());
    die "looks like a scam" if $numb > $total || $numb < 1;
    @cards = map { splice @deck, int rand $total--, 1 } 1 .. $numb;    
    
}

sub deal_snake($) { 
    my ($numb, $total, @cards) = (shift, scalar @deck, ());
    die "looks like a scam" if $numb > $total || $numb < 1;
    @cards = map{ (state $parity ^= 1) ? splice @deck, 0, 1 : splice @deck, $#deck, 1 } 1..$numb;
}

gen_deck;
# split_deck;
fisher_yates_shuffle;

say "deck before:\n@deck - ", scalar @deck, " total\n";

@gamers = map { [deal($cards)] } 0 .. $gamers - 1;

@buyin = deal($buyin);

say "deck after:\n@deck - ", scalar @deck, " total\n";

say "buy-in: @buyin - ", scalar @buyin, " total\n";

print "gamer$_\t" for 1 .. @gamers; say '';
for my $ii (0 .. $cards - 1) {
    print "$gamers[$_]->[$ii]\t" for  0 .. $#gamers; say '';
}

exit 0;

sub simple_shuffle { # не очень хорошее перемешивание
    for (0 .. $#deck) { 
        my $t = int rand scalar @deck;
        @deck[$_, $t] = @deck[$t, $_];
    }
}

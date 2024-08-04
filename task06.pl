#!/usr/bin/env perl
use strict; use warnings; use v5.30;
=head1 TASK06  Работа с памятью
6. Работа с памятью
    while (1) {
        my $a = {};
        $a->{func} = sub {
            $a->{cnt}++;
        };
    }
Что произойдет с памятью в этом примере и почему?
Как исправить положение?
=head1 DESCRIPTION
Правильней всего будет вынести объявление 'my a' за пределы блока цикла
Дкмонстрация работы по аналогии task05.pl
=cut

use Data::Dumper;
use Devel::Peek;
use Devel::Cycle 'find_cycle';
use Scalar::Util 'weaken';

use constant {
    OUTPUT_COUNTER  => 10000,   # период итераций для вывода информации
    RSS_FIELD       => 23,      # интересующая позиция в /proc/$$/stat 
    MEM_LIMIT       => 10,      # во сколько раз больше памяти стал занимать
};

open( my $fstat , "</proc/$$/stat" ) or die "Unable to open stat file";

sub mymem_eaten {
        seek($fstat, 0, 0);
        my @stat = split /\s+/ , <$fstat>;
        return $stat[RSS_FIELD] * 4;
}

my $start_usage = my $now_usage = mymem_eaten;
my $cc = my $reach_counter = 0;

sub show_info {
    say $reach_counter||($now_usage - $start_usage) ?
        "wtf, limit reached?! leak mem: ":"Ok, leak mem: ",
        ($now_usage - $start_usage)."KB\n";
}

sub show_status{ 
    unless ($cc--) {
        $cc = OUTPUT_COUNTER;
        say "RSS mem: ${now_usage}KB, $reach_counter cycle";
    }
}

say "\nstarting without fix";
while(1) { # память протячётъ
    $now_usage = mymem_eaten; show_status; $reach_counter++;

    my $a = {};
    $a->{func} = sub {
        $a->{cnt}++;
    };

    last if $now_usage >= MEM_LIMIT*$start_usage; # выход если мно го скушалось
}
show_info;

my $save_rc = $reach_counter;

say "starting with fix";
$start_usage = $now_usage = mymem_eaten;

for(my $a = {}; 1;) { # объявление $a не внутри
    $now_usage = mymem_eaten; show_status; $reach_counter--;

    $a->{func} = sub {
        $a->{cnt}++;
    };
    
    last unless $now_usage <= $start_usage * MEM_LIMIT && $reach_counter;
}
show_info;

$reach_counter = $save_rc;

say "starting with fix 2";
$start_usage = $now_usage = mymem_eaten;
while(1) { # очистка вручную в конце цикла
    $now_usage = mymem_eaten; show_status; $reach_counter--;

    my $a = {};
    $a->{func} = sub {
        $a->{cnt}++;
    };
    
    last unless $now_usage <= $start_usage * MEM_LIMIT && $reach_counter;
    undef $a; # тут
}
show_info;

$reach_counter = $save_rc;

say "starting with weaken";
$start_usage = $now_usage = mymem_eaten;
while(1) { # мягкая ссылка
    $now_usage = mymem_eaten; show_status; $reach_counter--;

    my $a = {};
    $a->{func} = sub {
        $a->{cnt}++;
    };
    weaken $a; # тут
    
    last unless $now_usage <= $start_usage * MEM_LIMIT && $reach_counter;
}
show_info;

close $fstat;

exit 0;


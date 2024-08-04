#!/usr/bin/env perl
use strict; use warnings; use v5.30;
=head1 TASK05 Поправить утечку памяти
В данном примере память естественно утекает из-за перекрестных ссылок.
    while (1) {
        my $a = {b => {}};
        $a->{b}{a} = $a;
    }
Как правильно инициализировать перекрестные ссылки, чтобы память из-
за них не утекала? Можно ли тут применить мягкие ссылки? Какие
особенности работы с мягкими ссылками?
=head1 DESCRIPTION
Пример ниже наглядно демонстрирует, как это работает
Первый цикл без weaken завершается при достижении MEM_LIMIT 
Второй должен завершаться по счётчику из первого цикла без утечек
К слову, обявление "my $a" перекрывает глобальную $a

todo: перессказать тут эту документацию:
https://perldoc.perl.org/perlref#Circular-References
=cut

use Data::Dumper 'Dumper';
use Devel::Cycle 'find_cycle';
use Devel::Peek 'Dump';
use Scalar::Util 'weaken';

use constant {
    OUTPUT_COUNTER  => 10000,   # период итераций для вывода информации
    RSS_FIELD       => 23,      # интересующая позиция в /proc/$$/stat 
    MEM_LIMIT       => 10,      # во сколько раз больше памяти стал занимать
};

say "info without weaken:";
{ # вывод информации о переменной из задания
    my $a = {b => {}};
    $a->{b}{a} = $a;
    find_cycle($a);    
    print Dumper $a;
    Dump $a;
}
say "\ninfo with weaken:";
{ # вывод информации с мягкой ссылкой
    my $a = {b => {}};
    weaken ($a->{b}{a} = $a);
    find_cycle($a);    
    print Dumper $a;
    Dump $a;
}

open( my $fstat , "</proc/$$/stat" ) or die "Unable to open stat file";
sub mymem_eaten {
        seek($fstat, 0, 0);
        my @stat = split /\s+/ , <$fstat>;
        return $stat[RSS_FIELD] * 4;
}

my $start_usage = my $now_usage = mymem_eaten;
my $cc = my $reach_counter = 0;

sub show_status{ 
    unless ($cc--) {
        $cc = OUTPUT_COUNTER;
        say "RSS mem: ${now_usage}KB, $reach_counter cycle";
    }
}

say "\nstarting without weaken";
while(1) { # память протячётъ
    $now_usage = mymem_eaten; show_status; $reach_counter++;

    my $a = {b => {}};
    $a->{b}{a} = $a;

    last if $now_usage >= MEM_LIMIT*$start_usage; # выход если мно го скушалось
}
say "Limit reached on $reach_counter cycle, leak mem: ", ($now_usage - $start_usage)."KB\n";

$start_usage = $now_usage = mymem_eaten;

say "starting with weaken";
while(1) { # мягкая ссылка
    $now_usage = mymem_eaten;
    unless ($cc--) {
        $cc = OUTPUT_COUNTER;
        say "RSS mem: ${now_usage}KB, $reach_counter remain cycle";
        # sleep 1;
    }
    $reach_counter--;

    my $a = {b => {}};
    weaken ($a->{b}{a} = $a); # тут

    last unless $now_usage < MEM_LIMIT*$start_usage && $reach_counter;
}

say $reach_counter||($now_usage - $start_usage) ?
    "wtf, limit reached again?! leak mem: ":"Ok, leak mem: ",
    ($now_usage - $start_usage)."KB";

close $fstat;

exit 0;
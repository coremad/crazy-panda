#!/usr/bin/env perl
use strict; use warnings; use v5.30;
=head1 TASK01 Удалить дубли из хеша
Дан хеш %h. Необходимо удалить из него лишние пары, у которых значения
повторяются (т.е. только 1 такую пару оставить) наиболее эффективным
методом. В хеше может быть миллион пар, так что приоритет –
процессорное время.

=head1 DESCRIPTION
Несколько функций удаления дублей вынесены в модуль MyApp::Hashdedup
    dedup_remap     - меняет местами ключ/значение туда-обратно с помощью map
    dedup_self      - модифицирует исходный хэш с помощью delete с итерацией по each
    dedup_each      - аналогичен предыдущему, вместо delete создаётся новый хэш
    dedup_onkeys    - аналогичен предыдущему, вместо each oбход по for/keys

=head1 BENCHMARKING
Сравнительное тестирование произваодится с помощью модуля Benchmark
Функции для сравнения перечислены в массиве @test_subs
Корректность работы методов проверяется последовательным сравнением с результатом предыдущего
Константа HSIZE определяет размер хэша %h, по которому будет тестирование, заполнение рандом
ITNUM - кол-во итераций по каждому методу 
Т.к. работа алгоритмов зависит от кол-ва дублей, в массиве @max_values перечислены макс. кол-ва 
уникальных значений, по которым будет тестирование
После всех тестов выводится сводная таблица со временем исполнения

Сравнение прооизводилось на системах:
1.  Intel(R) Xeon(R) CPU E5450  @ 3.00GHz
    Summary of my perl5 (revision 5 version 38 subversion 2) configuration:
    Platform:
        osname=linux
        osvers=6.6.21-gentoo-xeon
        archname=x86_64-linux-thread-multi
2.  PowerPC G4 7455
    Summary of my perl5 (revision 5 version 38 subversion 2) configuration:    
    Platform:
        osname=linux
        osvers=6.6.21-gentoo
        archname=powerpc-linux
3.  ARMv7 msm8960
    Summary of my perl5 (revision 5 version 38 subversion 2) configuration:   
    Platform:
        osname=linux
        osvers=3.4.10-gae8b65e
        archname=armv7a-linux

Наиболее производительные решения везде с использованием итерации по each и 
накоплением существующих значений в спомогательном хэше.
Наилучший результат у метода dedup_self, следом с отрывом от количества дублей
dedup_each поигрывает в 1.7-7 раз в зависимости  от количества дублей
dedup_onkeys, ожидаемо, проигрывает предыдущему где-то на 9%
dedup_remap проигрывает предыдущему в 1.5-* раза в зависимости от количества дублей

=head2 Xeon E5450
summary results for hash size 1048576 with 7 iterations, time in seconds

method \ max values     8       256     65536   262144  1048576 16777216
just dedup_remap:       10.66   11.93   16.67   26.07   43.42   54.42
dedup_self innerself:   0.93    1.05    2.09    4.36    9.49    13.96
dedup_each while/each:  5.85    6.15    9.02    12.42   19.49   25.65
dedup_onkeys for/keys:  7.42    7.99    12.53   17.12   22.87   28.28

=head2 PowerPC G4 7455, altivec supported
summary results for hash size 1048576 with 7 iterations, time in seconds

method \ max values     8       256     65536   262144  1048576 16777216
dedup_onkeys for/keys:  38.56   43.11   60.51   81.01   105.78  128.88
just dedup_remap:       59.97   65.75   82.26   127.88  204.71  256.9
dedup_each while/each:  36.36   41.99   50.24   66.37   98.17   125.96
dedup_self innerself:   6.09    7.04    11.42   23.38   48.28   71.44

=head2 ARMv7 msm8960 (swp half thumb fastmult vfp edsp neon vfpv3 tls vfpv4)
summary results for hash size 1048576 with 7 iterations, time in seconds

method \ max values     8       256     65536   262144  1048576 16777216
dedup_onkeys for/keys:  34.38   36.84   46.58   60.12   80.78   99.48
dedup_self innerself:   7.89    8.81    13.17   24.80   49.98   73.67
dedup_each while/each:  50.52   54.28   63.18   74.67   100.53  121.7
just dedup_remap:       44.6    45.72   53.11   78.75   126.08  158.92
=cut

use Data::Dumper;
use Benchmark;
use Test::More;

use File::Basename 'dirname';
use lib dirname(__FILE__).'/lib';
use MyApp::Hashdedup;

use constant {
    HSIZE => 2**20, # размер хэша для обработки
    ITNUM => 7,     # количество итераций для измерений
};
my @max_values = (2**3, 2**8, 2**16, 2**18, 2**20, 2**24); # кол-ва уникальных значений

my %bresults; # тут будут результаты бенчмарков

for my $value (@max_values) { # обход по разным уникальным значениям для генерации хэша
    my %h;
    print "Gen hash data for max value: $value...";
    $h{"kek_$_"} = "lol_".int rand $value for 1 .. HSIZE; # генерация хэша
    say " done\n";
    
    my $hsize = scalar keys %h;
    my $prevh;
    { no warnings 'experimental';
    for my ($desc, $sub) (@test_subs) { # обход по методам
        my $newh;
        (my $res = timethese (ITNUM, { # исполнение/замер метода
            "$desc" => sub { $newh = $sub->(\%h) } 
        })->{"$desc"}->[1]) =~ s/^(\d+\.\d\d).*/$1/;
        push @{$bresults{"$desc"}}, $res;

        say "\nOld hash size: $hsize\nNew hash size: ", (scalar keys %$newh);
        print "check keys..."; # проверка корректности ключ/значение
        ($newh->{$_} eq $h{$_} or die "wrong result!") for keys %$newh;
        say " ok";
        if ($prevh ) {
            print "comparing with previous result..."; # сравниваются значения, ключи совпадать не обязаны
            eq_set [values %$prevh], [values %$newh] or die "not equal!";            
            say " ok"
        }
        say "\n";
        $prevh = $newh; 
    }}
}

say "\n\nsummary results for hash size ", HSIZE, " with ", ITNUM," iterations, time in seconds\n";
{
    local $" = "\t";
    say "method \\ max values\t@max_values";
    while (my($name, $res) = each %bresults) { say "$name:\t@$res" }
}

exit 0;

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

Наиболее производительные решения везде с использованием итерации по each и 
накоплением существующих значений в спомогательном хэше.
Наилучший результат у метода dedup_self, следом с отрывом от количества дублей
dedup_each поигрывает в 1.7-7 раз в зависимости  от количества дублей
dedup_onkeys, ожидаемо, проигрывает предыдущему где-то на 9%
dedup_remap проигрывает предыдущему в 1.5-2 раза в зависимости от количества дублей
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
    my %h = ();
    print "Gen hash data for max value: $value...";
    $h{"kek_$_"} = "lol_".int rand $value for 1 .. HSIZE; # генерация хэша
    say " done\n";
    
    my $hsize = scalar keys %h;
    my ($prevh, $newh);
    { no warnings 'experimental';
    for my ($desc, $sub) (@test_subs) { # обход по методам
        $newh = {};
        (my $res = timethese (ITNUM, { # исполнение/замер метода
            "$desc" => sub { $newh = $sub->(\%h) } 
        })->{"$desc"}->[1]) =~ s/^(\d+\.\d\d).*/$1/;
        push @{$bresults{"$desc"}}, $res;

        say "\nOld hash size: $hsize\nNew hash size: ".(scalar keys %$newh);
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

say "\n\nsummary results for hash size ".HSIZE." with ".ITNUM." iterations, time in seconds\n";
{
    local $" = "\t";
    say "method \\ max values\t@max_values";
    while (my($name, $res) = each %bresults) { say "$name:\t@$res" }
}

exit 0;

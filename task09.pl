#!/usr/bin/env perl
use strict; use warnings; use v5.10;

=head1 TASK09  Поиск в массиве
Дан массив из большого числа элементов (числа), отсортированный по
возрастанию. Необходимо написать функцию, которая быстро найдет
индекс элемента массива, значение по которому наиболее близко к
переданному в аргументах функции числу.
Используйте модуль Benchmark, чтобы оценить скорость написанного
решения и оптимизировать его.

=head1 DESCRIPTION
Реализован бинарный поиск на Perl - binsearch и два на C
Первый вариант работает непосредственно с Perl-массивом, второму
требуется предварительная конвертация в родной массив. Это даёт некоторые
преимущества по скорости, но требует переиниции, если данные менялись

=head1 Результаты тестирования для разных архитектур
Сравненин проводилось для размера массива 2**20 и 10E6 итераций

=head2 Xeon E5450
                Rate   binsearch binsearchC1 binsearchC2
binsearch   128205/s          --        -70%        -76%
binsearchC1 427350/s        233%          --        -21%
binsearchC2 540541/s        322%         26%          --

=head2 PowerPC G4 7455, altivec supported
               Rate   binsearch binsearchC1 binsearchC2
binsearch   15207/s          --        -73%        -78%
binsearchC1 56022/s        268%          --        -19%
binsearchC2 69348/s        356%         24%          --

=head2 ARMv7 msm8960 (swp half thumb fastmult vfp edsp neon vfpv3 tls vfpv4)
               Rate   binsearch binsearchC1 binsearchC2
binsearch   14896/s          --        -56%        -62%
binsearchC1 33910/s        128%          --        -13%
binsearchC2 38835/s        161%         15%          --
=cut

use Benchmark 'cmpthese';
use File::Basename 'dirname';
use lib dirname(__FILE__).'/lib';
use MyApp::Findnear;
# use MyApp::Findnear:XS;

use constant {
    ASIZE   => 2**20,   # размер массива
    ITNUM   => 1000000, # количество итераций для измерений
    REPCOUNT => 5,      # колчичество повтореий с генерацией новых данных
};


for (1 .. REPCOUNT) {
    print "prepare array..."; STDOUT->flush;    
    my @arr = sort { $a <=> $b } map { rand } (0 .. ASIZE - 1);
    arr2c(\@arr); # конвертация для С
    say " done";

    my $searchin = rand; # значение для поиска
    my (%cmp_h, %res);
    { no warnings 'experimental';
    for my ($desc, $sub) (@test_subs) { # добавление функций для бенчмарка
         $cmp_h{$desc} = sub { 
            my $res = $sub->(\@arr, $searchin);
            $res{$searchin}{$res} = $arr[$res];
        }
    }}

    cmpthese(ITNUM, \%cmp_h); undef @arr;

    while (my($kk, $vv) = each %res ) { # функции должны находить одинаковый результат
        if (1 < keys %$vv) {
            my %tmp = map { $vv->{$_}, $_} keys %$vv;
            (1 < keys %tmp ) and die "not equal!"
        }
    }
}

exit 0;

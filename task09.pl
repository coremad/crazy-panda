#!/usr/bin/env perl
use strict; use warnings; use v5.30;

=head1 TASK09  Поиск в массиве
Дан массив из большого числа элементов (числа), отсортированный по
возрастанию. Необходимо написать функцию, которая быстро найдет
индекс элемента массива, значение по которому наиболее близко к
переданному в аргументах функции числу.
Используйте модуль Benchmark, чтобы оценить скорость написанного
решения и оптимизировать его.
=head1 DESCRIPTION
Функции поиска вынесены в модуль MyApp::Findnear
=cut

use Benchmark 'cmpthese';
use File::Basename 'dirname';
use lib dirname(__FILE__).'/lib';
use MyApp::Findnear;

use constant {
    ASIZE   => 2**23,   # размер массива
    ITNUM   => 200000,  # количество итераций для измерений
    REPCOUNT => 10,     # колчичество повтореий с генерацией новых данных
};

use Devel::Size qw(size total_size);

for (1 .. REPCOUNT) {
    print "prepare array..."; STDOUT->flush;
    my @arr = sort { $a <=> $b } map { rand } (0 .. ASIZE - 1);
    say " done";
    print "prepare btree..."; STDOUT->flush;
    my $searcher = MyApp::Findnear->new(\@arr, 3);
    say " done";
    say "total_size array: ", total_size(\@arr)/1024/1024;
    say "total_size btree: ", total_size($searcher->{btree})/1024/1024;
    my $searchin = rand;
    my (%cmp_h, %res);
    { no warnings 'experimental';
    for my ($desc, $sub) (@test_subs) {
         $cmp_h{$desc} = sub { 
            my $res = $sub->(\@arr, $searchin);
            $res{$searchin}{$res} = $arr[$res];
        }
    }}
    $cmp_h{'btreesearch'} = sub { 
        my $res = $searcher->btreesearch($searchin);
        $res{$searchin}{$res} = $arr[$res];
    };
    cmpthese(ITNUM, \%cmp_h);
    while (my($kk, $vv) = each %res ) { # функции должны находить одинаковый результат
        if (1 < keys %$vv) {
            my %tmp = map { $vv->{$_}, $_} keys %$vv;
            (1 < keys %tmp ) and say Dumper \%res and die "not equal!"
        }
    }
}

exit 0;

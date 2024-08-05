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
Победила реализация на С...
=cut

use Benchmark 'cmpthese';
use File::Basename 'dirname';
use lib dirname(__FILE__).'/lib';
use MyApp::Findnear;
# use MyApp::Findnear:XS;
use Inline 'C';

use constant {
    ASIZE   => 2**22,   # размер массива
    ITNUM   => 1000000,  # количество итераций для измерений
    REPCOUNT => 5,     # колчичество повтореий с генерацией новых данных
};


for (1 .. REPCOUNT) {
    print "prepare array..."; STDOUT->flush;
    my @arr = sort { $a <=> $b } map { rand } (0 .. ASIZE - 1);
    say " done";
    sv_init(\@arr);

    my $searchin = rand;
    my (%cmp_h, %res);
    { no warnings 'experimental';
    for my ($desc, $sub) (@test_subs) {
         $cmp_h{$desc} = sub { 
            my $res = $sub->(\@arr, $searchin);
            $res{$searchin}{$res} = $arr[$res];
        }
    }}

    $cmp_h{'binsearchC'} = sub {         
        my $min = 0;
        my $max = $#arr;
        my $res = binarySearch($searchin, $min, $max);
        $res{$searchin}{$res} = $arr[$res];
    };
    cmpthese(ITNUM, \%cmp_h);
    while (my($kk, $vv) = each %res ) { # функции должны находить одинаковый результат
        if (1 < keys %$vv) {
            my %tmp = map { $vv->{$_}, $_} keys %$vv;
            (1 < keys %tmp ) and die "not equal!"
        }
    }
}

exit 0;

__END__
__C__

double * carray;
int size = 0;

int sv_init(AV* parray) {
    if (size > 0 ) free(carray);
    size = av_len(parray)+1;
    carray = malloc(size*8);
    for (int i=0; i<=av_len(parray); i++) {
        SV** elem = av_fetch(parray, i, 0);
            if (elem != NULL)
        carray[i] = SvNV(*elem);
    }
    return size;   
}

int sv_done(AV* parray) {
    free(carray);
    size = 0;
}

double check(int index) {
    return carray[index];
}

int binarySearch(double x, int low, int high) {
  if (size <= 0 ) return(-1);
  while (high - low > 1) {
    int mid = low + (high - low) / 2;
    if (carray[mid] == x)
      return mid;
    if (carray[mid] < x)
      low = mid ;
    else
      high = mid;
  }
  return (x - carray[low]) <= (carray[high] - x) ? low : high;
}


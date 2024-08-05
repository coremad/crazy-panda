package MyApp::Findnear;
use strict; use warnings; use v5.10;
use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(@test_subs arr2c);

our @test_subs; # список функций для тестирования

sub simplesearch ($$) { # сравнивать её в бенчмарках нет смысла, слишком долго
    my ($arr, $num) = @_;
    ref $arr eq 'ARRAY' or die 'arrref needed!';
    return 0 if $num <= $arr->[0]; 
    my $ii = 0;
    {
        $num <= $arr->[$ii+1] and return(($num - $arr->[$ii]) <= ($arr->[$ii+1] - $num) ? $ii : $ii + 1);
        redo if ++$ii < $#$arr
    }
    return $#$arr;
}
push @EXPORT, 'simplesearch'; 
# push @test_subs, 'simplesearch' => \&simplesearch; 

sub binsearch ($$) { # бинарный поиск
    my ( $arr, $num ) = @_;
    ref $arr eq 'ARRAY' or die 'arrref needed!';
    my $min = 0;
    my $max = $#$arr;
    {
        my $mid = (( $max - $min ) >> 1 ) + $min ;
        $num > $arr->[$mid] and $min = $mid or $max = $mid;
        redo if $max - $min  > 1
    }
    return ($num - $arr->[$min]) <= ($arr->[$max] - $num) ? $min : $max;
}
push @EXPORT, 'binsearch'; 
push @test_subs, 'binsearch' => \&binsearch; 

use Inline 'C';

sub binsearchC1 ($$) {
    my ( $arr, $num ) = @_;
    ref $arr eq 'ARRAY' or die 'arrref needed!';
    return binarySearch1($arr, $num, 0, $#$arr);        
}
push @EXPORT, 'binsearchC1'; 
push @test_subs, 'binsearchC1' => \&binsearchC1; 

sub arr2c($) { 
    my ( $arr ) = @_;
    ref $arr eq 'ARRAY' or die 'arrref needed!';
    state $arr_ref = 0;
    sv_init($arr) if $arr_ref != $arr ;
    $arr_ref = $arr;
}

sub binsearchC2 ($$) {
    my ( $arr, $num ) = @_;
    ref $arr eq 'ARRAY' or die 'arrref needed!';
    # arr2c($arr);
    return binarySearch2($num, 0, $#$arr);        
}
push @EXPORT, 'binsearchC2'; 
push @test_subs, 'binsearchC2' => \&binsearchC2; 

END {
    sv_done();
}
1;

__DATA__
__C__

int binarySearch1(AV* parray, double x, int low, int high) {
  while (high - low > 1) {
    int mid = low + (high - low) / 2;
    SV** tmpm = av_fetch(parray, mid, 0);
    if (SvNV(*tmpm) < x)
      low = mid ;
    else
      high = mid;
  }
  SV** tmpl = av_fetch(parray, low, 0);
  SV** tmph = av_fetch(parray, high, 0);
  return (x - SvNV(*tmpl)) <= (SvNV(*tmph) - x) ? low : high;
}

double * carray;
int size = 0;

int sv_init(AV* parray) {
    if (size > 0 ) free(carray);
    size = av_len(parray)+1;
    carray = malloc(size*8);
    for (int i=0; i<=av_len(parray); i++) {
        SV** elem = av_fetch(parray, i, 0);
        if (elem != NULL) carray[i] = SvNV(*elem);
    }
    return size;   
}

int sv_done() {
    free(carray);
    size = 0;
}

double check(int index) {
    return carray[index];
}

int binarySearch2(double x, int low, int high) {
  if (size <= 0 ) return(-1);
  while (high - low > 1) {
    int mid = low + (high - low) / 2;
    if (carray[mid] < x)
      low = mid ;
    else
      high = mid;
  }
  return (x - carray[low]) <= (carray[high] - x) ? low : high;
}

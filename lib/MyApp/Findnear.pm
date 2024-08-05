package MyApp::Findnear;
use strict; use warnings; use v5.10;
use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(@test_subs);

our @test_subs; # список функций для тестирования

sub simplesearch ($$) { # сравнивать её в бенчмарках нет смысла 
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

sub binsearch ($$) {
    my ( $arr, $num ) = @_;
    ref $arr eq 'ARRAY' or die 'arrref needed!';
    return 0 if $arr->[0] >= $num;
    return $#$arr if $arr->[$#$arr] <= $num;
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

1;

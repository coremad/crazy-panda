package MyApp::Findnear;
use strict; use warnings; use v5.30;
use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(@test_subs);

our @test_subs; # список функций для тестирования

sub simplesearch ($$) {
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


# sub shittest ($$) {
#     my ( $arr, $num ) = @_;
#     ref $arr eq 'ARRAY' or die 'arrref needed!';
#     return int rand $#$arr;
# }
# push @EXPORT, 'shittest'; 
# push @test_subs, 'shittest' => \&shittest; 

use constant {
    BSIZE => 16,
};

sub new {
    my ($class, $arr, $bsize) = @_;
    ref $arr eq 'ARRAY' or die 'arrref needed!';
    my $self = { arr => $arr, btree => {} };
    bless $self, $class;
    $self->init($bsize);
    return $self;
}

sub mkbtree {
    my ($btree, $depth, $arr, $min, $max) = @_;
    my $mid = (( $max - $min ) >> 1) + $min;
    $$btree = { mid => $mid, vmid => $arr->[$mid], left => {}, right => {} };
    --$depth or return;
    mkbtree((\$$btree->{left}), $depth, $arr, $min, $mid) if $min < $mid;
    mkbtree((\$$btree->{right}), $depth, $arr, $mid, $max) if $mid < $max;
}

sub init {
    my ($self, $bsize) = (@_);
    $bsize = $bsize // BSIZE;
    mkbtree(\$self->{btree}, $bsize, $self->{arr}, 0, $#{$self->{arr}});
}

sub btreesearch ($$) {
    my ( $self, $num ) = @_;
    return 0 if $self->{arr}->[0] >= $num;
    return $#{$self->{arr}} if $self->{arr}->[$#{$self->{arr}}] <= $num;
    my $min = 0;
    my $max = $#{$self->{arr}};
    my $bpos = \$self->{btree};
    {
        if ($num > $$bpos->{vmid} ) { $min = $$bpos->{mid}; $bpos = \$$bpos->{right}}
        else { $max = $$bpos->{mid} ; $bpos = \$$bpos->{left}};
        redo if $$bpos->{mid} && ($max - $min  > 1)
    }
    while ($max - $min  > 1) {
        my $mid = (( $max - $min ) >> 1) + $min;
        $num > $self->{arr}[$mid] and $min = $mid or $max = $mid;
    }
    return ($num - $self->{arr}[$min]) <= ($self->{arr}[$max] - $num) ? $min : $max;
}

1;


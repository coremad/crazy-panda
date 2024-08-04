package MyApp::Hashdedup;
use strict; use warnings; use v5.30;
use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(@test_subs);

our @test_subs; # список функций для тестирования

sub dedup_each($) {
    ref (my $h = shift) eq 'HASH' or die ("href needed!");
    my (%newh, %dups);
    while (my($k, $v) = each %$h) {
        next if exists $dups{$v};
        $newh{$k} = $v; $dups{$v} = undef;
    }    
    return \%newh;
}
push @EXPORT, 'dedup_each'; 
push @test_subs, 'dedup_each while/each' => \&dedup_each; 

sub dedup_remap($) {
    ref (my $h = shift) eq 'HASH' or die ("href needed!");
    my %tmph = map { $h->{$_} => $_ } keys %$h;
    my %newh = map { $tmph{$_} => $_ } keys %tmph;
    return \%newh;
}
push @EXPORT, 'dedup_remap'; 
push @test_subs, 'just dedup_remap' => \&dedup_remap; 

sub dedup_onkeys($) {
    ref (my $h = shift) eq 'HASH' or die ("href needed!");
    my (%newh, %dups);
    for (keys %$h) {
        next if exists $dups{ my $v = $h->{$_} };
        $newh{$_} = $v; $dups{$v} = undef;
    }
    return \%newh;
}
push @EXPORT, 'dedup_onkeys'; 
push @test_subs, 'dedup_onkeys for/keys' => \&dedup_onkeys; 

sub dedup_sort($) { # в тесте не участвует, был только для сравнения результатов
    ref (my $h = shift) eq 'HASH' or die ("href needed!");
    my (%newh, $k, $v, $prev);
    $prev = '*wtf this magick value*';
    for (sort {$h->{$a} cmp $h->{$b}} keys %$h) {
        next if ($v = $h->{$_}) eq $prev;
        $prev = $newh{$_} = $v;
    }
    return \%newh;
}
push @EXPORT, 'dedup_sort'; 
# push @test_subs, 'just for/sort lol' => \&dedup_sort;

sub dedup_self($) { # модифицирует исходный хэш, в тестах запускать последним или делать копию
    ref (my $h = shift) eq 'HASH' or die ("href needed!");
    my ( %dups, $k, $v );
    (exists $dups{$v} and delete $h->{$k} or $dups{$v} = undef) while (($k, $v) = each %$h);
    return $h;
}
push @EXPORT, 'dedup_self';
push @test_subs, 'dedup_self innerself' => \&dedup_self; 

1;

package MyApp::Accessor;
use strict; use warnings; use v5.30;
use Exporter 'import';
our @EXPORT = qw/prop/;

our %_props = ();

sub new {
    my ($class, $self) = (shift, {});
    $class = ref $class || $class;
    bless $self, $class;
    while (my($prop, $attr) =  each %_props) {
        $attr = {} unless ref $attr eq "HASH";
        $self->{$prop} = $attr->{default};
        next unless ref $attr->{default} eq "CODE";
        $self->{$prop} = $self->{$prop}();
    }
    return $self;
}

sub prop {
    die "@_\nicorrect usage, need ('property name' => {attribures})," if (@_ & 1) & (@_ > 1);
    while (my $prop = shift) {
        die "property ",__PACKAGE__,"::$prop already yet!" if exists $_props{$prop};
        ref ($_props{$prop} = shift) eq 'HASH' or $_props{$prop} = { default => $_props{$prop} };
        my $accessor = $_props{$prop}->{accessor} // #"*".__PACKAGE__."::$prop = ".
            qq ^sub $prop {
                    \$_[0]->{$prop} = \@_ > 1 ? \$_[1] : \$_[0]->{$prop};
                }; 1; ^;
        eval "$accessor" && next unless (ref $accessor) eq 'CODE';
        die "wrong accessor for propetty '$prop':\n$@" if $@;
        no strict 'refs';
        *{__PACKAGE__."::$prop"} = $accessor;
    }
}

sub proplist {
    return sort keys %_props;
}

1;

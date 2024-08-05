#!/usr/bin/env perl
use strict; use warnings; use v5.30;
=head1 TASK02 Аксессоры
Напишите на Perl примитивный базовый класс MyApp::Accessor для
использования в качестве базового класса для генерации аксессоров
(методов которые сохраняют и отдают свойство объекта). Аксессоры
должны работать настолько быстро, насколько это возможно в принципе.
Какими технологиями/модулями, по вашему, лучше всего пользоваться в
реальной разработке для создания аксессоров?
P.S. Accessor – это примитивная функция, которая служит для доступа к
свойству объекта извне.
Т.е. $obj->property – возвращает значение, а $obj->property($value) –
устанавливает.
=head1 DESCRIPTION
Класс в Accessor.pm
Свойства описываются с помощью 'prop' следующим образом:
prop prop_name1 => { attr1 }, prop_name2 => { attr2 }, ... ;
Из атрибутов реализованы дефолтное значение при создании экземпляра и переопределение
дефолтного аксессора.
Метод proplist возвращает список свойств
=cut

use File::Basename 'dirname';
use lib dirname(__FILE__).'/lib';
{   # класс MyClass наследуется от MyApp::Accessor
    package MyClass;
    use MyApp::Accessor;
    push our @ISA,'MyApp::Accessor';

    prop    'test'  => {}; # в общем случае свойства описваются парой "имя => {атрибуты}"
    prop    'test0'; # для одиночного можно не указывать атрибудты
    prop    'test1' => { default => 'lol test1' },
            'test2' => 'kek test2'; # развернйтся в { default => 'kek test2' }            

    my $tmp = ', modcount=';

    prop    'test3' => {
                default     => 'ok',
                accessor    => sub { # переопределение дефолтного аксессора
                    state $modcount = 0;
                    my $self = shift;
                    return $self->{test3}.$tmp.$modcount unless scalar @_;
                    $modcount++;
                    $self->{test3} = shift;
                },
             },
            'test4' => { # тут начальное значение - функция
                default => sub { time . int rand 100 },
            },
            'test5' => {
                default => [1 .. 7],
                accessor => sub {
                    my $self = shift;
                    local $" = ', ';
                    return "@{$self->{test5}}" unless scalar @_;                    
                    $self->{test5} =  \@_;
                }
            },
    ;
    prop a => b => c => d =>; # свойства 'a' и 'c'
    # prop e => f => h => ; # ошибка, должны быть пары
    prop $_ => 1 for qw /x y z lamda/;
}

# использование класса MyClass
my $acc1 = MyClass->new;
say "$_\t=> " . ($acc1->$_//'undef') for $acc1->proplist;
$acc1->test('test kek');
say $acc1->test;
$acc1->test3('test3 new');
say $acc1->test3;
$acc1->test3('test3 newer');
say $acc1->test3, "\n";
$acc1->test5(3, 2, 1);

my $acc2 = MyClass->new;
say "$_\t=> " . ($acc2->$_//'undef') for $acc2->proplist;
$acc2->test('test new');
say $acc2->test;
$acc2->test('test newer');
say $acc2->test;
say "$_\t=> " . ($acc1->$_//'undef') for $acc1->proplist;

exit 0;

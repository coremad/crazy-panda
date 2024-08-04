#!/usr/bin/env perl
use strict; use warnings; use v5.10;
=head1 TASK04  Обработка данных из БД
В базе данных есть большая таблица из 2х полей (id, data), на порядки
превышающая объем оперативной памяти. Нам требуется обработать её
(т.е. прочитать все значения data). Как бы вы это организовали? Какие
проблемы могут возникнуть при такой обработке?
PS: Курсоры данная база не поддерживает.
=head1 DESCRIPTION
Упрощённый пример ниже.
В данной реализации выборка производится последовательно заданной порцией
выборки данных с помощью LIMIT
В примере используется sqlite чтобы можно было просто запустить скрипт без
дополнительных настроек, но не сложно переделать под любую другую БД
Проблем можно придумать много в зависимости конкретной БД и контекста задачи...
=cut

use DBI;

use constant {
    NUM_GEN_ROWS    => 2**8,    # сколько сгенерировать записей в таблицу, если пусто
    WORK_ROWS       => 2**3-1,  # по скольку обрабатывать данных
};

#my @conncred = ('DBI:mysql:panda', 'panda_user', 'panda20240804');
my @conncred = ("dbi:SQLite:dbname=panda.sqlite", "", "");

my $dbh  = DBI->connect(@conncred) and print "Connected, init tables..." or die "wtf?!";
my $sth;
while (<DATA>) { # инициализация таблиц БД, если отсутствуют
    $sth = $dbh->prepare($_) or die "prep failed: ".$dbh->errstr();
    $sth->execute or die "exec failed: ".$dbh->errstr();
}
print " done!\nGen data... " and STDOUT->flush;

my $total_rows = $sth->fetchrow;
$sth = $dbh->prepare("INSERT INTO `t1`(`data`) VALUES (?),(?)") or die "prep failed: ".$dbh->errstr();
while ($total_rows < NUM_GEN_ROWS ) { # генерация записей в таблице
    $sth->execute("lol_$total_rows", "kek_".int rand 2**16) or die "exec failed: ".$dbh->errstr();
    $total_rows += $sth->rows;
}
say "done!\ntotal rows: $total_rows";

my ($start_id, $processed, $sum) = (0, 0, 0);
$sth = $dbh->prepare("SELECT id, data FROM t1 ORDER BY id LIMIT ?, ?") or die "prepare failed: ".$dbh->errstr();
say "going work";
{ # обход всей таблицы
    my $num_rows = 0;
    $sth->execute($start_id, WORK_ROWS) or die "exec failed: ".$dbh->errstr();
    # где-то тут обработку порций данных несложно распараллелить
    while(my($id, $data) = $sth->fetchrow) { # обход выборки порции данных
        # say "$id\t $data";
        # тут должна быть какая-то обработка данных, например
        $data =~/(\d+)/; $sum += $1;        
    } continue { $num_rows++; $start_id = $id; }
    last unless $num_rows;
    $processed += $num_rows;
    say "Processed $num_rows rows, total $processed rows processed";    
} continue { redo }
say "\n all done, sum = $sum for $processed rows";

exit 0;

__DATA__
CREATE TABLE IF NOT EXISTS `t1` (`id` INTEGER NOT NULL PRIMARY KEY, `data` TEXT);
CREATE TABLE IF NOT EXISTS `tmp_t1` (`id` INTEGER NOT NULL PRIMARY KEY, `fid` INTEGER NOT NULL);
SELECT COUNT(*) FROM t1;

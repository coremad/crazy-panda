#!/usr/bin/env perl
use strict; use warnings; use v5.30;
=head1 TASK07.2 Асинхронный
А также написать асинхронную версию этой функции, которая (для
простоты задания) отличается тем, что пока ждет ответа занимается
заполнением какого-нить массива числами и выводит на экран сколько
элементов успела добавить пока ждала ответа удаленного сервера.
Программа должна оставаться в рамках 1 процесса и 1 потока (т.е. без
fork и без threads).
=head1 DESCRIPTION
В примере серверу передаётся параметр в запросе "?sleep = 4" для зададержки 
В цикле делаются запрсы с таймаутами от 1 до 7 сек
От предыдущего примера отличается тем, что во время ожидания ответа выполнение не
останавливается, можно грабить корованы
В процессе ожидания показывается счётчик секунд
=cut

use IO::Socket::IP;
use IO::Select;

sub http_get_async($$$$$) {
    my ( $host, $port, $path, $query, $timeout ) = @_;

    my $get = "$path?";
    if( ref($query) eq 'HASH' ) {
        for my $key (keys %$query) {
            $get .= "$key=$query->{$key}&";
        }
    }
    $get = substr($get, 0, - 1 + length $get);

    my $req = join "\r\n",
        "GET /$get HTTP/1.0",
        "Host: $host:$port",
        "Accept: text/plain\r\n\r\n";

    my $sock = IO::Socket::IP->new (
         PeerAddr => "$host:$port",
         Blocking => 0,
    ) or die "wtf socket?\n$!";
    say "Connected to $host via ", 
        ( $sock->sockdomain == PF_INET6 ) ? "IPv6" :
        ( $sock->sockdomain == PF_INET  ) ? "IPv4" :
        "unknown";

    my $select = IO::Select->new();
    $select->add($sock);
    print "wait ready for write...";
    print "." until $select->can_write($timeout);
    syswrite $sock, $req;
    say " done";
    
    my ($start_time, $time, $delta_time, $old_delta) = (time, 0, 0, 0);
    print "wait resonse... "; STDOUT->flush;
    while (($delta_time = ($time = time) - $start_time) < $timeout) {
        print "$delta_time " if $delta_time != $old_delta; STDOUT->flush;
        $old_delta = $delta_time;
        for my $client ($select->can_read(0)) {
            if ( $client != $sock ) {
                # тут придумать какую-то обработку на время ожидания
            } else {
                my $buf = '';
                (my $len = sysread $sock, $buf, 4096) // die "sysread error";
                $sock->close;
                say "done";
                return $buf;
            }
        }        
    }
    say "timeout reached";
    $sock->close;
    return undef;
}

my $qpar = {
    lol => 'value1',
    kek => 'value2',
    ok  => 'value3',
    sleep  => 4,
};

say http_get_async('slowpoke.madcore.fun', 80, 'path', $qpar, $_) ? 
    "ok\n": "nothing!\n" for 1 .. 7;

exit 0;

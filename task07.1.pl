#!/usr/bin/env perl
use strict; use warnings; use v5.30;
=head1 TASK07.1 Синхронный
Написать функцию http_get($host, $path, $query, $timeout), которая делает
http запрос на адрес http://$host/$path?$query с таймаутом $timeout.
Реализация http должна быть примитивной, то есть мы рассчитываем на
ответ HTTP 200 OK с content-length.
$query передают в функцию хешом.
=head1 DESCRIPTION
В примере серверу передаётся параметр в запросе "?sleep = 4" для зададержки 
В цикле делаются запрсы с таймаутами от 1 до 7 сек
=cut

use IO::Socket::IP;
use IO::Select;

sub http_get($$$$$) {
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
    
    print "wait resonse... "; STDOUT->flush;
    for my $client ($select->can_read($timeout)) {
        next unless $client == $sock;
        my $buf = '';
        (my $len = sysread $sock, $buf, 4096) // die "sysread error";
        $sock->close;
        say "done";
        return $buf;
    }
    say "timeout reached";
    $sock->close;
    return undef;
}

my $qpar = {
    lol => 'value1',
    kek => 'value2',
    ok  => 'value3',
    sleep  => 4, # задержка сервера перед ответом
};

say http_get('slowpoke.madcore.pro', 80, 'path', $qpar, $_) ? 
    "ok\n": "nothing!\n" for 1 .. 7;
# say http_get('127.0.0.1', 8080, 'path', $qpar, $_) ? 
#     "ok\n": "nothing!\n" for 1 .. 7;

exit 0;

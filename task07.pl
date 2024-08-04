#!/usr/bin/env perl
use strict; use warnings; use v5.30;

=head1 TASK07 HTTP запрос
Пожалуйста, при выполнении этого задания не пользуйтесь LWP::*, он не
поможет во втором пункте задания, да и задание это нужно, чтобы
посмотреть как вы умеете работать с сокетами, а не как это умеют
работать модули.
В качестве решения второй части задания мы также готовы засчитать
решение с помощью какого-либо модуля, однако вручную все же намного
лучше, т.к., повторюсь, в реальной жизни конечно можно и не писать такие
вещи в ручную, но знание этого и специфики асинхронной работы – очень
важно.

=head1 DESCRIPTION
Простейший HTTP-Сервер с таймаутом
По умолчанию ждёт 7 секунд перед ответом
Для удобства клиент может передать в запросе параметр "sleep=NUM"
=cut

use IO::Socket::IP;
use Socket qw(getnameinfo);
use POSIX ":sys_wait_h";
use Data::Dumper;

my $listen = $ARGV[0] || '127.0.0.1:8080';


my $max_kinders = 30;   # максимальное кол-во одновременных соединений
my $sleep_time  = 7;    # задержка перед ответом по умолчанию
my %kids;
my $sock;

sub wait_kids {
    my $kid; delete $kids{$kid} while (($kid = waitpid(-1, &WNOHANG)) > 0);
}

$SIG{INT} = sub {
    say "@_";
    $sock->close;
    say "server go down";
    kill 'TERM', $_ for keys %kids;
    wait_kids;
    exit 0;
};

$SIG{CHLD} = \&reaper;
sub reaper {
    wait_kids;
    say "[reaper] babies: ", scalar keys %kids;
    $SIG{CHLD} = \&reaper;
}

my $content = "";
while (my $line = <DATA>) { $content .= $line; }; close DATA;

my $resp = join "\r\n",
    "HTTP/1.1 200 Ok",
    "Content-Length: " . length $content,
    "Accept: text/html",
    '','', $content;

sub init_sock {
    $sock = IO::Socket::IP->new (
        LocalHost   => $listen,
        Listen      => 1,
        ReuseAddr   => 1,
    ) or wait_kids && die "wtf socket?\n$IO::Socket::errstr\n$!";
}

my ($req, $path, $param_str, %req_params, $sleep);
sub parse_req {
            %req_params = ();
            ($path, $param_str) = split /\?/, $req;
            $sleep = 7;
            return unless $param_str;
            $param_str =~ s/(.*?)(#| |\n|\r).*/$1/mg; 
            return unless $param_str;
            say "[$$] param_str: $param_str";
            %req_params = split /&|=/, $param_str;
            $sleep = $req_params{'sleep'} // $sleep_time;
            $sleep = $sleep_time if $sleep < 0 || $sleep > 20;
}

while ($sock = init_sock) {
    say "listen $listen";
    while(my $peer = $sock->accept) {        
        my ($err, $hostname, $servicename) = getnameinfo($peer->peername);
        die "[serv] Cannot getnameinfo - $err" if $err;
        say "[serv] connetcted client $hostname:$servicename";
        if ($max_kinders <= scalar keys %kids) {
            say "[serv] too many babes still not reaped: ", scalar keys %kids;
            $peer->close;
            wait_kids;
            next;
        }
        defined (my $pid = fork) or die "[serv] cant fork lol\n$!";
        unless ($pid) {
            $sock->close;
            $req = ''; $peer->recv($req, 1024);
            say "[$$] request:\n[$req\n]";
            parse_req;
            say "[$$] sleep time: $sleep sec";
            sleep $sleep if $sleep;
            $peer->send($resp);
            $peer->close;
            say "[$$] done\n";
            exit 0;
        }
        $peer->close;
        $kids{$pid}++;
        say "[master] babies: ", scalar keys %kids;
    }
    $sock->close;
}
wait_kids;
exit 0;

__DATA__
<!DOCTYPE HTML>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>PANDA TASK07</title>
</head>
<body>
    <div class="shitcontent">
         <div class="top">
            Crazy Panda task7 server
        </div>
        <div class="center">
            <div class="txt">
                there's nothing here yet<br>
                ...coming soon
            </div>
       <div class="bottom">
            <span class="mc">©madcore</span>, contacts:  
            <a href="mailto:madcore@madcore.fun">e-mail</a> |
            <a href="https://t.me/madcore_fun" target="_blank">telega</a>
        </div>
</body>
</html>
<style>
body {
    background-color: olive;
}

.shitcontent {
    text-align: center;
    position: absolute; 
    top:8px;
    right: 8px;
    left: 8px;
    bottom: 8px;
}

.top {
        background-color: darkblue;
        color: gold;
        border: 3px solid green;
        font-size: xx-large;
        padding: 32px;
        text-align: center;
    right: 16px;
    left: 16px;
    position: absolute;
}

.vspace {
    padding: 8px;
}    

.txt {
    position: relative;
    top: 50%;
    transform: translateY(-50%);
}

.center {
        background-color: darkcyan;
        color: antiquewhite;
        border: 3px solid green;
        font-size: xxx-large;
        text-align: center;
    right: 4px;
    left: 4px;
    bottom: 32px;
    top: 32px;
    z-index: -1;
    position: absolute;
}

.bottom {
        background-color: darkblue;
        color: aqua;
        border: 3px solid green;
        text-align: center;
        font-size: xx-large;
    position: absolute;
        padding: 32px;
    right: 16px;
    left: 16px;
    bottom: 8px;
}

.mc {
    color: burlywood;
}

a:link {
    color: cadetblue;
}  

a:visited {
    color: cadetblue;
}
  
a:hover {
        color: hotpink;
}

a:active {
    color: blue;
}
</style>


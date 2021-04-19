#!/usr/bin/env perl

use Test::Most;

use Log::Log4perl;

use utf8;
use Encode;

subtest "no mdc" => sub {

    *main::hello = sub {+{hello => 'world'}};

    my $conf = q(
        log4perl.rootLogger = INFO, Test
        log4perl.appender.Test = Log::Log4perl::Appender::String
        log4perl.appender.Test.layout = Log::Log4perl::Layout::JSON
        log4perl.appender.Test.layout.field.message = %m
        log4perl.appender.Test.layout.field.category = %c
        log4perl.appender.Test.layout.field.class = %C
        log4perl.appender.Test.layout.field.file = %F{1}
        log4perl.appender.Test.layout.field.AAAA.BBBB.SUB = %M{1}
        log4perl.appender.Test.layout.field.AAAA.BBBB.CODE = sub {\&hello}
        log4perl.appender.Test.layout.field.BBBB.AAAA.FILE = %F{1}
        log4perl.appender.Test.layout.canonical = 1
    );
    Log::Log4perl::init( \$conf );
    Log::Log4perl::MDC->remove;

    ok my $appender = Log::Log4perl->appender_by_name("Test");

    my $logger = Log::Log4perl->get_logger('foo');

    $logger->info('info message');

    my $got = $appender->string();
    my $expected = '{"AAAA":{"BBBB":{"CODE":{"hello":"world"},"SUB":"__ANON__"}},"BBBB":{"AAAA":{"FILE":"complex-fields.t"}},"category":"foo","class":"main","file":"complex-fields.t","message":"info message"}'."\n";

    is_deeply $got, $expected;

    $appender->string('');
};

done_testing();

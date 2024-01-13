# NAME

Log::Log4perl::Layout::JSON - Layout a log message as a JSON hash, including MDC data

# VERSION

version 0.60

# SYNOPSIS

Example configuration:

    log4perl.appender.Example.layout = Log::Log4perl::Layout::JSON
    log4perl.appender.Example.layout.field.message = %m{chomp}
    log4perl.appender.Example.layout.field.category = %c
    log4perl.appender.Example.layout.field.class = %C
    log4perl.appender.Example.layout.field.file = %F{1}
    log4perl.appender.Example.layout.field.sub = %M{1}
    log4perl.appender.Example.layout.include_mdc = 1

    # Optional truncation of specific fields
    log4perl.appender.Example.layout.maxkb.message = 2

    # Note: Appender option!
    # log4perl.appender.Example.warp_message = 0

See below for more configuration options.

# DESCRIPTION

This class implements a `Log::Log4perl` layout format, similar to
[Log::Log4perl::Layout::PatternLayout](https://metacpan.org/pod/Log%3A%3ALog4perl%3A%3ALayout%3A%3APatternLayout) except that the output is a JSON hash.

The JSON hash is ASCII encoded, with no newlines or other whitespace, and is
suitable for output, via Log::Log4perl appenders, to files and syslog etc.

Contextual data in the [Log::Log4perl::MDC](https://metacpan.org/pod/Log%3A%3ALog4perl%3A%3AMDC) hash will be included if
["include\_mdc"](#include_mdc) is true.

# LAYOUT CONFIGURATION

## field

Specify one or more fields to include in the JSON hash. The value is a string
containing one of more [Log::Log4perl::Layout::PatternLayout](https://metacpan.org/pod/Log%3A%3ALog4perl%3A%3ALayout%3A%3APatternLayout) placeholders.
For example:

    log4perl.appender.Example.layout.field.message = %m{chomp}
    log4perl.appender.Example.layout.field.category = %c
    log4perl.appender.Example.layout.field.where = %F{1}:%L

If no fields are specified, the default is `message = %m{chomp}`.
It is recommended that `message` be the first field.

## prefix

Specify a prefix string for the JSON. For example:

    log4perl.appender.Example.layout.prefix = @cee:

See http://blog.gerhards.net/2012/03/cee-enhanced-syslog-defined.html

## format\_prefix

If this is turned on, the prefix is treated as a
[Log::Log4perl::Layout::PatternLayout](https://metacpan.org/pod/Log%3A%3ALog4perl%3A%3ALayout%3A%3APatternLayout) string, and will be rendered as a
pattern layout.

For example:

    log4perl.appender.Example.layout.prefix = %m{chomp} @cee:
    log4perl.appender.Example.layout.format_prefix = 1

Would log `Hello World` as:

    Hello World @cee:{ .. MDC as JSON ... }

See also ["prefix"](#prefix)

## exclude\_message

Exclude the message from the JSON (default: 0).  If you are logging the message
in the prefix for example, you may want to omit the message from the JSON
layout.

## include\_mdc

Include the data in the Log::Log4perl::MDC hash.

    log4perl.appender.Example.layout.include_mdc = 1

See also ["name\_for\_mdc"](#name_for_mdc).

## maxkb

Use this name with the field name to specify a maximum length for a specific
field. For example:

    log4perl.appender.Example.maxkb.message = 2

Will truncate message if it is more than 2048 bytes in length.  Truncated
message will have a marker at the end like
`...[truncated, was $len chars total]...`

## name\_for\_mdc

Use this name as the key in the JSON hash for the contents of MDC data

    log4perl.appender.Example.layout.name_for_mdc = mdc

If not set then MDC data is placed at top level of the hash.

Where MDC field names match the names of fields defined by the Log4perl
configuration then the MDC values take precedence. This is currently construde
as a feature.

## canonical

If true then use canonical order for hash keys when encoding the JSON.

    log4perl.appender.Example.layout.canonical = 1

This is mainly intended for testing.

## max\_json\_length\_kb

Set the maximum JSON length in kilobytes. The default is 20KB.

    log4perl.appender.Example.layout.max_json_length_kb = 3.8

This is useful where some downstream system has a limit on the maximum size of
a message.

For example, rsyslog has a `maxMessageSize` configuration parameter with a
default of 4KB. Longer messages are simply truncated (which would corrupt the
JSON). We use rsyslog with maxMessageSize set to 128KB.

If the JSON is larger than the specified size (not including ["prefix"](#prefix))
then some action is performed to reduce the size of the JSON.

Currently fields are simply removed until the JSON is within the size.
The MDC field/fields are removed first and then the fields specified in the
Log4perl config, in reverse order. A message is printed on `STDERR` for each
field removed.

In future this rather dumb logic will be replaced by something smarter.

## utf8

Switch JSON encoding from ASCII to UTF-8.

## warp\_message = 0

The `warp_message` **appender option** is used to specify the desired behavior
for handling log calls with multiple arguments.
The default behaviour (`warp_message` not set>) is to concatenate all
arguments using `join( $Log::Log4perl::JOIN_MSG_ARRAY_CHAR, @log_args )` and
setting a JSON field `message` to this simple string.

If, on the other hand, `warp_message = 0` is applied, then for log calls with
multiple arguments these are considered name/value pairs and rendered to a
hash-like JSON structure.
For log calls with an odd number of arguments (3 or more), the first argument
is considered the `message` and the others are again considered
name/value pairs.

See ["Appenders Expecting Message Chunks" in Log::Log4perl::Appender](https://metacpan.org/pod/Log%3A%3ALog4perl%3A%3AAppender#Appenders-Expecting-Message-Chunks) for more info
on the configuration option.

## EXAMPLE USING Log::Log4perl::MDC

    local Log::Log4perl::MDC->get_context->{request} = {
        request_uri => $req->request_uri,
        query_parameters => $req->query_parameters
    };

    # ...

    for my $id (@list_of_ids) {

        local Log::Log4perl::MDC->get_context->{id} = $id;

        do_something_useful($id);

    }

Using code like that shown above, any log messages produced by
do\_something\_useful() will automatically include the 'contextual data',
showing the request URI, the hash of decoded query parameters, and the current
value of $id.

If there's a `$SIG{__WARN__}` handler setup to log warnings via `Log::Log4perl`
then any warnings from perl, such as uninitialized values, will also be logged
with this context data included.

The use of `local` ensures that contextual data doesn't stay in the MDC
beyond the relevant scope. (For more complex cases you could use something like
[Scope::Guard](https://metacpan.org/pod/Scope%3A%3AGuard) or simply take care to delete old data.)

# HISTORY

Originally created and maintained through v0.002003 by Tim Bunce.  Versions
0.50 and later maintained by Michael Schout <mschout@cpan.org>

# SOURCE

The development version is on github at [https://github.com/mschout/Log-Log4perl-Layout-JSON](https://github.com/mschout/Log-Log4perl-Layout-JSON)
and may be cloned from [https://github.com/mschout/Log-Log4perl-Layout-JSON.git](https://github.com/mschout/Log-Log4perl-Layout-JSON.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/mschout/Log-Log4perl-Layout-JSON/issues](https://github.com/mschout/Log-Log4perl-Layout-JSON/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Michael Schout <mschout@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Tim Bunce.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

#!perl -w

# unattended Mail::Sendmail test, sends a message to the author
# but you probably want to change $mail{To} below
# to send the message to yourself.

$mail{From} = 'Sendmail Test <ivkovic@csi.com>'; 
$mail{To}   = 'Sendmail Test <mi@alma.ch>';
#$mail{To}   = 'Sendmail Test <mi@alma.ch>, You me@myaddress';
#$server = 'use.your.own.smtp.server';

BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}

use Mail::Sendmail;
$loaded = 1;
print "ok 1\n";

print <<EOT
Test Mail::Sendmail $Mail::Sendmail::VERSION

(The test is designed so it can be run by Test::Harness from CPAN.pm.
Edit it to send the mail to yourself for more concrete feedback, and
to change the default mail server from Compuserve's "smpt.site1.csi.com"
to your own.)

Try to send a message to the author (and/or whoever if you edited test.pl)

Current recipient(s): '$mail{To}'

The default mail server is $Mail::Sendmail::default_smtp_server
EOT
;

if ($server) {
    $mail{Smtp} = $server;
    print "Server set to: $server\n";
}

$mail{Subject} = "Mail::Sendmail version $Mail::Sendmail::VERSION test";

$mail{Message} = "This is a test message sent with Perl version $] from a $^O system.\n\n";
$mail{Message} .= "It contains an accented letter: à (a grave).\n";
$mail{Message} .= "It was sent on " . Mail::Sendmail::time_to_date() . "\n";

# Go send it
print "Sending...\n";

if (sendmail %mail) {
    print "content of \$Mail::Sendmail::log:\n$Mail::Sendmail::log\n";
    if ($Mail::Sendmail::error) {
        print "content of \$Mail::Sendmail::error:\n$Mail::Sendmail::error\n";
    }
    print "ok 2\n";
}
else {
    print "\n!Error sending mail:\n$Mail::Sendmail::error\n";
    print "not ok 2\n";
}

#!/usr/bin/perl -w

# unattended Mail::Sendmail test, sends a message to the author (in an attempt
# to enable the use of CPAN.pm) but you probably want to change $mail{To} below
# to send the message to yourself.

use Mail::Sendmail;
my (%mail, $server);

$mail{From} = 'ivkovic@csi.com'; 
$mail{To}   = 'mi@alma.ch'; 

#$server = 'mail.mediaprofil.ch';
#$TZ = "+0330";

print "\nTest Mail::Sendmail $Mail::Sendmail::VERSION by sending a message to $mail{To}\n\n";

print "The default mail server is $Mail::Sendmail::default_smtp_server\n";
if ($server) {
    $mail{Smtp} = $server;
    print "Server set to: $server\n";
}

if (defined($TZ)) {
    $Mail::Sendmail::TZ = $TZ;
    print "Time Zone set to: $TZ\n";
}

$mail{Subject} = "Mail::Sendmail version $Mail::Sendmail::VERSION test";

$mail{Message} = "This is a test message sent with Perl version $] from a $^O system.\n\n";
$mail{Message} .= "It should contain an empty line above this one,\n";
$mail{Message} .= "and an accented letter: à (a grave).\n\n";
$mail{Message} .= "The time here appears to be " . Mail::Sendmail::time_to_date() . "\n";

# Send it
print "Sending...\n\n";

if (sendmail %mail) {
    print <<EOT;
content of \$Mail::Sendmail::log:
$Mail::Sendmail::log

EOT
    if ($Mail::Sendmail::error) {
        print <<EOT;
content of \$Mail::Sendmail::error:
$Mail::Sendmail::error
EOT
    }
    print "OK\n";
}
else {
    print "\n!Error sending mail:\n$Mail::Sendmail::error\n";
    die;
}

#!/usr/bin/perl -w

# unattended Mail::Sendmail test, sends a message to the author
# change $mail{To} to send the message to yourself

use Mail::Sendmail;
my (%mail, $TZ, $server);

$mail{From} = 'ivkovic@csi.com'; 
$mail{To}   = 'mi@alma.ch, ivkovic@compuserve.com'; 

#$server = 'mail.mediaprofil.ch';
#$TZ = 1;

print "\nTest Mail::Sendmail $Mail::Sendmail::VERSION by sending a message to $mail{To}\n\n";

print "The default mail server is $Mail::Sendmail::default_smtp_server\n";
if ($server) {
    $mail{Smtp} = $server;
    print "Server set to: $server\n";
}

print "The default Time Zone is $Mail::Sendmail::TZ\n";
if (defined($TZ)) {
    $Mail::Sendmail::TZ = $TZ;
    print "Time Zone set to: $TZ\n";
}

$mail{Subject} = "Mail::Sendmail version $Mail::Sendmail::VERSION test";

$mail{Message} = "This is a test message sent with Perl version $] from an $^O system.\n\n";
$mail{Message} .= "It should contain an empty line above this one,\n";
$mail{Message} .= "and an accented letter: à (a grave).\n";
#$mail{Message} .= "and no accented letter.\n";

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
    die "\n!Error sending mail:\n$Mail::Sendmail::error\n"
}

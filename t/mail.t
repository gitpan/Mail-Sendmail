#!/usr/bin/perl -w

# test Mail::Sendmail by sending a message to yourself

use Mail::Sendmail;

my (%mail, $TZ, $server);
my $adr = ""; 
my $adr_rx = $Mail::Sendmail::address_rx;

print "\ntest Mail::Sendmail $Mail::Sendmail::VERSION by sending a message to yourself\n\n";

# Get e-mail address
while (not $adr =~ /$adr_rx/) {
	print "Your e-mail address: ";
	$adr = <STDIN>;
	chomp($adr);
	unless ($adr) {die "No address to send to. Aborting.\n"};
}
print "\n";

$mail{To} = $mail{From} = $adr;

# Get SMTP server
print "The current default mail server is $Mail::Sendmail::default_smtp_server\n";
print "Your mail server is [<Enter> to use default]: ";
$server = <STDIN>;
chomp($server);
print "\n";

$mail{Smtp} = $server if $server;

# Get Time Zone
print "The current default Time Zone is $Mail::Sendmail::TZ\n";
print "Your Time Zone [<Enter> to use default, 1 for Paris, -5 for New York, ...]: ";
$TZ = <STDIN>;
chomp($TZ);
print "\n";

if ($TZ ne "") {
	print "TZ set to: $TZ\n";
	$Mail::Sendmail::TZ = $TZ;
}

# Get Subject and message
print "Subject: ";
$mail{Subject} = <STDIN>;
chomp($mail{Subject});

print "Message text: ";
$mail{Message} = <STDIN>;

# Send it
print "Sending...\n";

if (sendmail %mail) { print "\n\$Mail::Sendmail::log says:\n$Mail::Sendmail::log\n\nOK\n" }
else { print "\n!Error sending mail: $Mail::Sendmail::error \n" }

package Mail::Sendmail;
# Mail::Sendmail by Milivoj Ivkovic <mi@alma.ch> or <ivkovic@csi.com>
# see embedded POD documentation below or http://alma.ch/perl/mail.htm

$VERSION  = "0.71";

# *************** CUSTOMIZE the following lines *********************

# set your Time Zone here in numeric form, negative if west of Greenwich.

$TZ = 1; # London = 0, Europe = 1, New-York = -5, etc...

# put your mail server name here (or override it in each message)

$default_smtp_server = 'smtp.site1.csi.com';

# if you have a strange server not on port 25, set the port here.
# (Needs to be hardcoded for Win95 compatibility)

$default_smtp_port = 25;

# *******************************************************************

=head1 NAME

Mail::Sendmail v. 0.71 - Simple platform independent mailer


=head1 SYNOPSIS

  use Mail::Sendmail;

  %mail = ( To      => 'you@there.com',
            From    => 'me@here.com',
            Message => "This is a minimalistic message"
           );

  if (sendmail %mail) { print "Mail sent OK.\n" }
  else { print "Error sending mail: $Mail::Sendmail::error \n" }

  print STDERR "\n\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log;

=head1 DESCRIPTION

Simple platform independent e-mail from your perl script.

After struggling for some time with various command-line mailing programs
which didn't give me all the control I wanted, I found a nice script by
Christian Mallwitz, put it into a module, and added a few features I wanted.

Mail::Sendmail contains mainly &sendmail, which takes a hash with the
message to send and sends it...

sendmail is exported to your namespace.

=head1 INSTALLATION

- Copy Sendmail.pm to Mail/ in your Perl lib directory
  (eg. c:\Perl\lib\Mail\, c:\Perl\lib\site\Mail\,
  /usr/lib/perl5/site_perl/Mail/, ... or whatever it is on your system)

- At the top of Sendmail.pm, set your Time Zone and your default SMTP server

- If you want to use MIME quoted-printable encoding, you need
MIME::QuotedPrint from CPAN. It's in the MIME-Base64 package.
To get it with your browser go to
http://www.perl.com/CPAN//modules/by-module/MIME/

=head1 FEATURES

- Mime quoted printable encoding if requested (needs MIME::QuotedPrint)

- Bcc: and Cc: support

- Doesn't send unwanted headers

- Allows you to send any header you want

- Doesn't abort sending if there is a bad recipient address among other good ones

- Makes verbose error messages

- Adds the Date header if you don't supply your own

=head1 LIMITATIONS

Doesn't send attachments (you can still send them if you provide
the appropriate headers and boundaries, but that may not be practical).

Not tested in a situation where the server goes down during session

=head1 USAGE DETAILS

=over

=item sendmail

sendmail is the only thing exported to your namespace

C<sendmail(%mail) || print "Error sending mail: $Mail::Sendmail::error\n";>

- takes a hash containing the full message, with keys for all headers, Body,
  and optionally for another non-default SMTP server. (The Body part can be
  called "Body", "Message" or "Text")

- returns 1 on success, 0 on error.

updates C<$Mail::Sendmail::error> and C<$Mail::Sendmail::log>.

Keys are not case-sensitive. They get normalized before use with
C<ucfirst( lc $key )>

=back

The following are not exported, but you can still access them with their full name:

=over

=item Mail::Sendmail::time_to_date()

convert time ( as from C<time()> ) to a string suitable for the Date header as per RFC 822.

=item $Mail::Sendmail::VERSION

The package version number

=item $Mail::Sendmail::error

Fatal or non-fatal socket or SMTP server errors

=item $Mail::Sendmail::log

You can check it out after a sendmail to see what it says

=item $Mail::Sendmail::address_rx

A handy regex to recognize e-mail addresses

  Example:
    $rx = $Mail::Sendmail::address_rx;
    if (/$rx/) {
      $address=$1;
      $user=$2;
      $domain=$3;
    }

=item $Mail::Sendmail::default_smtp_server

see Configuration below

=item $Mail::Sendmail::default_smtp_port

see Configuration below

=item $Mail::Sendmail::TZ

Time Zone. see Configuration below

=back

=head1 CONFIGURATION

At the top of Sendmail.pm, there are 2 variables you have to set:

- your Time Zone (until I change the module so it finds the TZ itself).
  (1 hour for daylight savings time is added if your system says it should be)

- your default SMTP server.

and the port number if your server doesn't use the default port 25 (which
would be surprising, but who knows).

If you want a different server only for a particular script put
  C<$Mail::Sendmail::default_smtp_server = 'newserver.my-domain.com';>
in your script.

If you want a different server only for a particular message, add it to
your %message hash with a key of 'Smtp':
  C<$message{Smtp} = 'newserver.my-domain.com';>

=head1 ANOTHER EXAMPLE

  use Mail::Sendmail;

  print STDERR "Testing Mail::Sendmail version $Mail::Sendmail::VERSION\n";
  print STDERR "smtp server: $Mail::Sendmail::default_smtp_server\n";
  print STDERR "server port: $Mail::Sendmail::default_smtp_port\n";

  %mail = (
      #To      => 'No to field this time, only Bcc and Cc',
      From    => 'Myself <me@here.com>',
      Bcc     => 'Someone <him@there.com>, Someone else her@there.com',
      # only addresses are extracted from Bcc, real names disregarded
      Cc      => 'Yet someone else <xz@whatever.com>',
      # Cc will appear in the header. (Bcc will not)
      Subject => 'Test message',
      'Content-transfer-encoding' => 'quoted-printable',
      'X-Mailer' => "Mail::Sendmail",
  );

  $mail{Smtp} = 'special_server.for-this-message-only.domain.com';
  $mail{'X-custom'} = 'My custom additionnal header';
  $mail{message} = "Only a short message";
  $mail{Date} = Mail::Sendmail::time_to_date( time() - 86400 ), # cheat on the date

  if (sendmail %mail) { print "Mail sent OK.\n" }
  else { print "Error sending mail: $Mail::Sendmail::error \n" }

  print STDERR "\n\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log;

=head1 CHANGES

0.71: Fixed Time Zone bug with AS port.
      Added half-hour Time Zone support.
      Repackaged with \n line endings instead of \r\n.

=head1 AUTHOR

Milivoj Ivkovic mi@alma.ch or ivkovic@csi.com


=head1 NOTES

You can use this freely.

I would appreciate a short (or long) e-mail note if you do.
And of course, bug-reports and/or improvements are welcome.

This version has been tested on Win95 and WinNT 4.0 with
Perl 5.003_07 (AS 313) and Perl 5.004_02 (GS),
and on Linux 2.0.34 (Red Hat 5.1) with 5.004_04.

Last revision: 07.07.98. Latest version should be available at
http://alma.ch/perl/mail.htm

=cut

BEGIN {
	use Exporter   ();
	use Socket;

	eval "use MIME::QuotedPrint";
	if ($@) {
		warn "MIME::QuotedPrint not present. You won't be able to encode accented characters!\n";
		$MIME_OK = 0;
	}
	else {$MIME_OK = 1};
	
	@ISA        = qw(Exporter);
	@EXPORT     = qw(&sendmail);
}

$address_rx = '\b(([\w-]+(?:\.[\w-]+)*)\@([\w-]+(?:\.[\w-]+)+))\b'; # where full=$1, user=$2, domain=$3

$debug = 0;

sub time_to_date {
	# convert a time() value to a date-time string according to RFC 822
    
    my $time = $_[0] || time(); # default to now if no argument

	my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	my @wdays  = qw(Sun Mon Tue Wed Thu Fri Sat);

	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);

	$mon = $months[$mon];
	$wday = $wdays[$wday];

	my $zone = sprintf("%+05d", ($TZ + $isdst) * 100);
	$zone =~ s/[^0]0$/30/o; # half-hour zone (even if $TZ == 3.1416 or whatever silly)
		
	return join(" ", $wday.",", $mday, $mon, $year+1900, sprintf("%02d", $hour) . ":" . sprintf("%02d", $min), $zone );
}

sub sendmail {
    # original sendmail 1.21 by Christian Mallwitz.
    # Modified and 'modulized' by ivkovic@csi.com
	
	$error = '';
    $log = "Mail::Sendmail v. $VERSION - "	. scalar(localtime()) . "\n";
    
    local $_;
    
	# redo hash, arranging keys case
    my %mail; my $k;
    while ($k = shift @_) {
		$mail{ucfirst lc $k} = shift @_;
	}

    my $smtp = $mail{Smtp} || $default_smtp_server;
    delete $mail{Smtp}; # so we don't send it later as a header
    
    my $message	= $mail{Message} || $mail{Body} || $mail{Text};
    delete($mail{Message}) || delete($mail{Body}) || delete($mail{Text}); # so we don't send it later as a header
    
    # Extract from e-mail address
    my $fromaddr = $mail{From};
	unless ($fromaddr =~ /$address_rx/o) {
		$error = "Bad From address: $fromaddr";
		return 0;
	}	# get from email address
    $fromaddr = $1;

    $mail{'X-mailer'} .= " $VERSION" if defined $mail{'X-mailer'};

	# Default MIME headers if needed
	unless ($mail{'Mime-version'}) {
		 $mail{'Mime-version'} = '1.0';
	};
	unless ($mail{'Content-type'}) {
		 $mail{'Content-type'} = 'text/plain; charset="iso-8859-1"';
	};
	unless ($mail{'Content-transfer-encoding'}) {
		 $mail{'Content-transfer-encoding'} = '8bit';
	};

	# add Date header if needed
	unless ($mail{Date}) {
		 $mail{Date} = time_to_date;
	};

    # cleanup message, and encode if needed
    $message =~ s/^\./\.\./gm; 	# handle . as first character
    #$message =~ s/\r\n/\n/g; 	# handle line ending
    #$message =~ s/\n/\r\n/g;
    $message = encode_qp($message) if ($MIME_OK and $mail{'Content-transfer-encoding'} =~ /^quoted/io);
    
	# cleanup smtp
    $smtp =~ s/^\s+//g; # remove spaces around $mail{Smtp}
    $smtp =~ s/\s+$//g;
    
    # Get recipients
    # my $recip = join(' ', $mail{To}, $mail{Bcc}, $mail{Cc});
    # Nice and short, but gives 'undefined' errors with -w switch,
    # so here's another way:
    my $recip = "";
    $recip   .= $mail{To}        if defined $mail{To};
    $recip   .= " " . $mail{Bcc} if defined $mail{Bcc};
    $recip   .= " " . $mail{Cc}  if defined $mail{Cc};
    
    my @recipients = ();
    while ($recip =~ /$address_rx/go) {
    	push @recipients, $1;
    }
    unless (@recipients) { $error .= "No recipient!"; return 0 }

    delete $mail{Bcc};
    
    my($proto) = (getprotobyname('tcp'))[2];
    
    # the following produced a "runtime exception" under Win95:
    # my($port) = (getservbyname('smtp', 'tcp'))[2]; 
    # so I just hardcode the port at the start of the module: 
    my $port = $default_smtp_port;
    
    my($smtpaddr) =
    	($smtp =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)
    	? pack('C4',$1,$2,$3,$4)
    	: (gethostbyname($smtp))[4];
    
    unless (defined($smtpaddr)) {
    	$error .= "smtp host \"$smtp\" unknown";
    	return 0
    }
    
	# Add info to log variable
    $log .= "Server: $smtp Port: $port\n"
    		   . "From: $fromaddr\n"
    		   . "Subject: $mail{Subject}\n"
    		   . "To: ";
	
	# open socket and start mail session
	
    if (!socket(S, AF_INET, SOCK_STREAM, $proto)) {
    	$error .= "socket failed ($!)";
    	return 0
    }
    if (!connect(S, pack('Sna4x8', AF_INET, $port, $smtpaddr))) {
    	$error .= "connect failed ($!)";
    	return 0;
    }
    
    my($oldfh) = select(S); $| = 1; select($oldfh);
    
    $_ = <S>;
    if (/^[45]/) {
    	close S;
    	$error .= "service unavailable: $_";
		return 0;
	}
    
    print S "helo localhost\r\n";
    $_ = <S>;
    if (/^[45]/) {
    	close S;
    	$error .= "mysterious communication error: $_";
		return 0;
	}
    
    print S "mail from: <$fromaddr>\r\n";
    $_ = <S>;
    if (/^[45]/) {
    	close S;
    	$error .= "mysterious communication error: $_";
    	return 0;
    }
    
    foreach $to (@recipients) {
    	if ($debug) { print STDERR "sending to: <$to>\n"; }
    	print S "rcpt to: <$to>\r\n";
    	$_ = <S>;
    	if (/^[45]/) {
    		$error .= "Error sending to <$to>: $_\n";
    		$log .= "!Failed: $to\n    ";
    	}
    	else {
    		$log .= "$to\n    ";
    	}
    }
    
    # send headers
    print S "data\r\n";
    $_ = <S>;
    if (/^[45]/) {
    	close S;
    	$error .= "mysterious communication error: $_";
    	return 0;
    }
    
    #Is the order of headers important? Probably not! 

    # print headers
    foreach $header (keys %mail) {
    	print S "$header: ", $mail{$header}, "\r\n";
    };
    
    # send message body and quit
    print S "\r\n",
    		$message,
    		"\r\n.\r\n"
    		;
    
    $_ = <S>;
    if (/^[45]/) {
    	close S;
    	$error .= "transmission of message failed: $_";
    	return 0;
    }
    
    print S "quit\r\n";
    $_ = <S>;
    
    close S;
    return 1;
} # end sub sendmail

	END { }       # module clean-up code here (global destructor)
	$VERSION;	# repeat to avoid "used only once" warning, and also for "modules must return true"
	
__END__
changes:

0.70:	corrected bug when hash key passed with empty or undefined (=false) value
0.69:   use MIME::Quotedprint in eval, so it works without it.
0.64:	Message body can be in $mail{Message} or $mail{Body} or $mail{Text}
		(I couldn't remember which it was myself, so now it doesn't matter.)
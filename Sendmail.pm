package Mail::Sendmail;
# Mail::Sendmail by Milivoj Ivkovic <mi@alma.ch> or <ivkovic@csi.com>
# see embedded POD documentation below or http://alma.ch/perl/mail.htm

$VERSION  = "0.73";

# *************** CUSTOMIZE the following lines *********************

# put your mail server name here (or override it in each message)

$default_smtp_server = 'smtp.site1.csi.com';

# if you have trouble with the automatic Time Zone detection, set it here
# in RFC 822 compliant format ("+0330", "-0800", etc...)

$TZ = ''; # leave empty to auto-detect
#$TZ = '+0200'; # Western Europe with daylight savings time

# if you have a strange server not on port 25, set the port here.
# (or override it in each message). It needs to be hardcoded for Win95 compatibility

$default_smtp_port = 25;

# you can also have a default from address:
$default_sender = '';
#$default_sender = 'This is me <me@here>'; # use single quotes or escape '@' ("me\@here") !

# *******************************************************************

=head1 NAME

Mail::Sendmail v. 0.73 - Simple platform independent mailer


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
which never did exactly what I wanted, I put together this Perl only solution.

Mail::Sendmail contains mainly &sendmail, which takes a hash with the
message to send and sends it...

=head1 INSTALLATION

- Copy Sendmail.pm to Mail/ in your Perl lib directory
  (eg. c:\Perl\lib\Mail\, c:\Perl\lib\site\Mail\,
  /usr/lib/perl5/site_perl/Mail/, ... or whatever it is on your system)

- At the top of Sendmail.pm, set your default SMTP server

- MIME::QuotedPrint is strongly recommended. It's in the MIME-Base64 package.
  Get it from http://www.perl.com/CPAN/modules/by-module/MIME. It is used
  by default on every message, and is needed to send accented characters safely.

=head1 FEATURES

- Automatic Mime quoted printable encoding (if MIME::QuotedPrint installed)

- Bcc: and Cc: support

- Doesn't send unwanted headers

- Allows you to send any header you want

- Doesn't abort sending if there is a bad recipient address among other good ones

- Returns verbose error messages

- Adds the Date header if you don't supply your own

- Automatic Time Zone detection (hopefully)

=head1 LIMITATIONS

Doesn't send attachments. You can probably still send them if you provide
the appropriate headers and boundaries, but that may not be practical,
and I haven't tested it.

Not tested in a situation where the server goes down during session

The SMTP server has to be set manually in Sendmail.pm or in your script,
unless you can live with the default (Compuserve's smpt.site1.csi.com).

I couldn't test the automatic time zone detection much. If it doesn't work,
set it manually (see below) and please let me know.

=head1 DETAILS

=over 4

=item sendmail()

sendmail is the only thing exported to your namespace

C<sendmail(%mail) || print "Error sending mail: $Mail::Sendmail::error\n";>

- takes a hash containing the full message, with keys for all headers, Body,
  and optionally for another non-default SMTP server and/or Port.
  (The Body part can be called "Body", "Message" or "Text")

- returns 1 on success, 0 on error.

updates C<$Mail::Sendmail::error> and C<$Mail::Sendmail::log>.

Keys are not case-sensitive. They get normalized before use with
C<ucfirst( lc $key )>. The colon after headers is not necessary.

The following headers are added unless you specify them yourself:

    Mime-version: 1.0
    Content-type: 'text/plain; charset="iso-8859-1"'

    Content-transfer-encoding: quoted-printable
    or (if MIME::QuotedPrint not installed)
    Content-transfer-encoding: 8bit 
    
    Date: [string returned by time_to_date()]

If you put an 'X-mailer' header, the package version number
is appended to it.

=back

The following are not exported, but you can still access
them with their full name:

=over 4

=item Mail::Sendmail::time_to_date()

convert time ( as from C<time()> ) to a string suitable for the Date header as per RFC 822.
See also $Mail::Sendmail::TZ.

=item $Mail::Sendmail::VERSION

The package version number

=item $Mail::Sendmail::error

Fatal or non-fatal socket or SMTP server errors

=item $Mail::Sendmail::log

A summary that you could write to a log file after each send

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

=item $Mail::Sendmail::default_sender

see Configuration below

=item $Mail::Sendmail::TZ

Your time zone. It should be set automatically, from the difference
between time() and gmtime(), unless it has been preset in Sendmail.pm.

If it doesn't work for you, let me know so I can try to fix it,
and in the meantime, set it manually in RFC 822 compliant format:

C<$Mail::Sendmail::TZ = "+0200"; # Western Europe in summer>

=back

=head1 CONFIGURATION

=over 4

=item default SMTP server (recommended setting)

Set this at the top of Sendmail.pm, unless you want to use the provided default.

You can override the default in a particular script with:

C<$Mail::Sendmail::default_smtp_server = 'newserver.my-domain.com';>

or just for a particular message by adding it to your %message hash with a key of 'Smtp':

C<$message{Smtp} = 'newserver.my-domain.com';>

=item default port (optional)

If your server doesn't use the default port 25, also change this at the
top of Sendmail.pm.

Or override it for a particular script with:

C<$Mail::Sendmail::default_smtp_port = 8025;>

or just for a particular message by adding it to your %message hash with a key of 'Port':

C<$message{Port} = 8025;>

=item $default_sender (optional)

If you set this, you don't need to define %message{From} in every message.

=back

=head1 ANOTHER EXAMPLE

  use Mail::Sendmail;

  print STDERR "Testing Mail::Sendmail version $Mail::Sendmail::VERSION\n";
  print STDERR "smtp server: $Mail::Sendmail::default_smtp_server\n";
  print STDERR "server port: $Mail::Sendmail::default_smtp_port\n";

  $Mail::Sendmail::default_sender = 'This is me <myself@here.com>';
  
  %mail = (
      #To      => 'No to field this time, only Bcc and Cc',
      #From    => 'not needed, use default',
      Bcc     => 'Someone <him@there.com>, Someone else her@there.com',
      # only addresses are extracted from Bcc, real names disregarded
      Cc      => 'Yet someone else <xz@whatever.com>',
      # Cc will appear in the header. (Bcc will not)
      Subject => 'Test message',
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

0.73: Line endings changed again to hopefully be Mac compatible at last.
      Automatic time zone detection.
      Support for SMTP Port change for single messages.
      Always default to quoted-printable encoding if possible.
      Added $Mail::Sendmail::default_sender.

0.72: Fixed line endings in Body to "\r\n".
      MIME quoted printable encoding is now automatic if needed.
      Test script can now run unattended.

0.71: Fixed Time Zone bug with AS port.
      Added half-hour Time Zone support.
      Repackaged with \n line endings instead of \r\n.

=head1 AUTHOR

Milivoj Ivkovic mi@alma.ch or ivkovic@csi.com


=head1 NOTES                             

This module was first based on a script by Christian Mallwitz.

You can use it freely.

I would appreciate a short (or long) e-mail note if you do (and even if you don't,
especially if you care to say why).
And of course, bug-reports and/or suggestions are welcome.

This version has been tested on Win95 and WinNT 4.0 with
Perl 5.003_07 (AS 313) and Perl 5.004_02 (GS),
and on Linux 2.0.34 (Red Hat 5.1) with 5.004_04.

Last revision: 13.07.98. Latest version should be available at
http://alma.ch/perl/mail.htm, and a few days later on CPAN.

=cut

BEGIN {
	use Exporter   ();
	use Socket;
	use Time::Local; # only needed for automatic time zone detection

	eval "use MIME::QuotedPrint";
	if ($@) {
		$use_MIME = 0;
	}
	else {$use_MIME = 1};
	
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

	if ($TZ eq "") {
	    my $offset = sprintf "%.1f", ( timegm(localtime()) - time() ) / 3600; # in hours
	    my $minutes = sprintf "%02d", ( $offset - int($offset) ) * 60;
        $TZ  = sprintf("%+03d", int($offset)) . $minutes;
    }    
	return join(" ", $wday.",", $mday, $mon, $year+1900, sprintf("%02d", $hour) . ":" . sprintf("%02d", $min), $TZ );
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
        $k = ucfirst lc $k;
        $k =~ s/\s*:\s*$//o; # kill colon (and possible spaces) at end, we add it later.
		$mail{$k} = shift @_;
	}

    my $smtp = $mail{Smtp} || $default_smtp_server;
    delete $mail{Smtp} if $mail{Smtp}; # so we don't send it later as a header
    
    my $port = $mail{Port} || $default_smtp_port;
    delete $mail{Port} if $mail{Port}; # so we don't send it later as a header

    # the normal "my($port) = (getservbyname('smtp', 'tcp'))[2];" produced a 
    # "runtime exception" under Win95, so it had to be hardcoded.

    my $message	= $mail{Message} || $mail{Body} || $mail{Text};
    delete($mail{Message}) || delete($mail{Body}) || delete($mail{Text}); # so we don't send it later as a header
    
    # Extract from e-mail address
    my $fromaddr = $mail{From} || $default_sender;
	unless ($fromaddr =~ /$address_rx/o) {
		$error = "Bad or missing From address: $fromaddr";
		return 0;
	}	# get from email address
    $fromaddr = $1;

    $mail{'X-mailer'} .= " $VERSION" if defined $mail{'X-mailer'};

	# add Date header if needed
    unless ($mail{Date}) {
        $mail{Date} = time_to_date;
        $log .= "Date: $mail{Date}\n";
    }

    # cleanup message, and encode if needed
    $message =~ s/^\./\.\./gom; 	# handle . as first character
    $message =~ s/\r\n/\n/go; 	# normalize line endings, step 1 (next step after MIME encoding)

    $mail{'Mime-version'} = '1.0' unless ($mail{'Mime-version'});
    $mail{'Content-type'} = 'text/plain; charset="iso-8859-1"' unless ($mail{'Content-type'});

    if ($use_MIME) {
        $mail{'Content-transfer-encoding'} = 'quoted-printable';
        $message = encode_qp($message);
    }
    else {
        $mail{'Content-transfer-encoding'} = '8bit' unless ($mail{'Content-transfer-encoding'});
        warn "MIME::QuotedPrint not present!\nSending 8bit characters, hoping it will come across OK.\n";
        $error .= "MIME::QuotedPrint not present!\nSending 8bit characters, hoping it will come across OK.\n";
    }
    
    $message =~ s/\n/\015\012/go; # normalize line endings, step 2.
    
	# cleanup smtp
    $smtp =~ s/^\s+//go; # remove spaces around $mail{Smtp}
    $smtp =~ s/\s+$//go;
    
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
#    my $packed = pack('Sna4x8', AF_INET, $port, $smtpaddr);
#    if (!connect(S, pack('Sna4x8', AF_INET, $port, $smtpaddr))) {
#     	$error .= "connect failed to '$packed' ($!)";
#    why does connect sometimes fail ?? Should I retry a few times?
     	$error .= "connect failed ($!)";
    	return 0;
    }
    
    my($oldfh) = select(S); $| = 1; select($oldfh); # what is this $oldfh for? 
    
    $_ = <S>;
    if (/^[45]/) {
    	close S;
    	$error .= "service unavailable: $_";
		return 0;
	}
    
    print S "helo localhost\015\012";
    $_ = <S>;
    if (/^[45]/) {
    	$error .= "mysterious communication error: $_";
    	close S;
		return 0;
	}
    
    print S "mail from: <$fromaddr>\015\012";
    $_ = <S>;
    if (/^[45]/) {
    	$error .= "mysterious communication error: $_";
    	close S;
    	return 0;
    }
    
    foreach $to (@recipients) {
    	if ($debug) { print STDERR "sending to: <$to>\n"; }
    	print S "rcpt to: <$to>\015\012";
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
    print S "data\015\012";
    $_ = <S>;
    if (/^[45]/) {
    	$error .= "mysterious communication error: $_";
    	close S;
    	return 0;
    }
    
    # print headers
    foreach $header (keys %mail) {
    	print S "$header: ", $mail{$header}, "\015\012";
    };
    
    # send message body and quit
    print S "\015\012",
    		$message,
    		"\015\012.\015\012"
    		;
    
    $_ = <S>;
    if (/^[45]/) {
    	close S;
    	$error .= "transmission of message failed: $_";
    	return 0;
    }
    
    print S "quit\015\012";
    $_ = <S>;
    
    close S;
    return 1;
} # end sub sendmail

1;
	
__END__

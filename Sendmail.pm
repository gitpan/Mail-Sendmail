package Mail::Sendmail;
# Mail::Sendmail by Milivoj Ivkovic <mi@alma.ch> or <ivkovic@csi.com>
# see embedded POD documentation after __END__
# or http://alma.ch/perl/mail.htm

=head1 NAME

Mail::Sendmail v. 0.74 - Simple platform independent mailer

=cut

$VERSION = '0.74';

# *************** CUSTOMIZE the following line(s) *******************
# put your mail server name here (or override it in each message)

$default_smtp_server = 'smtp.site1.csi.com';

# That should be enough, but there is more below, in case you need it

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

$connect_retries = 1; # retry to connect after a failed attempt
$retry_delay = 5; # seconds before retrying

$debug = 0; # Not used yet.

# *******************************************************************

BEGIN {
    use strict;
    use vars qw(
                $VERSION
                @ISA
                @EXPORT
                @EXPORT_OK
                $default_smtp_server
                $default_smtp_port
                $default_sender
                $TZ
                $use_MIME
                $address_rx
                $debug
                $log
                $error
                $retry_delay
                $connect_retries
               );
    
    require Exporter;

    use Socket;
    use Time::Local; # for automatic time zone detection
    
    eval "use MIME::QuotedPrint";
    if ($@) {
        $use_MIME = 0;
    }
    else {$use_MIME = 1};
    
    @ISA        = qw(Exporter);
    @EXPORT     = qw(&sendmail);
    @EXPORT_OK  = qw(
                     time_to_date
                     $default_smtp_server
                     $default_smtp_port
                     $default_sender
                     $TZ
                     $address_rx
                     $debug
                     $log
                     $error
                     $use_MIME
                    );
} # end BEGIN block

# A correct regex for valid e-mail addresses is (almost?) impossible.
# This is an attempt to a reasonable compromise, that should accomodate
# all real-world internet style addresses:
# - No comments, no chars that would need to be quoted.
# - Domain part necessary
# - Some weird chars valid in user part, also accepted in domain part.

# Let me know if you have problems with this.

my $word_rx = '[\x21\x23-\x27\x2A-\x2D\w\x3D\x3F]+';

# regex for e-mail addresses where full=$1, user=$2, domain=$3
$address_rx =
     '\b(('  . $word_rx         # valid chars starting at word boundary
    .'(?:\.' . $word_rx . ')*)' # possibly more words preceded by a dot
    .'\@'                       # @
    .'('     .$word_rx          # same as for user part
    .'(?:\.' .$word_rx  . ')*)' #
    .')\b'                      # end at word boundary
; # v. 0.3

sub time_to_date {
    # convert a time() value to a date-time string according to RFC 822

    my $time = $_[0] || time(); # default to now if no argument

    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my @wdays  = qw(Sun Mon Tue Wed Thu Fri Sat);

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
        = localtime($time);

    if ($TZ eq "") {
        # offset in hours
        my $offset  = sprintf "%.1f", (timegm(localtime) - time) / 3600;
        my $minutes = sprintf "%02d", ( $offset - int($offset) ) * 60;
        $TZ  = sprintf("%+03d", int($offset)) . $minutes;
    }
    return join(" ",
                    ($wdays[$wday] . ','),
                     $mday,
                     $months[$mon],
                     $year+1900,
                     sprintf("%02d", $hour) . ":" . sprintf("%02d", $min),
                     $TZ
               );
} # end sub time_to_date

sub sendmail {
    # original sendmail 1.21 by Christian Mallwitz.
    # Modified and 'modulized' by ivkovic@csi.com
    
    $error = '';
    $log = "Mail::Sendmail v. $VERSION - "    . scalar(localtime()) . "\n";

    my $save_w = $^W;
    local $_;
    local $/;
    $/ = "\015\012";

    my (%mail, $k,
        $smtp, $port,
        $message, $fromaddr, $recip, @recipients,
        $proto, $smtpaddr, $localhost
       );

    sub failure {
        # things to do before returning a sendmail failure
        print STDERR @_ if $^W;
        $error .= join(" ", @_) . "\n";
        close S;
        return 0;
    }
    # redo hash, arranging keys case etc...

    while (@_) {
        $k = ucfirst lc(shift @_);
        if (!$k and $^W) {
            warn "Received false mail hash key: \'$k\'. Did you forget to put it in quotes?\n";
        }
        $k =~ s/\s*:\s*$//o; # kill colon (and possible spaces) at end, we add it later.
        $mail{$k} = shift @_;
    }

    $smtp = $mail{'Smtp'} || $mail{'Server'} || $default_smtp_server;
    # delete non-header keys, so we don't send them later as mail headers
    # This doesn't seem to work with AS port 5.003_07: delete @mail{'Smtp', 'Server'};
    delete $mail{'Smtp'}; delete $mail{'Server'};

    $port = $mail{'Port'} || $default_smtp_port;
    delete $mail{'Port'};

    $^W = 0; # turn off errors: we use undefined values below
    $message = join("", $mail{'Message'}, $mail{'Body'}, $mail{'Text'});
    $^W = $save_w; # restore original -w flag
    # delete @mail{'Message', 'Body', 'Text'};
    delete $mail{'Message'}; delete $mail{'Body'}; delete $mail{'Text'};

    # Extract 'From:' e-mail address
    # this will not work with weird addresses.
    
    $fromaddr = $mail{'From'} || $default_sender;
    unless ($fromaddr =~ /$address_rx/o) {
        return failure("Bad or missing From address: \'$fromaddr\'");
    }
    $fromaddr = $1;

    $mail{'X-mailer'} .= " ($VERSION)" if defined $mail{'X-mailer'};

    # add Date header if needed
    $mail{Date} ||= time_to_date() ;
    $log .= "Date: $mail{Date}\n";

    # cleanup message, and encode if needed
    $message =~ s/^\./\.\./gom;     # handle . as first character
    $message =~ s/\r\n/\n/go;     # normalize line endings, step 1 of 2 (next step after MIME encoding)

    $mail{'Mime-version'} ||= '1.0';
    $mail{'Content-type'} ||= 'text/plain; charset="iso-8859-1"';

    if ($use_MIME) {
        $mail{'Content-transfer-encoding'} = 'quoted-printable';
        $message = encode_qp($message);
    }
    else {
        $mail{'Content-transfer-encoding'} ||= '8bit';
        #+ maybe warn only if there really are 8bit chars?
        warn "MIME::QuotedPrint not present!\nSending 8bit characters, hoping it will come across OK.\n" if $^W;
        $error .= "MIME::QuotedPrint not present!\nSending 8bit characters, hoping it will come across OK.\n";
    }

    $message =~ s/\n/\015\012/go; # normalize line endings, step 2.

    # cleanup smtp
    $smtp =~ s/^\s+//go; # remove spaces around $mail{Smtp}
    $smtp =~ s/\s+$//go;

    # Get recipients
    $^W = 0; # turn off errors: we use undefined values below
    $recip = join(", ", $mail{To}, $mail{Cc}, $mail{Bcc});
    $^W = $save_w; # restore original -w flag
    
    delete $mail{'Bcc'};

    @recipients = ();
    while ($recip =~ /$address_rx/go) {
        push @recipients, $1;
    }
    unless (@recipients) {
        return failure("No recipient!")
    }

    $proto = (getprotobyname('tcp'))[2];

    $smtpaddr =
        ($smtp =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)
        ? pack('C4',$1,$2,$3,$4)
        : (gethostbyname($smtp))[4];

    unless (defined($smtpaddr)) {
        return failure("smtp host \"$smtp\" unknown");
    }

    # Add info to log variable
    $log .=   "Server: $smtp Port: $port\n"
            . "From: $fromaddr\n"
            . "Subject: $mail{Subject}\n"
            . "To: ";
    
    # get local hostname for polite HELO
    my @ghbn = gethostbyname('localhost');
    $localhost = $ghbn[0] || 'localhost';

    # open socket and start mail session
    
    if (!socket(S, AF_INET, SOCK_STREAM, $proto)) {
        return failure("socket failed ($!)")
    }

    # connect sometimes failed with no obvious reason.
    # maybe retries can help?

    while (!connect(S, pack('Sna4x8', AF_INET, $port, $smtpaddr))) {
        if ($connect_retries > 0) {
            $error .= "connect to $smtp failed ($!) retrying in $retry_delay seconds...\n";
            sleep $retry_delay;
            $connect_retries--;
            next;
        }
        return failure("connect to $smtp failed ($!) no (more) retries!")
    }

    my($oldfh) = select(S); $| = 1; select($oldfh);

    chomp($_ = <S>);
    if (/^[45]/ or !$_) {
        return failure("Connection error from $smtp ($_)")
    }

    print S "HELO $localhost\015\012"; # get a real hostname
    chomp($_ = <S>);
    if (/^[45]/ or !$_) {
        return failure("HELO error ($_)")
    }

    print S "mail from: <$fromaddr>\015\012";
    chomp($_ = <S>);
    if (/^[45]/ or !$_) {
        return failure("mail From: error ($_)")
    }

    my $bad_recipient_count;
    foreach $to (@recipients) {
        if ($debug) { print STDERR "sending to: <$to>\n"; }
        print S "rcpt to: <$to>\015\012";
        chomp($_ = <S>);
        if (/^[45]/ or !$_) {
            $log .= "!Failed: $to\n    ";
            $bad_recipient_count++;
            return failure("Error sending to <$to> ($_)\n");
        }
        else {
            $log .= "$to\n    ";
        }
    }

    # start data part
    print S "data\015\012";
    chomp($_ = <S>);
    if (/^[45]/ or !$_) {
           return failure("Cannot send data ($_)");
    }

    # print headers
    foreach $header (keys %mail) {
        print S "$header: ", $mail{$header}, "\015\012";
    };

    #- test cutting line here, to see what happens
    #- print STDERR "CUT NOW!\n";
    #- sleep 4;
    #- print STDERR "trying to continue, expecting an error... \n";
    #-

    # send message body
    print S "\015\012",
            $message,
            "\015\012.\015\012";

    chomp($_ = <S>);
    if (/^[45]/ or !$_) {
           return failure("message transmission failed ($_)");
    }

    # finish
    print S "quit\015\012";
    $_ = <S>;
    close S;

    return 1;
} # end sub sendmail

1;
__END__

=head1 SYNOPSIS

  use Mail::Sendmail;

  %mail = ( To      => 'you@there.com',
            From    => 'me@here.com',
            Message => "This is a minimalistic message"
           );

  if (sendmail %mail) { print "Mail sent OK.\n" }
  else { print "Error sending mail: $Mail::Sendmail::error \n" }

  print "\n\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log;

=head1 DESCRIPTION

Simple platform independent e-mail from your perl script.

After struggling for some time with various command-line mailing
programs which never did exactly what I wanted, I put together this
Perl only solution.

Mail::Sendmail contains mainly &sendmail, which takes a hash with
the message to send and sends it...

=head1 INSTALLATION

Standard:

    perl Makefile.PL
    make
    make test
    make install

or manual:

    Copy Sendmail.pm to Mail/ in your Perl lib directory.
      (eg. c:\Perl\lib\Mail\, c:\Perl\lib\site\Mail\,
       /usr/lib/perl5/site_perl/Mail/, ...
       or whatever it is on your system)

At the top of Sendmail.pm, set your default SMTP server, unless
you specify it with each message, or want to use the default.

See the L<NOTES> section about MIME::QuotedPrint. It is not required
but strongly recommended.

=head1 FEATURES

=over 4
Automatic Mime quoted printable encoding (if MIME::QuotedPrint installed)

Internal Bcc: and Cc: support (even on broken servers)

Allows real names in From: and To: fields

Doesn't send unwanted headers, and allows you to send any header(s) you want

Adds the Date header if you don't supply your own

Automatic Time Zone detection

=back

=head1 LIMITATIONS

Doesn't send attachments, unless you provide the appropriate headers
and boundaries yourself, but that may not be practical, and I haven't
tested it.

The SMTP server has to be set manually in Sendmail.pm or in your script,
unless you can live with the default (Compuserve's smpt.site1.csi.com).

=head1 CONFIGURATION

=over 4

=item default SMTP server

Set this at the top of Sendmail.pm, unless you want to use the
provided default.

You can override the default for a particular message by adding
it to your %message hash with a key of 'Smtp':

C<$message{Smtp} = 'newserver.my-domain.com';>

Overriding it globally in your script with:

C<$Mail::Sendmail::default_smtp_server = 'newserver.my-domain.com';>

also works, but this may change in future versions! Better do it in
Sendmail.pm or in the %message hash.

=item other configuration settings

See individual entries under DETAILS below.

=back

=head1 DETAILS

=over 4

=item sendmail()

sendmail is the only thing exported to your namespace by default

C<sendmail(%mail) || print "Error sending mail: $Mail::Sendmail::error\n";>

It takes a hash containing the full message, with keys for all headers,
Body,and optionally for another non-default SMTP server and/or Port. It
returns 1 on success or 0 on error, and rewrites C<$Mail::Sendmail::error>
and C<$Mail::Sendmail::log>.

Keys are NOT case-sensitive.

The colon after headers is not necessary.

The Body part key can be called "Body", "Message" or "Text".
The smtp server key can be called "Smtp" or "Server".

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

The following are not exported by default, but you can still access
them with their full name, or request their export on the use line
like in: C<use Mail::Sendmail qw($address_rx time_to_date);>

=over 4

=item Mail::Sendmail::time_to_date()

convert time ( as from C<time()> ) to an RFC 822 compliant string for
the Date header. See also $Mail::Sendmail::TZ.

=item $Mail::Sendmail::error

When you don't run with the -w flag, the module sends no errors
to STDERR, but puts anything it has to complain about in here.
You should probably always check if it says something.

=item $Mail::Sendmail::log

A summary that you could write to a log file after each send

=item $Mail::Sendmail::address_rx

A handy regex to recognize e-mail addresses.

  Example:
    $rx = $Mail::Sendmail::address_rx;
    if (/$rx/) {
      $address=$1;
      $user=$2;
      $domain=$3;
    }

The regex is a compromise between RFC 822 spec. and a simple regex.
See the code and comments if interested, and let me know if it doesn't
recognize what you expect.

=item $Mail::Sendmail::default_smtp_server

see Configuration above.

=item $Mail::Sendmail::default_smtp_port

If your server doesn't use the default port 25, change this at the
top of Sendmail.pm, or override it for a particular message by adding
it to your %message hash with a key of 'Port':

C<$message{Port} = 8025;>

Global overriding with C<$Mail::Sendmail::default_smtp_port = 8025;>
is deprecated as above for the server, since future versions may not
use this anymore.

=item $Mail::Sendmail::default_sender

You can set this in Sendmail.pm, so you don't need to define
%message{From} in every message.

=item $Mail::Sendmail::TZ

Your time zone. It is set automatically, from the difference
between time() and gmtime(), unless you have preset it in Sendmail.pm.

Or you can force it from your script, using an RFC 822 compliant format:

C<$Mail::Sendmail::TZ = "+0200"; # Western Europe in summer>

=item $Mail::Sendmail::use_MIME

This is set to 1 if you have MIME::QuotedPrint, to 0 otherwise.
It's available in case you want to force it to zero and do the
encoding yourself. You would want this to do multipart messages
and/or attachments, but you may prefer using some other package if
you have complex needs.

=item $Mail::Sendmail::connect_retries

Number of retries when the connection to the server fails. Default 
is 1 retry (= 2 connection attempts).

=item $Mail::Sendmail::retry_delay

Seconds to wait before retrying to connect to the server. Default is 
a low 5 seconds, so if you output results to a web page, you don't 
time out. Set it much higher for scripts that don't mind waiting.

=item $Mail::Sendmail::VERSION

The package version number (this cannot be exported)

=back

=head1 ANOTHER EXAMPLE

  use Mail::Sendmail;

  print STDERR "Testing Mail::Sendmail version $Mail::Sendmail::VERSION\n";
  print STDERR "smtp server: $Mail::Sendmail::default_smtp_server\n";
  print STDERR "server port: $Mail::Sendmail::default_smtp_port\n";

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
  $mail{'mESSaGE : '} = "The message key looks terrible, but works.";
  # cheat on the date:
  $mail{Date} = Mail::Sendmail::time_to_date( time() - 86400 ),

  if (sendmail %mail) { print "Mail sent OK.\n" }
  else { print "Error sending mail: $Mail::Sendmail::error \n" }

  print STDERR "\n\$Mail::Sendmail::log says:\n", $Mail::Sendmail::log;

=head1 CHANGES

Many changes and bug-fixes since version 0.73. See Changes file.

=head1 AUTHOR

Milivoj Ivkovic mi@alma.ch or ivkovic@csi.com

=head1 NOTES

MIME::QuotedPrint is used by default on every message if available.
It is needed to send accented characters reliably. (It is in the
MIME-Base64 package at http://www.perl.com/CPAN/modules/by-module/MIME/ ).

When using this module in CGI scripts, look out for problems related
to messages sent to STDERR. Some servers don't like it, or log them
somewhere where you don't know, or compile-time errors are sent before
you printed the HTML headers. Either be sure to not run with the -w flag,
or (better) print the HTML headers in a BEGIN{} block, and maybe redirect
STDERR to STDOUT.

This module was first based on a script by Christian Mallwitz.

You can use it freely. (someone complained this is too vague.
So, more precisely: do whatever you want with it, but if it's
bad - like using it for spam or claiming you wrote it alone,
or ...? - terrible things will happen to you!)

I would appreciate a short (or long) e-mail note if you use this
(and even if you don't, especially if you care to say why).
And of course, bug-reports and/or suggestions are welcome.

Last revision: 01.08.98. Latest version should be available at
http://alma.ch/perl/mail.htm , and a few days later on CPAN.

=cut

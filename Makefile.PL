use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'Mail::Sendmail',
    'VERSION_FROM' => 'Sendmail.pm', # finds $VERSION
    'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
#    'PREREQ_PM'  => {
#        'Time::Local'   => 0,
#        'Socket'        => 0,
#        'Sys::Hostname' => 0
#    },
    ($] ge '5.005')
        ? (
            'AUTHOR' => 'Milivoj Ivkovic <mi _at_ alma.ch>',
            'ABSTRACT' => 'Simple platform independent mailer',
#            'BINARY_LOCATION' => "http://alma.ch/perl/ppm/Mail-Sendmail-$VERSION-PPM.tar.gz",
            'PPM_INSTALL_SCRIPT' => 'test.pl',
           )
         : (),


);

print <<EOT
**********************************************************************

NOTE
----

The test (test.pl) is a real test for this module: it sends an e-mail.

You may want to edit test.pl before running it (directly or through
make test), so the mail is sent to you. If you also leave my address,
the mail goes into a database from which I can get statistics.

Read the docs, and have fun...

**********************************************************************
EOT
;

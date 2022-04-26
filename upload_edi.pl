#! /usr/bin/perl -w

# ./upload_edi.pl aDawsonEDIEDIFACTtest 130.241.35.131 EDI 21
use strict;
use POSIX qw(strftime);
use YAML qw(LoadFile);
use File::Basename;

my $script_dir = dirname(__FILE__);
my $config = LoadFile("$script_dir/upload_edi.conf.yml");

my $idag = strftime("%Y-%m-%d", localtime(time));

my $email = $config->{email};
my $subject = "ERROR! Problem med edi-körning.";
my $ftp = "/usr/bin/ftp";

my $base = $config->{base_dir};

my $filename;
my $pelle; # bra att ha en pelle...
my $vendor;
my $host;
my $port;
my $server_dir;
my $user;
my $pass;
my $tom_fil;
my $fil;

if ( !$ARGV[0] ) {
    print "\nMissing args\n\nUsage:\n\t./upload_edi.pl vendor_name\n\n";
    exit 1;
}

#print "argv $ARGV[0]\n\n";

#
# Old dawson credentials
#
# if ($ARGV[0] eq 'aDawsonEDI' ) {
#     $vendor = 'aDawsonEDI';
#     $host = 'ftp2.dawson.co.uk';
#     $port = 21;
#     $server_dir = '.';
#     $user = 'FTP40686';
#     $pass = 'FRAME';
# }
#
$vendor = $ARGV[0];

if ( exists $config->{vendors}->{$vendor} ) {
    $host = $config->{vendors}->{$vendor}->{host};
    $port = $config->{vendors}->{$vendor}->{port};
    $server_dir = $config->{vendors}->{$vendor}->{server_dir};
    $user = $config->{vendors}->{$vendor}->{user};
    $pass = $config->{vendors}->{$vendor}->{pass};
}
else {
    my $msg = "Felaktig parameter/vendor, programmet avbryts\n $idag\n";
#    &send_mail ($email, $msg, $subject);
    print "$msg\n";
    exit 1;
}
print "Startar $vendor\n";

my $orig_dir = "${base}/${vendor}";
my $up_dir = "${base}/${vendor}/messages";
my $down_dir = "${base}/${vendor}" . "_down";
my $archive_dir = "${base}/${vendor}/archive/${idag}";
my $error_dir = "${base}/${vendor}/error/";

my @cklista = ();
#$pelle = `mv $orig_dir/*.CEP $up_dir/`;
open (CHECKEMPTY, "ls $up_dir/ | grep '\.CEP\$' |") || die("$!");
@cklista = <CHECKEMPTY>;
close(CHECKEMPTY);

if(!@cklista) {
    print "Inga EDI-filer idag (${vendor})\n";
    exit 0;
}

open (LS, "ls $up_dir/*.CEP |") or die "FEL";

my @lista = <LS>;
my $antal = @lista;
my $i = 0;

close LS;

foreach $fil (@lista) {
    # viktigt med chomp, annars fel i -z
    chomp $fil;
#    if (-z $fil) {
#	$tom_fil = 1;
#	$pelle = `mv $fil $error_dir`;
#    }
}
#if ($tom_fil) {
#    # skicka felmail
#    my $msg = "Tomma EDI-filer till $vendor. Dessa filer ligger nu i katalog $error_dir i edi-katalogen pa sunda.\nDe filerna har inte tagits med i dagens korning."; 
#    &send_mail ($email, $msg, $subject);
#
#    # Ny lista
#    open (LS, "ls $up_dir/*CEP |") or die "FEL";
#    my @lista = <LS>;
#    my $antal = @lista;
#}

while ($i < $antal) {
    $lista[$i] =~ /^.*\/(.*)$/;
    $lista[$i] = $+;
    $i++;
}

# Ta bort linefeeds, Delbanco goer det sjaelva.
# if ($vendor eq 'axDelbancoEDI') {
#    foreach $filename (@lista) {
#	system ./remove_linefeed.pl $filename;
#    }
# }

print "Running script upload_edi.pl $idag\n";
print "Uploading...\n";

#print "$ftp -i -n $host $port\n";
#print "user $user $pass\n";
#print "lcd $up_dir\n";
#print "cd $server_dir\n";
#print "binary\n";

#foreach $filename (@lista) {
#    print "put $filename\n";
#}
#print "dir\n";
#print "quit\n";

open FTP, "|$ftp -i -n $host $port";
print FTP "user $user $pass\n";
print FTP "lcd $up_dir\n";
print FTP "cd $server_dir\n";
print FTP "binary\n";

foreach $filename (@lista) {
    print FTP "put $filename\n";
}
print FTP "dir\n";
print FTP "quit\n";
close(FTP);

### SB: START - Plockat bort del som kollar om filen laddats upp.
#sleep 2;

#print "Reconnecting...\n";
#open(FTP, "| $ftp -i -n $host $port");
#print "Downloading...\n";
#print FTP "user $user $pass\n";
#print FTP "lcd $down_dir\n";
#print FTP "cd $server_dir\n";
#print FTP "binary\n";
#foreach $filename (@lista) {
#    print FTP "get $filename\n";
#}
#print FTP "quit\n";
#close(FTP);

#print "Comparing...\n";
#my $diff = `/usr/bin/diff -r $up_dir $down_dir`;
#if ($diff) {
#    print "FEL $idag\nSkillnad:\n$diff\n\n";
#    my $medd2 = "Det skiljer mellan de filer som har försökt laddas upp till leverantören ($vendor) och de filer som sedan har laddats ner.\nKontrollera manuellt överföringen av edi-filerna (till server $host $port).\nFilerna som skulle skickas upp idag ska ligga arkiverade i edi-katalogen i katalog $archive_dir.\n\nDiffen:\n" . $diff;
#    &send_mail ($email, $medd2, $subject);
#}
#print "Diff $diff\n";
### SB: END - Plockat bort...

print "Archiving...\n";
$pelle = `mkdir -p $archive_dir`;
$pelle = `mv $up_dir/*.CEP $archive_dir/`;
$pelle = `ls $archive_dir | wc -l`;
$pelle =~ tr/0-9//cd;
chomp $pelle;
print "Cleaning up...\n";
print "Uploaded $pelle files $idag\n";
#my $subj =  "$vendor Uploaded $pelle files $idag";
#&send_mail($email, $subj, $subj);
#$pelle = `rm $down_dir/*.CEP`;
print "Finished ok $idag\n\n\n";
exit;

#=============================================================================#

sub send_mail {

    my $email = $_[0];
    my $medd = $_[1];
    my $subject = $_[2];

    open MAIL, "|/usr/lib/sendmail -f gubmail\@ub.gu.se $email";
    print MAIL <<_EOM_;
To: $email
From: Gundautskick <gubmail\@ub.gu.se>
Subject: $subject

$medd

_EOM_
    close MAIL;

}

#=============================================================================#

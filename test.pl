use Test::More tests => 4;
use lib "..";
BEGIN {
	use_ok( 'GD' );
	use_ok( 'Image::Thumbnail' );
	use_ok( 'Image::ThousandWords' );
}

my $IMG = $ARGV[0] || 'test.jpg';

my $text = Image::ThousandWords::html(
	image_path => $IMG,
	font_size  => 12,
);

ok (defined $text, "Got HTML");

if ($^O =~ /win/i){
	open OUT, ">out.html";
	print OUT "<html>
	<head><title>$IMG</title></head>
	<body>$text</body>
	</html>\n";
	close OUT;
	warn "Done\n";

	`start out.html`;
	sleep 4;
	unlink 'out.html';
}

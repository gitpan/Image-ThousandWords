use Test::More tests => 10;
use strict;
use warnings;

use lib "..";
BEGIN {
	use_ok( 'GD' );
	use_ok( 'Image::Thumbnail' );
	use_ok( 'Image::ThousandWords'=> 0.07 );
}

my $IMG = $ARGV[0] || 'test.jpg';
my $html ;

# goto CURRENT;

$html = Image::ThousandWords::html(
	image_path 	=> 'rose.jpg',
	text	   	=> 'PETALS',
	auto_size	=> 1,
	size		=> 800,
	font_size	=> 12,
);
ok (defined $html, "Turn the image into coloured HTML rows of the letter X");
&show($html);

# Turn the image into coloured HTML rows of the letter X:
$html = Image::ThousandWords::html(
	image_path => $IMG,
	text	   => 'X',
);
ok (defined $html, "Turn the image into coloured HTML rows of the letter X");
&show($html);


{
	my $html;
	eval '$html = Image::ThousandWords::html(
		image_path => "leaf300x225.jpg",
		font_size  => 32,
		size	=> 20,
	);';
	ok (length($html) ==0, 'Got a bad result, good');
}

$html = Image::ThousandWords::html(
	image_path => 'leaf300x225.jpg',
	font_size  => 32,
	size	=> 500,
	text 	=> 'What will it look like if I use a long string of text in a tiny image?',
	font_face	=> "'Lucida Console'",
);
ok (defined $html, "Turn the image into coloured HTML rows of longer text");
&show($html);

# A small image and a big font makes nice headlines, esp with simple graphic images:
$html = Image::ThousandWords::html(
	image_path => '300x225.jpg',
	font_size  => 32,
	text 	=> 'What will it look like if I use a long string of text in a tiny image?',
	font_face	=> "'Lucida Console'",
);
ok (defined $html, "Got HTML");
&show($html);

{
	my $html;
	my $o = Image::ThousandWords->new(image_path=>'NOPATH');
	isa_ok($o, "Image::ThousandWords" );
	ok( $o->{image_path} eq 'NOPATH', "Obtained arguments");
	$o->html(image_path=>'./300x225.jpg');
	ok( $o->{image_path} eq './300x225.jpg', "Obtained arguments");
	ok( defined $o->{result}, "Got HTML");
	ok( $html = $o->wrap_html, "Got HTML Page");
	ok ($o->{title} eq '300x225', 'Got Title');
	show_page($html);
}


# As before, but you can specify the output size:
$html = Image::ThousandWords::html(
	image_path => '300x225.jpg',
	font_size  => 32,
	auto_size => 1,
	size	=> 100,
	text 	=> 'What will it look like if I use a long string of text in a tiny image?',
	font_face	=> "'Lucida Console'",
);
ok (defined $html, "Got HTML");
&show($html);

# As before, but keep whitespace
$html = Image::ThousandWords::html(
	image_path => '300x225.jpg',
	whitespace	=> '.',
	font_size  => 12,
	size	=> 500,
	text 	=> 'What will it look like if I use a long string of text in a tiny image?',
	font_face	=> "'Lucida Console'",
);
ok (defined $html, "Got HTML");
&show($html);

{
	local *IN;
	open IN,'shakespeare.txt';
	read IN, $_, -s IN;
	close IN;
	my $o = Image::ThousandWords->new(
		text 	=> $_,
		image_path => 'shakespeare.jpg',
		whitespace	=> ' ',
		line_ends	=> '<span style=\'letter-spacing:0px\'>[]</span>',
		font_size  => 20,
		auto_size => 1,
		size	=> 400,
		font_face	=> "'Courier New'",
	);
	isa_ok($o, "Image::ThousandWords" );
	$html = $o->html;
	ok (defined $html, "Got HTML");
	ok( $html = $o->wrap_html(background=>'black'), "Got HTML Page");
	&show_page($html);
}


# Small Shakespeare!
{
	local *IN;
	open IN,'shakespeare.txt';
	read IN, $_, -s IN;
	close IN;
	$html = Image::ThousandWords::html(
		text 	=> $_,
		image_path => 'shakespeare.jpg',
		whitespace	=> ' ',
		line_ends	=> '<font color=red>&para;</font>',
		font_size  => 20,
		auto_size => 1,
		size	=> 400,
		font_face	=> "'Courier New'",
	);
	ok (defined $html, "Got HTML");
	&show($html);
	ok ($html =~ /\Q&para;/sg, "Literal &para; in line-ends");
}

# Shakespeare!
{
	local *IN;
	open IN,'shakespeare.txt';
	read IN, $_, -s IN;
	close IN;
	$html = Image::ThousandWords::html(
		text 	=> $_,
		image_path => 'shakespeare.jpg',
		whitespace	=> ' ',
		line_ends	=> '·',
		font_size  => 10,
		auto_size => 1,
		size	=> 600,
		font_face	=> "'Courier New'",
	);
	ok (defined $html, "Got HTML");
}
&show($html);



# Display in windows
sub show { my $html = shift;
	return unless defined $html;
	if ($^O =~ /win/i){
		warn "# Displaying in default HTML viewer...\n";
		open OUT, ">out.html";
		print OUT "<html>
		<head><title>Image::ThousandWords</title></head>
		<body style='letter-spacing:1px;' bgcolor=black>$html</body>
		</html>\n";
		close OUT;
		warn "# Done\n";

		`start out.html`;
		warn "# Pausing ...\n";
		sleep 4; # wait for windows....
#		unlink 'out.html';
		warn "# OK\n";
	}
}

sub show_page { my $html = shift;
	return unless defined $html;
	if ($^O =~ /win/i){
		warn "# Displaying in default HTML viewer...\n";
		open OUT, ">out.html";
		print OUT $html;
		close OUT;
		warn "# Done\n";

		`start out.html`;
		warn "# Pausing ...\n";
		sleep 4; # wait for windows....
#		unlink 'out.html';
		warn "# OK\n";
	}
}

package Image::ThousandWords;

$Image::ThousandWords::NAME	= 'Image::ThousandWords';
$Image::ThousandWords::VERSION	= '0.06';

=head1 NAME

Image::ThousandWords - convert an image to colored HTML text

=head1 SYNOPSIS

	use Image::ThousandWords;
	my $html = Image::ThousandWords::html(
		image_path	=> 'image.jpg',
		text		=> 'TurnMeIntoAnImage',
	};
	print "<html><body bgcolor='white'>$html</body></html>\n\n";
	exit;

=head1 DESCRIPTION

This module is designed to take as input the path to an image file,
and a string of text, and return an HTML colored text, resembling the image made out
of the string, repeated as necessary.

Henning Møller-Nielsen wrote the original, Lee Goddard modified it slightly.

Henning said,

	The inspiration I got from http://www4.telge.kth.se/~d99_kme/
	look at http://rto.dk/images/camel.html or http://rto.dk/images/llama.html for the first versions
	(and I look like this: http://rto.dk/images/henning.htm)

Lee adds:

	Modified by Lee Goddard (lgoddard-at-cpan.org) 2003, and again 15 February 2004
	- I did send Henning the mod, but he didn't publish it; I lost it, rewrote it
	and didn't want to re-write it again

=head1 DEPENDENCIES

	Carp
	GD
	Image::Thumbnail
	HTML::Entities

=cut

use strict;
use warnings;
use Carp;
use GD;
use Image::Thumbnail;
use HTML::Entities;

=head1 FUNCTION html

Returns a HTML formatted string, colored to resemble IMAGE. The string consists
of the letters and characters from STRING.

Accepts parameters as a hash, list or hash-reference:

=over 4

=item image_path

Path to the file to convert. Must be openable by your version of GD.
If you don't supply this, you must supply C<thumb> as a GD image.

=item thumb

If you do not supply C<image_path> (above), you must supply this
as a loaded GD image.

=item text

Text to use in conversion of the C<file>. Default is C<aPictureIsWorthAThousandWords>,
so you'd better supply your own. Note that whitesapce will be stripped.

=item font_face

String to use in the HTML, which will be quoted in "double-quotes".
Defaults to C<'Arial Black','Lucida Console','Courier New', Courier'>.

=item font_size

Number of pixels for the size of the font used: default is C<8>.

=item line_height

Number of pixels for the height of a line of text. Default value
is two pixels less than the C<font_size>.

=item scanline_skip

The number of scan-lines or rows to skip jump in each read of
the image. The default is to read every line, which is a C<scanline_skip>
of C<1> - not a very clear name, sorry.  Check the relation of this to
the C<line_height> parameter, above.

=back

=cut

sub html { my $args = (ref $_[0]? shift : {@_});
	confess "No image path" unless defined $args->{image_path} or defined $args->{thumb};
	$args->{font_size} = 8 unless defined $args->{font_size};
	$args->{font_face} = "'Arial Black','Lucida Console','Courier New', Courier'" unless defined $args->{font_face};
	$args->{line_height} = $args->{font_size} - 2 	unless defined $args->{line_height};

	$args->{scanline_skip} = 1 unless defined $args->{scanline_skip};

	$args->{text} = 'aPictureIsWorthAThousandWords' 	unless defined $args->{text};
	$args->{text} =~ s/\s+//smg;

	my @text = split //, $args->{text};

	# Re-size the image if necessary (ie unless orig interface used)
	my $t;
	unless ($args->{thumb}){
		$t = new Image::Thumbnail(
				module     => 'GD',
				size       => 100,
				create     => 1,
				inputpath  => $args->{image_path},
		);
		$args->{thumb} = $t->{thumb};
		undef $t;
	}
	confess "Could not re-size the image" unless defined $args->{thumb};
	my ($x, $y) = $args->{thumb}->getBounds();
	my ($R, $G, $B) = (-1);
	@text = (@text, @text) while ($x*$y > scalar(@text));
	my $result = qq¤<center><nobr><font size="1" style="font-size:$args->{font_size}px;line-height:$args->{line_height}px;" face="$args->{font_face}"><font color="white">¤;

	my $j;
	for ($j = 0; $j < $y; $j += $args->{scanline_skip}) {
		my $i;
		for ($i = 0; $i < $x; $i++) {
			my $index = $args->{thumb}->getPixel($i, $j);
			my ($r,$g,$b) = $args->{thumb}->rgb($index);
			unless (($r == $R) and ($g == $G) and ($b == $B)) {
				($R, $G, $B) = ($r, $g, $b);
				my $color = '#' . sprintf("%.2X%.2X%.2X", $r, $g, $b);
				$result .= qq¤</font><font color="$color">¤;
			}
			my $char = shift @text;
			#$char =~ s¤<¤&lt;¤g;
			#$char =~ s¤>¤&gt;¤g;
			$char = HTML::Entities::encode($char);
			$result .= $char;
		}
		$result .= "\n<br/>";
	}

	$result .= qq¤</font></nobr></center>\n¤;

	return $result;
}

=head1 BACKWARDS COMPARABILITY

The original C<ThousandWords> module's C<giveme> method is still acceptable.

=cut

sub giveme ($$) {
	return html(
		thumb => $_[0],
		text  => $_[1],
	);
}

1;

=head1 EXAMPLES FROM HENNING:

Made with the v. 0.01 (just a script, inspired by http://www4.telge.kth.se/~d99_kme/)

	http://rto.dk/images/camel.html
	http://rto.dk/images/llama.html
	http://rto.dk/images/henning.html (me)

Made with the v. 0.03

	http://rto.dk/images/neptune.html
	http://rto.dk/images/mars.html
	http://rto.dk/images/pluto_charon.html
	http://rto.dk/images/earth.html
	http://rto.dk/images/saturn.html
	http://rto.dk/images/jupiter.html (here the reason for v. 0.04 is apparent)
	http://rto.dk/images/ira1.html
	http://rto.dk/images/ira2.html (my colleagues)

=head1 KNOWN BUGS

None, from a perl perspective. From an image perspective things look different :-)

=head1 AUTHOR ETC.

Henning Michael Møller-Nielsen, hmn -at- datagraf.dk

Slightly modified by Lee Goddard, lgoddard -at- cpan.org

=head1 VERSION HISTORY

A bit of an overkill, but hey - this is Fun!

0.01	Not really a module, just a script
0.02	'ThousandWords.pm' came to life
0.03	Fixed an error so the first text in a black image wouldn't be white
0.04	Fixed an error so the first text in a black image wouldn't be larger
		than the rest and so spaces no longer would be used
0.05	Ah - added POD
0.06	Re-sizing of image and new access means added by Lee

Future:

	ANSI colored text?
	Resizing of image? - done by lee (twice)

=head1 SEE ALSO

L<ThousandWords>

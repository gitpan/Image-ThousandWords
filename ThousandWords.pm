package Image::ThousandWords;

our $NAME	= 'Image::ThousandWords';
our $VERSION	= '0.10';
our $CHAT = undef;

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

Or:

	use Image::ThousandWords;
	my $o = Image::ThousandWords->new(
		text 	=> $text,
		image_path => 'shakespeare.jpg',
		whitespace	=> ' ',
		line_ends	=> '<font color=red>&bull;</font>',
		font_size  => 20,
		auto_size => 1,
		size	=> 400,
		font_face	=> "'Courier New'",
	);
	$html = $o->html;
	print "Content-type:text/html\n\n", $o->wrap_html(background=>'black');

B<See the file F<test.pl>> for examples of use>.

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
	and didn't want to re-write it again. Module now has more parameters, and more
	control over the HTML, using a combination of CSS and image resizing (the latter
	being one of Henning's original requests).

B<See the file F<test.pl>> for examples of use>.

=head1 DEPENDENCIES

	Carp
	GD
	Image::Thumbnail
	HTML::Entities
	Image::Size

=cut

use strict;
use warnings;
use Carp "cluck";
use GD;
use Image::Thumbnail;
use HTML::Entities;
use Image::Size;

# Returns an object blessed into this class
sub new { my $class = shift;
	die unless defined $class and not ref $class;
	my $self = bless {}, $class;
	$self->_populate(@_);
	return $self;
}

sub _populate { my $self = shift;
	my $args = (ref $_[0]? shift : {@_});
	$self->{$_} = $args->{$_} foreach keys %$args;
}

=head1 CONSTRUCTOR html

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

=item size

The length in pixels of the largest size of the image when
re-sized prior to conversion to text. Default is C<100>.

=item auto_size

If set, experimentally tries to re-size the output to be
the same size, in pixels, as the input. If supplied, don't
bother with C<font_size> or C<line_height> (below), but maybe
use C<size> (above).

So, if you supply C<size> as well as C<auto_size>, you are
requesting the output to the be C<size> in pixels, the number
of characters in each row being determind by C<font_size>

If you supply C<size> without C<auto_size>, then C<size>
specifies the number of characters per row.

=item text

Text to use in conversion of the C<file>. Default is C<aPictureIsWorthAThousandWords>,
so you'd better supply your own. Note that whitesapce will be stripped.

=item whitespace

If you don't supply this at all, all whitespace will be removed.
If you do supply this, all whitespace will be substituted for whatever
this C<whitespace> value is. Intention is that you'll supply a single
space to maintain whitespace - or some character to maintain spacing
and colouring. See also C<line_ends> below.

=item line_ends

Replace line terminators C<[\n\r\f]> with this string: may be multiple
characters. By default this paramter is set to whatever C<whitespace>
is set to - setting this parameter over-rides the effets of the former
parameter on line terminators.

=item font_face

String to use in the HTML, which will be quoted in "double-quotes".
Defaults to C<'Arial Black','Lucida Console','Courier New', Courier'>.

=item font_size

Number of pixels for the size of the font used: default is C<8>.

=item line_height

Number of pixels for the height of a line of text. Default value
is two pixels less than the C<font_size>.

=item scanline_skip

You shuldn't need this, but...
The number of scan-lines or rows to skip jump in each read of
the image. The default is to read every line, which is a C<scanline_skip>
of C<1> - not a very clear name, sorry.  Check the relation of this to
the C<line_height> parameter, above.

=back

B<See the file F<test.pl>> for examples of use>.

=cut

sub html {
	local $_;
	my $self = (ref $_[0] eq __PACKAGE__? shift : __PACKAGE__->new);
	$self->_populate(@_);
	unless (defined $self->{image_path} or defined $self->{thumb}){
		cluck "No image path" ;
		return undef;
	}
	$self->{result} = "";
	warn "# Image path: ".$self->{image_path} if defined $self->{image_path} and defined $CHAT;
	$self->{font_size} = 8 unless defined $self->{font_size};
	warn "# Font size: ".$self->{font_size} if defined $self->{font_size} and defined $CHAT;
	$self->{font_face} = "'Arial Black','Lucida Console','Courier New', Courier'" unless defined $self->{font_face};
	warn "# Font face: ".$self->{font_face} if defined $self->{font_face} and defined $CHAT;
	$self->{line_height} = $self->{font_size} - int ($self->{font_size}/3) 	unless defined $self->{line_height};
	warn "# Line height: ".$self->{line_height} if defined $self->{line_height} and defined $CHAT;
	$self->{scanline_skip} = 1 unless defined $self->{scanline_skip};
	warn "# Scanline: ".$self->{scanline_skip} if defined $self->{scanline_skip} and defined $CHAT;
	$self->{text} = 'aPictureIsWorthAThousandWords' unless defined $self->{text};

	$self->{whitespace} = "" unless defined $self->{whitespace};
	my $whitespace;
	if ($self->{line_ends}){
		$whitespace = '[ |\t]';
		$self->{text} =~ s/([\n\r\f])+/$1/sg;	# collapse line endings
	} else {
		$self->{line_ends} = $self->{whitespace};
		$whitespace = '\s'
	}
	$self->{text} =~ s/${whitespace}+/$self->{whitespace}/smg if defined $self->{whitespace};
	my @text = split //, $self->{text};

	# Set size....
	if (defined $self->{image_path} and $self->{auto_size}){
		my ($x, $y) = imgsize( $self->{image_path}  );
		unless ($x and $y){
			cluck "No x or y?";
			return undef;
		}

		# Get the size of original
		if (defined $self->{size}){
			my $r = $x>$y ? $x / $self->{size} : $y / $self->{size};
			$x /= $r;
			$y /= $r;
		}
		warn "# Size is $x,$y" if $CHAT;

		# Set 'size' to longest side of original, over the font_size
		# - what is wrong with this?!
		$x /= $self->{font_size};
		$y /= $self->{line_height};
		$x = int($x)+1 if int($x) != $x;
		$y = int($y)+1 if int($y) != $y;
		$self->{size} = $x > $y? $x : $y;
		warn "# New size from $x,$y is $self->{size}, so lines are $x characters of $self->{font_size}px" if $CHAT;
	}
	elsif (not defined $self->{size}){
		$self->{size}	= 100;
		warn "# Set size (B) to: ".$self->{size} if defined $CHAT;
	} elsif ($self->{size} <= $self->{font_size}){
		cluck "Please make sure size ($self->{size}) > font_size ($self->{font_size})";
		return undef;
	} else {
		warn "# Size (C) is ".$self->{size} if defined $CHAT;
	}

	# Re-size the image if necessary (ie unless orig interface used)
	# This is quicker than us trying to work out an average colour for
	# a block of pixels
	my $t;
	unless ($self->{thumb}){
		$t = new Image::Thumbnail(
				module     => 'GD',
				create     => 1,
				size       => $self->{size},
				inputpath  => $self->{image_path},
		);
		$self->{thumb} = $t->{thumb};
		undef $t;
	}

	unless (defined $self->{thumb}){
		cluck "Could not re-size the image";
		return undef;
	}

	my ($x, $y) = $self->{thumb}->getBounds();
	my ($R, $G, $B) = (-1);
	@text = (@text, @text) while ($x*$y > scalar(@text));

	# Finally do the job
	my $j;
	for ($j = 0; $j < $y; $j += $self->{scanline_skip}) {
		my $i;
		for ($i = 0; $i < $x; $i++) {
			my $index = $self->{thumb}->getPixel($i, $j);
			my ($r,$g,$b) = $self->{thumb}->rgb($index);
			unless (($r == $R) and ($g == $G) and ($b == $B)) {
				($R, $G, $B) = ($r, $g, $b);
				my $color = '#' . sprintf("%.2X%.2X%.2X", $r, $g, $b);
				$self->{result} .= qq¤</font><font color="$color">¤;
			}
			my $char;
			# Do not begin or end a line with whitespace
			do {
				$char = shift @text
			} while (($i==0 or $i==$x-1) and $char eq $self->{whitespace});

			if ($self->{line_ends}){
				if (not $char =~ s/[\n\r\f]/$self->{line_ends}/){
					$char = HTML::Entities::encode($char);
				}
			} else {
				$char = HTML::Entities::encode($char);
			}

			$self->{result} .= $char;
		}
		$self->{result} .= "\n<br/>";
	}

	if ($self->{result}){
		$self->{result} = qq¤<center style='font-align:justify;display:block;'><nobr><font size="1" style="font-size:$self->{font_size}px;line-height:$self->{line_height}px;" face="$self->{font_face}"><font color="white">¤
			. $self->{result}
			. qq¤</font></nobr></center>\n¤;
		return $self->{result};
	} else {
		return undef;
	}
}

=head2 METHOD wrap_html

Convenience method to return the C<result> field wrapped in
HTML to make a complete page. Accepts values valid for CSS
in the parameter C<background>, and text in the C<title> (which
is otherwise inherited from the calling object) or the C<image_path>.

Sets the C<title> field and returns an HTML page.

=cut

sub wrap_html { my ($self, $args) = (shift, (ref $_[0]? shift : {@_}));
	$args->{background} = "black" unless defined $args->{background};
	$self->{title} = $args->{title} if defined $args->{title};
	if (not defined $self->{title}){
		$self->{title} = $self->{image_path};
		($self->{title}) = $self->{title} =~ /([^\\\/]+)\.\w{3,4}$/;
		$self->{title} =~ s/_+/ /g;
	}
	return "\n\n<html>
	<head><title>$self->{title}</title></head>
	<body style='background:$args->{background}'>$self->{result}</body>
	</html>\n";
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
0.06	Lee added: re-sizing of image; new access method; proper HTML entities
0.07	Sod it - full OO interface, more re-sizing, line-feeds/whitespace
0.08	Fixed MANIFEST for test.pl

Future:

	ANSI colored text?

	Work on the 'size' field

=head1 SEE ALSO

L<ThousandWords>,
L<Image::Thumbnail>,
L<GD>.

B<See the file F<test.pl>> for examples of use>.

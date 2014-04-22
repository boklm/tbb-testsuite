package TBBTestSuite::Thumbnail;

use strict;
use Image::Magick;

sub screenshot_thumbnail {
    my ($dir, $name) = @_;
    my $image = Image::Magick->new;
    $image->Read("$dir/$name");
    $image->Scale(geometry => '600x600');
    $image->Write("$dir/t-$name");
}

1;

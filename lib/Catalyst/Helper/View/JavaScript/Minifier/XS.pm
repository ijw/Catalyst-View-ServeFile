package Catalyst::Helper::View::JavaScript::Minifier::XS;

use strict;

=head1 NAME

Catalyst::Helper::View::JavaScript::Minifier::XS - Helper for JavaScript::Minifier::XS views

=head1 SYNOPSIS

    script/create.pl view JavaScript JavaScript::Minifier::XS

=head1 DESCRIPTION

Helper for JavaScript::Minifier::XS views

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>

=head1 AUTHOR

See L<Catalyst::View::JavaScript::Minifier::XS>

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;

use parent 'Catalyst::View::JavaScript::Minifier::XS';

1;

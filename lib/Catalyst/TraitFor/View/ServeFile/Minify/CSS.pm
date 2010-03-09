package Catalyst::TraitFor::View::ServeFile::Minify::CSS;

# ABSTRACT: Minify your served CSS files

use autodie;
use Moose::Role;
requires 'Catalyst::View::ServeFile';

use CSS::Minifier::XS qw/minify/;

has '+stash_variable' => (
   default => 'css',
);

has '+path' => (
   default => 'css',
);

has '+default_content_type' => (
   default => 'text/css',
);

around filter => sub {
   my ( $self, $c, $output ) = @_;

   if ( defined($output) ) {
      return $c->debug
         ? $output
         : minify($output);
   } else {
      return q{ };
   }
}

1;

=pod

=head1 SYNOPSIS

 View::CSSMini => { # (a StashFile view)
   traits => qw/Minifier::CSS/
 }

 # in your controller file, as an action
 sub css : Local {
    my ( $self, $c ) = @_;

    # loads root/css/main.css and root/css/page.css
    $c->stash->{js} = ['main.css', 'page.css'];

    $c->forward('View::CSSMini');
 }

 # in your html
 <script type="text/javascript" src="/js"></script>

=head1 DESCRIPTION

Use your minified CSS files as a separated catalyst request. By default they
are read from C<< $c->stash->{css} >> as array or string.  Also note that this
does not minify the CSS if the server is started in development mode.

=head1 CONFIG VARIABLES

=over 2

=item stash_variable

sets a different stash variable from the default C<< $c->stash->{css} >>

=item path

sets a different path for your CSS files

default : css

=item default_content_type

sets a different content type for your CSS files

default : text/css

=back

=cut

=head1 SEE ALSO

L<Catalyst::View::ServeFile>
L<CSS::Minifier::XS>


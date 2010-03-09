package Catalyst::View::JavaScript::Minifier::XS;

# ABSTRACT: Minify your served JavaScript files

use autodie;
use Moose::Role;
requires 'Catalyst::View::ServeFile';

use JavaScript::Minifier::XS qw/minify/;

has '+stash_variable' => (
   default => 'js',
);

has '+path' => (
   default => 'js',
);

has '+default_content_type' => (
   default => 'text/javascript',
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

 View::JSMini => { # (a StashFile view)
   traits => qw/Minifier::JS/
 }

 # in your controller file, as an action
 sub js : Local {
    my ( $self, $c ) = @_;

    # loads root/js/script1.js and root/js/script2.js
    $c->stash->{js} = [qw/script1 script2/];

    $c->forward('View::JSMini');
 }

 # in your html
 <script type="text/javascript" src="/js"></script>

=head1 DESCRIPTION

Use your minified js files as a separated catalyst request. By default they
are read from C<< $c->stash->{js} >> as array or string.  Also note that this
does not minify the javascript if the server is started in development mode.

=head1 CONFIG VARIABLES

=over 2

=item stash_variable

sets a different stash variable from the default C<< $c->stash->{js} >>

=item path

sets a different path for your javascript files

default : js

=back

=cut

=head1 SEE ALSO

L<Catalyst::View::ServeFile>
L<JavaScript::Minifier::XS>


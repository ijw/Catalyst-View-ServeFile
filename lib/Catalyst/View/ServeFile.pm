package Catalyst::View::JavaScript::Minifier::XS;

# ABSTRACT: Minify your served JavaScript files

use autodie;
use Moose;
extends 'Catalyst::View';

use JavaScript::Minifier::XS qw/minify/;
use Path::Class::File;
use URI;

has stash_variable => (
   is => 'ro',
   isa => 'Str',
   default => 'file',
);

has path => (
   is => 'ro',
   isa => 'Str',
   default => 'static',
);

has default_content_type => (
   is => 'ro'
   isa => 'Str',
   default => 'text/html',
);

sub find_content_type {
    my $self = shift;
#    my $file=shift;
    return $self->default_content_type;
}

sub process {
   my ($self,$c) = @_;

   my $original_stash = $c->stash->{$self->stash_variable};
   my @files = $self->_expand_stash($original_stash);

   $c->res->content_type($self->find_content_type(@files));

   my $home = $self->config->{INCLUDE_PATH} || $c->path_to('root');
   @files = map {
      Path::Class::File->new( $home, $self->path, $_ );
   } grep { defined $_ && $_ ne '' } @files;

   my @output = $self->combine_files($c, \@files);

   $c->res->body( $self->filter($c, \@output) );
}

sub combine_files {
   my ( $self, $c, $files ) = @_;

   my @output;
   for my $file (@{$files}) {
      $c->log->debug("loading js file ... $file");
      open my $in, '<', $file;
      for (<$in>) {
         push @output, $_;
      }
      close $in;
   }
   return @output;
}

# The default filter is a no-op, but you may want to override it.
sub filter {
    my ($self, $c, $content) = @_;

    return $content;
}


sub _expand_stash {
   my ( $self, $stash_var ) = @_;

   if ( $stash_var ) {
      return ref $stash_var eq 'ARRAY'
         ? @{ $stash_var }
	 : split /\s+/, $stash_var;
   }

}

1;

=pod

=head1 SYNOPSIS

 # creating MyApp::View::ServeFile
 ./script/myapp_create.pl view ServeFile ServeFile

 # in your controller file, as an action
 sub js : Local {
    my ( $self, $c ) = @_;

    # loads root/js/script1.js and root/js/script2.js and concatenates them
    $c->stash->{js} = [qw/script1 script2/];

    $c->forward('View::ServeFile');
 }

 # in your html
 <script type="text/javascript" src="/js"></script>

=head1 DESCRIPTION

This is a rather dull view that simply fetches files from the filesystem and serves them.

There are specific reasons why you would want to use this view:

=over 4
=item Minifying JS
=item Minifying CSS
=item Complex rewriting of URLS
=item Serving either a static file or something else depending no what a controller decides
=item Serving files from behind Catalyst's authentication wall
=item Any other sort of multiple-file processing and filtering
=back

This plugin is also superficially tempting for other needs, but other, possibly more
efficient, ways exist to serve static files.  Consider:

=over 4
=item If you're using Apache, you can set up a filter in Apache/mod_perl and avoid the overhead of
Catalyst's dispatch mechanism.
=item If you're using lighttpd or certain proxy arrangements, you can send a X-SendFile header
to instruct the webserver to serve a file, rather than serving it yourself.
=item With pretty much any webserver you should be able to set it to serve files straight off of
disk for a given URL.
=back

What this module gives you is flexibility: you can transform the file before it's output,
you can output more than one file, you can sort out your own caching policies and you can
make complex decisions on what exactly you should be serving.

WARNING: This assumes that the controller calling it has a modicum of intelligence.  Therefore,
ensure that any file you ask to be served has a suitably untainted filename: this view will
serve /etc/passwd without complaint if your controller tells it to.

=head1 CONFIG VARIABLES

=over 2

=item stash_variable

The file, or file list, that will be served.  The default behaviour is to concat
multiple files in the order supplied.

The default is C<< $c->stash->{file} >> .

=item path

Sets a different path for your files; the path is relative
to your Catalyst 'root' directory.

default : static

=item default_content_type

The content type that will be given for served files.

The default is 'text/html'.

=back

You may also wish to set 'traits' (which Catalyst understands) to extend this module.

=cut

=head1 METHODS FOR OVERRIDING

=over 2

=item find_content_type

Supplied $c and a list of files; returns the content-type string to serve.

Default is to serve default_content_type as above.

=item combine_files

Supplied $c and a list of files; returns the content string to serve.

Default is to serve the files concatenated in the supplied order, and to
throw an error if any don't exist.

=item filter

Supplied $c and the combined content.  You get a chance here to modify the content
before handing it to be served; thus, an ideal place for minifiers.

Default is to return the content unchanged.

=head1 SEE ALSO

L<Catalyst::TraitFor::View::ServeFile::Minify::JS>
L<Catalyst::TraitFor::View::ServeFile::Minify::CSS>


=head1 TODO

In the near future I will add code to set cache headers.

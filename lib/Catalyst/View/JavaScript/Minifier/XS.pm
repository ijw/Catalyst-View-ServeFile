package Catalyst::View::JavaScript::Minifier::XS;

# ABSTRACT: Minify your served JavaScript files

use Moose;
extends 'Catalyst::View';

use JavaScript::Minifier::XS qw/minify/;
use Path::Class::File;
use URI;

has stash_variable => (
   is => 'ro',
   isa => 'Str',
   default => 'js',
);

has path => (
   is => 'ro',
   isa => 'Str',
   default => 'js',
);

has subinclude => (
   is => 'ro',
   isa => 'Bool',
   default => undef,
);

sub process {
	my ($self,$c) = @_;

	my $path = $self->path;
	my $variable = $self->stash_variable;
	my @files = ();

	my $original_stash = $c->stash->{$variable};

	# setting the return content type
	$c->res->content_type('text/javascript');

	# turning stash variable into @files
	if ( $c->stash->{$variable} ) {
		@files = ( ref $c->stash->{$variable} eq 'ARRAY' ? @{ $c->stash->{$variable} } : split /\s+/, $c->stash->{$variable} );
	}

	# No referer we won't show anything
	if ( ! $c->request->headers->referer ) {
		$c->log->debug('javascripts called from no referer sending blank');
		$c->res->body( q{ } );
		$c->detach();
	}

	# If we have subinclude ON then we should run the action and see what it left behind
	if ( $self->subinclude ) {
		my $base = $c->request->base;
		if ( $c->request->headers->referer ) {
			my $referer = URI->new($c->request->headers->referer);
			if ( $referer->path ne '/' ) {
				$c->forward('/'.$referer->path);
				$c->log->debug('js taken from referer : '.$referer->path);
				if ( $c->stash->{$variable} ne $original_stash ) {
					# adding other files returned from $c->forward to @files ( if any )
					push @files, ( ref $c->stash->{$variable} eq 'ARRAY' ? @{ $c->stash->{$variable} } : split /\s+/, $c->stash->{$variable} );
				}
			} else {
				# well for now we can't get js files from index, because it's indefinite loop
				$c->log->debug(q{we can't take js from index, it's too dangerous!});
			}
		}
	}

	my $home = $self->config->{INCLUDE_PATH} || $c->path_to('root');
	@files = map {
		$_ =~ s/\.js$//;
		Path::Class::File->new( $home, $path, "$_.js" );
	} @files;

	# combining the files
	my @output = ();
	for my $file ( @files ) {
		$c->log->debug("loading js file ... $file");
		open my $in, '<', "$file";
		for ( <$in> ) {
			push @output, $_;
		}
		close $in;
	}

	if ( @output ) {
		# minifying them if any files loaded at all
		$c->res->body(
                   $c->debug
                      ? join q{ },@output
                      : minify(join q{ }, @output )
                );
	} else {
		$c->res->body( q{ } );
	}
}

1;

=pod

=head1 SYNOPSIS

 # creating MyApp::View::JavaScript
 ./script/myapp_create.pl view JavaScript JavaScript::Minifier::XS

 # in your controller file, as an action
 sub js : Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = [qw/script1 script2/]; # loads root/js/script1.js and root/js/script2.js

    $c->forward('View::JavaScript');
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

=item subinclude

setting this to true will take your js files (stash variable) from your referer action

 # in your controller
 sub action : Local {
    my ( $self, $c ) = @_;

    $c->stash->{js} = "exclusive"; # loads exclusive.js only when /action is loaded
 }

This could be very dangerous since it's using C<< $c->forward($c->request->headers->referer) >>. It doesn't work with the index action!

default : false

=back

=cut

=head1 SEE ALSO

L<JavaScript::Minifier::XS>


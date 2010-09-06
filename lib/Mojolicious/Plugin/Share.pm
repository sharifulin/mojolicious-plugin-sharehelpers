package Mojolicious::Plugin::Share;

use strict;
use warnings;

use Mojo::ByteStream 'b';
use base 'Mojolicious::Plugin';

our $VERSION = '0.01';

__PACKAGE__->attr(url => sub { +{
	twitter   => 'http://twitter.com/share',
	facebook  => 'http://facebook.com/sharer.php',
	buzz      => 'http://www.google.com/buzz/post',
	vkontakte => 'http://vkontakte.ru/share.php',
} });

sub register {
	my ($self, $app, $conf) = @_;
	
	$app->renderer->add_helper( share_url    => sub { $self->share_url   ( @_ ) } );
	$app->renderer->add_helper( share_button => sub { $self->share_button( @_ ) } );
	$app->renderer->add_helper( share_meta   => sub { $self->share_meta  ( @_ ) } );
}

sub share_url {
	my($self, $c) = (shift, shift);
	
	my $type = shift;
	my $args = @_ ? { @_ } : {};
	
	return $self->log->debug('Bad share type') unless $self->_check_type( $type );
	
	my $param;
	if ($type eq 'twitter') {
		$param->{$_} = $args->{$_} for qw(url via text related count lang counturl);
	}
	elsif ($type eq 'facebook') {
		$param->{u} = $args->{url };
		$param->{t} = $args->{text};
	}
	elsif ($type eq 'buzz') {
		$param->{     url} = $args->{url  };
		$param->{imageurl} = $args->{image};
	}
	elsif ($type eq 'vkontakte') {
		$param->{url} = $args->{url};
	}
	
	return join '?', $self->url->{ $type },
		join '&', map { $_ . '=' . b( $param->{$_} )->url_escape } grep { $param->{$_} } sort keys %$param
	;
}

sub share_button {
	my($self, $c) = (shift, shift);
	
	my $type = shift;
	my $args = @_ ? { @_ } : {};
	
	return $self->log->debug('Bad share type') unless $self->_check_type( $type );
	
	my $button;
	if ($type eq 'twitter') {
		if ($args->{iframe}) {
			my $url    = $c->helper(share_url => $type, @_ );
			my($param) = $url =~ /.*\?(.*)/;
			
			$button =
				qq(<iframe allowtransparency="true" frameborder="0" scrolling="no" style="width:130px; height:50px;" ) .
				qq(src="http://platform.twitter.com/widgets/tweet_button.html?$param"></iframe>)
			;
		}
		else {
			my $attr; push @$attr, qq(data-$_="$args->{$_}")
				for grep { $args->{$_} } qw(url via text related count lang counturl);
			my $param = join ' ', @$attr;
			
			$button =
				qq(<a href="http://twitter.com/share" class="twitter-share-button" $param>Tweet</a>) .
				qq(<script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>)
			;
		}
	}
	elsif ($type eq 'facebook') {
		if ($args->{fb}) {
			my $attr  = { type => $args->{type}, href => $args->{url}, class => $args->{class} };
			my $param = join ' ', map { qq($_="$attr->{$_}") } grep { $attr->{$_} } keys %$attr;
			
			$button =
				qq(<fb:share-button $param></fb:share-button>)
			;
		}
		else {
			my $attr  = { type => $args->{type}, share_url => $args->{url} };
			my $param = join ' ', map { qq($_="$attr->{$_}") } grep { $attr->{$_} } keys %$attr;
			
			$button =
				qq(<a name="fb_share" $param>$args->{button_text}</a>) .
				qq(<script src="http://static.ak.fbcdn.net/connect.php/js/FB.Share" type="text/javascript"></script>)
			;
		}
	}
	elsif ($type eq 'buzz') {
		my $attr  = { 'button-style' => $args->{type}, locale => $args->{lang}, url => $args->{url}, imageurl => $args->{image} };
		my $param = join ' ', map { qq(data-$_="$attr->{$_}") } grep { $attr->{$_} } keys %$attr;
		
		$args->{title} ||= 'Share to Google Buzz';
		
		$button =
			qq(<a title="$args->{title}" class="google-buzz-button" href="http://www.google.com/buzz/post" $param></a>) .
			qq(<script type="text/javascript" src="http://www.google.com/buzz/api/button.js"></script>)
		;
	}
	elsif ($type eq 'vkontakte') {
		my $url   = $args->{url} ? qq({url: "$args->{url}"}) : 'false';
		my $attr  = { type => $args->{type}, text => $args->{text} };
		my $param = join ', ', map { qq($_: "$attr->{$_}") } grep { $attr->{$_} } keys %$attr;
		
		$button =
			qq(<script type="text/javascript" src="http://vkontakte.ru/js/api/share.js?9" charset="windows-1251"></script>) .
			qq(<script type="text/javascript">document.write(VK.Share.button($url, {$param}));</script>)
		;
	}
	
	return b( $button );
}

sub share_meta {
	my($self, $c) = (shift, shift);
	
	my $args = @_ ? { @_ } : {};
	
	return b( join "\n",
		@_ ? qq(<meta name="medium" content="mult"/>) : '',
		
		$args->{og} ? (
			$args->{fb_app_id} ? qq(<meta property="fb:app_id" content="$args->{fb_app_id}"/>) : (),
			qq(<meta property="og:site_name" content="$args->{site_name}" />),
			qq(<meta property="og:type" content="website" />),
			map { $args->{$_} ? qq(<meta property="og:$_" content="$args->{$_}"/>) : () }
			qw(image title description)
		) : (),
		
		$args->{title} ? qq(<meta name="title" content="$args->{title}"/>) : (),
		$args->{description} ? qq(<meta name="description" content="$args->{description}"/>) : (),
		$args->{image} ? qq(<link rel="image_src" href="$args->{image}" />) : (),
		$args->{url} ? qq(<link rel="target_url" href="$args->{url}"/>) : (),
	);
}

sub _check_type {
	my $self = shift;
	my $type = shift;
	
	return $type && exists $self->url->{ $type } ? $type : undef;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Share - Mojolicious Plugin for generate share url and button (Twitter, Facebook, Buzz, VKontakte)

=head1 SYNOPSIS

	# Mojolicious
	$self->plugin('share');
	
	# Mojolicious::Lite
	plugin 'share';
	
	# share urls:
	<a href="<%= share_url 'twitter',   url => $url, text => $text, via => 'sharifulin' %>">Share to Twitter</a>
	<a href="<%= share_url 'facebook',  url => $url, text => $text %>">Share to Facebook</a>
	<a href="<%= share_url 'buzz',      url => $url, img  => $img %>">Share to Google Buzz</a>
	<a href="<%= share_url 'vkontakte', url => $url %>">Share to ВКонтакте</a>

=head1 DESCRIPTION

L<Mojolicous::Plugin::Share> is a plugin for generate share url (Twitter, Facebook, VKontakte).

Plugin adds a C<share_url>, C<share_button>, C<share_meta> helpers to L<Mojolicious>.

Twitter Share L<http://dev.twitter.com/pages/tweet_button>

Facebook Share L<http://developers.facebook.com/docs/share>

Google Buzz Share L<http://www.google.com/buzz/api/admin/configPostWidget>

VKontakte Share L<http://vkontakte.ru/pages.php?act=share>

=head2 HELPERS

<%= share_url %>

Generate share url.

<%= share_button %>

Generate share button.

=head1 METHODS

L<Mojolicious::Plugin::Share> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

	$plugin->register;

Register plugin hooks in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Anatoly Sharifulin <sharifulin@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-share at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.htMail?Queue=Mojolicious-plugin-share>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=over 5

=item * Github

L<http://github.com/sharifulin/Mojolicious-plugin-share/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.htMail?Dist=Mojolicious-plugin-share>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-plugin-share>

=item * CPANTS: CPAN Testing Service

L<http://cpants.perl.org/dist/overview/Mojolicious-plugin-share>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-plugin-share>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-plugin-share>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

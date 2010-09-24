package Mojolicious::Plugin::ShareHelpers;

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
	mymailru  => 'http://connect.mail.ru/share',
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
		$param->{hl      } = $args->{lang };
		$param->{url     } = $args->{url  };
		$param->{message } = $args->{text };
		$param->{imageurl} = $args->{image};
	}
	elsif ($type eq 'vkontakte') {
		$param->{url} = $args->{url};
	}
	elsif ($type eq 'mymailru') {
		$param->{share_url} = $args->{url};
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
				qq(<a name="fb_share" $param>$args->{title}</a>) .
				qq(<script src="http://static.ak.fbcdn.net/connect.php/js/FB.Share" type="text/javascript"></script>)
			;
		}
	}
	elsif ($type eq 'buzz') {
		my $attr  = { 'button-style' => $args->{type}, locale => $args->{lang}, url => $args->{url}, message => $args->{text}, imageurl => $args->{image} };
		my $param = join ' ', map { qq(data-$_="$attr->{$_}") } grep { $attr->{$_} } keys %$attr;
		
		$args->{title} ||= 'Share to Google Buzz';
		
		$button =
			qq(<a title="$args->{title}" class="google-buzz-button" href="http://www.google.com/buzz/post" $param></a>) .
			qq(<script type="text/javascript" src="http://www.google.com/buzz/api/button.js"></script>)
		;
	}
	elsif ($type eq 'vkontakte') {
		my $url   = $args->{url} ? qq({url: "$args->{url}"}) : 'false';
		my $attr  = { type => $args->{type}, text => $args->{title} };
		my $param = join ', ', map { qq($_: "$attr->{$_}") } grep { $attr->{$_} } keys %$attr;
		
		$button =
			qq(<script type="text/javascript" src="http://vkontakte.ru/js/api/share.js?9" charset="windows-1251"></script>) .
			qq(<script type="text/javascript">document.write(VK.Share.button($url, {$param}));</script>)
		;
	}
	elsif ($type eq 'mymailru') {
		my $param = $args->{url} ? '?share_url='.$c->helper(share_url => $type, @_ ) : '';
		
		$args->{type } ||= '';
		$args->{title} ||= 'В Мой Мир';
		
		$button =
			qq(<script src="http://cdn.connect.mail.ru/js/share/2/share.js" type="text/javascript"></script>) .
			qq(<a class="mrc__share" type="$args->{type}" href="http://connect.mail.ru/share$param">$args->{title}</a>)
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

Mojolicious::Plugin::ShareHelpers - Mojolicious Plugin for generate share url, button and meta (Twitter, Facebook, Buzz, VKontakte, My.MailRU)

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('share_helpers');

  # Mojolicious::Lite
  plugin 'share_helpers';

  # share urls:
  <a href="<%= share_url 'twitter',   url => $url, text => $text, via => 'sharifulin' %>">Share to Twitter</a>
  <a href="<%= share_url 'facebook',  url => $url, text => $text %>">Share to Facebook</a>
  <a href="<%= share_url 'buzz',      url => $url, text => $text, image => $image %>">Share to Google Buzz</a>
  <a href="<%= share_url 'vkontakte', url => $url %>">Share to ВКонтакте</a>
  <a href="<%= share_url 'mymailru',    url => $url %>">Share to Мой Мир</a>

  # share buttons:
  %= share_button 'twitter',   url => 'http://mojolicio.us', text => 'Viva la revolution!', via => 'sharifulin';
  %= share_button 'facebook',  url => 'http://mojolicio.us', type => 'button_count', title => 'Share it';
  %= share_button 'buzz',      url => 'http://mojolicio.us', text => 'Viva la revolution', image => 'http://mojolicious.org/webinabox.png', type => 'normal-count', title => 'Share it';
  %= share_button 'vkontakte', url => 'http://mojolicio.us', type => 'round', title => 'Save';
  %= share_button 'mymailru',  url => 'http://mojolicio.us', type => 'button_count', title => 'Share to Мой Мир';

  # generate meta for share
  %= share_meta title => 'Mojolicious', description => 'Viva la revolition!', url => 'http://mojolicio.us', image => 'http://mojolicious.org/webinabox.png'
  %= share_meta title => 'Mojolicious', description => 'Viva la revolition!', url => 'http://mojolicio.us', image => 'http://mojolicious.org/webinabox.png', og => 1, fb_app_id => 1234567890, site_name => 'Site Name'


=head1 DESCRIPTION

L<Mojolicous::Plugin::ShareHelpers> is a plugin for generate share url, share button and share meta (Twitter, Facebook, VKontakte).

Plugin adds a C<share_url>, C<share_button>, C<share_meta> helpers to L<Mojolicious>.

Twitter Share L<http://dev.twitter.com/pages/tweet_button>

Facebook Share L<http://developers.facebook.com/docs/share>

Google Buzz Share L<http://www.google.com/buzz/api/admin/configPostWidget>

VKontakte Share L<http://vkontakte.ru/pages.php?act=share>

My.MailRU Share L<http://api.mail.ru/sites/plugins/share/extended/>

=head2 HELPERS

<%= share_url %>

Generate share url.

<%= share_button %>

Generate share button.

=head1 METHODS

L<Mojolicious::Plugin::ShareHelpers> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

	$plugin->register;

Register plugin hooks in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Anatoly Sharifulin <sharifulin@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-sharehelpers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.htMail?Queue=Mojolicious-plugin-sharehelpers>.  We will be notified, and then you'll
automatically be notified of progress on your bug as we make changes.

=over 5

=item * Github

L<http://github.com/sharifulin/Mojolicious-plugin-sharehelpers/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.htMail?Dist=Mojolicious-plugin-sharehelpers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-plugin-sharehelpers>

=item * CPANTS: CPAN Testing Service

L<http://cpants.perl.org/dist/overview/Mojolicious-plugin-sharehelpers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-plugin-sharehelpers>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-plugin-sharehelpers>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010 by Anatoly Sharifulin.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

#!/usr/bin/env perl
use lib qw(lib /tk/lib /tk/mojo/lib);

use Mojolicious::Lite;

app->log->level('error');

plugin 'share';

get '/'   => 'index';
get "/$_" => $_ for qw(twitter facebook buzz vkontakte meta);

use Test::More tests => 17;
use Test::Mojo;

my $t = Test::Mojo->new;

$t->get_ok('/twitter')
  ->status_is(200)
  ->content_is(
	q(http://twitter.com/share?text=Viva%20la%20revolution%21&amp;url=http%3A%2F%2Fmojolicio.us) .
	q(<a href="http://twitter.com/share" class="twitter-share-button" data-url="http://mojolicio.us" data-via="sharifulin" data-text="Viva la revolution!">Tweet</a><script type="text/javascript" src="http://platform.twitter.com/widgets.js"></script>) . 
	q(<iframe allowtransparency="true" frameborder="0" scrolling="no" style="width:130px; height:50px;" src="http://platform.twitter.com/widgets/tweet_button.html?text=Viva%20la%20revolution%21&url=http%3A%2F%2Fmojolicio.us"></iframe>)
);

$t->get_ok('/facebook')
  ->status_is(200)
  ->content_is(
	q(http://facebook.com/sharer.php?t=Viva%20la%20revolution%21&amp;u=http%3A%2F%2Fmojolicio.us) .
	q(<a name="fb_share" share_url="http://mojolicio.us" type="button_count">Share it</a><script src="http://static.ak.fbcdn.net/connect.php/js/FB.Share" type="text/javascript"></script>) .
	q(<fb:share-button href="http://mojolicio.us" type="icon"></fb:share-button>)
);

$t->get_ok('/buzz')
  ->status_is(200)
  ->content_is(
	q(http://www.google.com/buzz/post?imageurl=http%3A%2F%2Fmojolicious.org%2Fwebinabox.png&amp;url=http%3A%2F%2Fmojolicio.us) . 
	q(<a title="Share it" class="google-buzz-button" href="http://www.google.com/buzz/post" data-imageurl="http://mojolicious.org/webinabox.png" data-url="http://mojolicio.us" data-button-style="normal-count"></a><script type="text/javascript" src="http://www.google.com/buzz/api/button.js"></script>) .
	q(<a title="Share to Google Buzz" class="google-buzz-button" href="http://www.google.com/buzz/post" data-url="http://mojolicio.us" data-locale="ru" data-button-style="link"></a><script type="text/javascript" src="http://www.google.com/buzz/api/button.js"></script>)
);

$t->get_ok('/vkontakte')
  ->status_is(200)
  ->content_is(
	q(http://vkontakte.ru/share.php?url=http%3A%2F%2Fmojolicio.us) .
	q(<script type="text/javascript" src="http://vkontakte.ru/js/api/share.js?9" charset="windows-1251"></script><script type="text/javascript">document.write(VK.Share.button({url: "http://mojolicio.us"}, {text: "Save", type: "round"}));</script>) .
	q(<script type="text/javascript" src="http://vkontakte.ru/js/api/share.js?9" charset="windows-1251"></script><script type="text/javascript">document.write(VK.Share.button(false, {text: "Save", type: "custom"}));</script>)
);

$t->get_ok('/meta')
  ->status_is(200)
  ->content_is(
	q(<meta name="medium" content="mult"/>
<meta name="title" content="Mojolicious"/>
<meta name="description" content="Viva la revolition!"/>
<link rel="image_src" href="http://mojolicious.org/webinabox.png" />
<link rel="target_url" href="http://mojolicio.us"/><meta name="medium" content="mult"/>
<meta property="fb:app_id" content="1234567890"/>
<meta property="og:site_name" content="Site Name" />
<meta property="og:type" content="website" />
<meta property="og:image" content="http://mojolicious.org/webinabox.png"/>
<meta property="og:title" content="Mojolicious"/>
<meta property="og:description" content="Viva la revolition!"/>
<meta name="title" content="Mojolicious"/>
<meta name="description" content="Viva la revolition!"/>
<link rel="image_src" href="http://mojolicious.org/webinabox.png" />
<link rel="target_url" href="http://mojolicio.us"/>)
  )
;

$t->get_ok('/')
  ->status_is(200)
  ->tx->res->body
;

__DATA__

@@ twitter.html.ep

%= share_url    'twitter', url => 'http://mojolicio.us', text => 'Viva la revolution!';
%= share_button 'twitter', url => 'http://mojolicio.us', text => 'Viva la revolution!', via => 'sharifulin';
%= share_button 'twitter', url => 'http://mojolicio.us', text => 'Viva la revolution!', iframe => 1;

@@ facebook.html.ep

%= share_url    'facebook', url => 'http://mojolicio.us', text => 'Viva la revolution!';
%= share_button 'facebook', url => 'http://mojolicio.us', type => 'button_count', button_text => 'Share it';
%= share_button 'facebook', url => 'http://mojolicio.us', type => 'icon', fb => 1;

@@ buzz.html.ep

%= share_url    'buzz', url => 'http://mojolicio.us', image => 'http://mojolicious.org/webinabox.png';
%= share_button 'buzz', url => 'http://mojolicio.us', image => 'http://mojolicious.org/webinabox.png', type => 'normal-count', title => 'Share it';
%= share_button 'buzz', url => 'http://mojolicio.us', type => 'link', lang => 'ru';

@@ vkontakte.html.ep

%= share_url    'vkontakte', url => 'http://mojolicio.us';
%= share_button 'vkontakte', url => 'http://mojolicio.us', type => 'round', text => 'Save';
%= share_button 'vkontakte', type => 'custom', text => 'Save';

@@ meta.html.ep

%= share_meta
%= share_meta title => 'Mojolicious', description => 'Viva la revolition!', url => 'http://mojolicio.us', image => 'http://mojolicious.org/webinabox.png'
%= share_meta title => 'Mojolicious', description => 'Viva la revolition!', url => 'http://mojolicio.us', image => 'http://mojolicious.org/webinabox.png', og => 1, fb_app_id => 1234567890, site_name => 'Site Name'

@@ index.html.ep

%== include 'meta'

% for (qw(twitter facebook buzz vkontakte)) {
<p>
	<%== include $_ %>
</p>
% }

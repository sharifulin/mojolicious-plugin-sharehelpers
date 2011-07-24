#!/usr/bin/env perl
use common::sense;
use lib qw(lib ../mojo/lib);

use Mojolicious::Lite;

plugin 'share_helpers';

get '/' => 'index';

app->start('daemon');

__DATA__

@@ index.html.ep

%== share_button 'google+'
<br/><br/>
%== share_button 'google+', noscript => 1
<br/><br/>
%== share_button 'google+', noscript => 1, size => 'tall', url => 'http://mojolicio.us'
<br/><br/>
%== share_button 'google+', noscript => 1, size => 'standard', url => 'http://mojolicio.us', count => 'false'
<br/><br/>
%== share_button 'google+', noscript => 1, size => 'standard', url => 'http://mojolicio.us', count => 'false', callback => 'GooglePlusCallback'
<br/><br/>
%== share_button 'google+', size => 'small', lang => 'ru'
<br/><br/>
%== share_button 'google+', size => 'small', lang => 'ru', parsetags => 'explicit'
<br/><br/>

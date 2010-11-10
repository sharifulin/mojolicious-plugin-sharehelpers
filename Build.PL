use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Mojolicious::Plugin::ShareHelpers',
	license             => 'perl',
	dist_author         => 'Anatoly Sharifulin <sharifulin@gmail.com>',
	dist_version_from   => 'lib/Mojolicious/Plugin/ShareHelpers.pm',
	dist_abstract       => 'for generate share url, button and meta (Twitter, Facebook, Buzz, VKontakte, MyMailRU)',
	build_requires => {
		'Test::More' => 0,
	},
	requires => {
		'Mojolicious' => '0.999937',
	},
	add_to_cleanup  => [],
	meta_merge => {
		resources => {
			repository => 'http://github.com/sharifulin/Mojolicious-Plugin-ShareHelpers',
		},
		keywords => ['mojo', 'mojolicious', 'share', 'helper', 'plugin'],
	},
	create_makefile_pl => 'traditional',
);

$builder->create_build_script();

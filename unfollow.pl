#!/usr/bin/perl

use strict;
use warnings;
use Net::Twitter::Lite::WithAPIv1_1;
use YAML;
use Encode;
use Data::Dumper;
$| = 1;

my $consumer_key = 'YOUR_CONSUMER_KEY_HERE';
my $consumer_secret = 'YOUR_CONSUMER_SECRET_HERE';
my $access_token = 'YOUR_ACCESS_TOKEN_HERE';
my $access_token_secret = 'YOUR_ACCESS_TOKEN_SECRET_HERE';

my $client = new Net::Twitter::Lite::WithAPIv1_1(
	consumer_key => $consumer_key,
	consumer_secret => $consumer_secret,
	access_token => $access_token,
	access_token_secret => $access_token_secret,
	ssl => 1,
);

my $timeline = $client->user_timeline();
my $screen_name = $$timeline[0]{"user"}{"screen_name"};

my $next_cursor = -1;
my %followers_list = ();

while ($next_cursor != 0) {
	my $result = $client->followers_list({
		screen_name => $screen_name,
		cursor => $next_cursor,
		count => 200,
	});

	$next_cursor = $$result{"next_cursor"};

	my $users = $$result{"users"};

	foreach my $user (@$users) {
		my $screen_name = $$user{"screen_name"};
		$followers_list{$screen_name} = 1;
	}

	sleep(4);
}

$next_cursor = -1;

my @unfollow_list;
my %unfollow_whitelist;
my $whitelist = YAML::LoadFile("whitelist.yml");
foreach(@$whitelist) {
  $unfollow_whitelist{$_} = 1;
}

while ($next_cursor != 0) {
	my $result = $client->friends_list({
		screen_name => $screen_name,
		cursor => $next_cursor,
		count => 200,
	});

	$next_cursor = $$result{"next_cursor"};

	my $users = $$result{"users"};

	foreach my $user (@$users) {
		my $screen_name = $$user{"screen_name"};
		if(!exists($followers_list{$screen_name})) {
			if(!exists($unfollow_whitelist{$screen_name})){
				push(@unfollow_list, $screen_name);
			}
		}
	}

	sleep(4);
}

foreach my $unfollow_user (@unfollow_list) {
	$client->unfollow({
		screen_name => $unfollow_user
	});
	print "Unfollowed ".$unfollow_user."\n";

	sleep(2);
}
#!/usr/bin/env perl

use strict;
use warnings;

use Config::Auto;
use JSON::XS;
use Net::DNS;
use Unix::Syslog qw(:macros :subs);

my $DNS_KEY = 'ctf.tng.retreat.';
my $DNS_SECRET = 'hjScR9gNoz0PY3CgNSmtHRdeEejNrHDyIfwufM0FY/8YfVXlY0j2LO3tSpDbMcCvj26FGJn4//XlXx7qz519rQ==';
my $DNS_SERVER = '127.0.0.1';
my $DNS_ZONE = 'ctf.tng.retreat.';
my $DNS_REVERSE_ZONE = '0.17.172.in-addr.arpa.';
my $DNS_TTL = 15 * 60;

openlog('dns4docker', LOG_PID | LOG_CONS, LOG_USER);

my $dns = Net::DNS::Resolver->new(nameservers => [ $DNS_SERVER ]);
my $config = Config::Auto->new(source => '/etc/docker/dns4docker.conf')->parse;

open my $events, '-|', qw(docker events) or do {
    syslog LOG_CRIT, 'Cannot listen to docker events: %s!', $!;
    die "Cannot listen to docker events: $!";
};
while (<$events>) {
    next unless /
        \S+\s                # time stamp
        ([[:xdigit:]]+):\s   # container id
        [(]from\s
        ([^:]+):([^:]+)      # image:tag
        [)]\s
        (start|die)          # action
    /x;
    my ($container, $image, $tag, $action) = ($1, $2, $3, $4);
    syslog LOG_INFO, 'relevant docker event registered: container: %s (from %s:%s), action: %s', $container, $image, $tag, $action;

    my $container_details = decode_json `docker inspect $container`;

    my $hostname = get_hostname_for_container($config, $image, $tag, $container_details);
    if ($hostname) {
        syslog LOG_INFO, 'determined hostname: %s', $hostname;
        if ($action eq 'start') {
            my $ip = $container_details->[0]{NetworkSettings}{IPAddress};
            register_in_dns($dns, $hostname, $ip);
        } else {
            remove_from_dns($dns, $hostname);
        }
    } else {
        syslog LOG_INFO, 'nothing to do for container %s', $container;
    }
}
close $events;
closelog;

sub register_in_dns {
    my ($dns, $hostname, $ip) = @_;

    syslog LOG_INFO, 'creating dns entry for %s with ip %s', $hostname, $ip;
    my $packet = Net::DNS::Update->new($DNS_ZONE);
    $packet->push(update => rr_add("$hostname.$DNS_ZONE $DNS_TTL A $ip"));
    update_dns($dns, $packet);

    syslog LOG_INFO, 'creating reverse lookup dns entry for %s with ip %s', $hostname, $ip;
    $packet = Net::DNS::Update->new($DNS_REVERSE_ZONE);
    my $ptr = (split /\./, $ip)[-1];
    $packet->push(update => rr_add("$ptr.$DNS_REVERSE_ZONE $DNS_TTL PTR $hostname.$DNS_ZONE"));
    update_dns($dns, $packet);
}

sub remove_from_dns {
    my ($dns, $hostname) = @_;

    my $reply = $dns->query("$hostname.$DNS_ZONE");
    if ($reply) {
        my $ip;
        foreach ($reply->answer) {
            $ip = $_->address if $_->{type} eq 'A';
            last if $ip;
        }
        if ($ip) {
            my $ptr = (split /\./, $ip)[-1];
            syslog LOG_INFO, 'deleting reverse lookup dns entry for %s', "$ptr.$DNS_REVERSE_ZONE";
            my $packet = Net::DNS::Update->new($DNS_REVERSE_ZONE);
            $packet->push(update => rr_del("$ptr.$DNS_REVERSE_ZONE PTR"));
            update_dns($dns, $packet);
        }
    }
    syslog LOG_INFO, 'deleting dns entry for %s', $hostname;
    my $packet = Net::DNS::Update->new($DNS_ZONE);
    $packet->push(update => rr_del("$hostname.$DNS_ZONE A"));
    update_dns($dns, $packet);
}

sub update_dns {
    my ($dns, $packet) = @_;

    $packet->sign_tsig($DNS_KEY, $DNS_SECRET);
    my $reply = $dns->send($packet);

    if ($reply) {
        if ($reply->header->rcode ne 'NOERROR') {
            syslog LOG_ERR, 'updating DNS (%s) failed: %s', $DNS_SERVER, $reply->header->rcode;
        }
    } else {
        syslog LOG_ERR, 'updating DNS (%s) failed: %s', $DNS_SERVER, $dns->errorstring;
    }
}

sub get_hostname_for_container {
    my ($config, $image, $tag, $details) = @_;

    my $config_entry = $config->{"$image:$tag"} || $config->{$image};
    return unless $config_entry;

    no strict 'refs';
    return defined &$config_entry ? &$config_entry($details->[0]) : $config_entry;
}

sub host_from_image {
    my $details = shift;

    my ($image, $version) = split(":", $details->{Config}{Image});
    return "$image";
}

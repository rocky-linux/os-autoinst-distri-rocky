#!/bin/perl

use JSON;

my $templates = do './templates';
my $updates = do './templates-updates';

my $tempjson = JSON->new->utf8(1)->pretty(1)->encode($templates);
my $updjson = JSON->new->utf8(1)->pretty(1)->encode($updates);

open(FILE, "> templates.json");
print FILE $tempjson;

open (FILE, "> templates-updates.json");
print FILE $updjson;

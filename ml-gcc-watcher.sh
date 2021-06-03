#!/bin/bash

# watch the list in every 1 hour
FREQ=3600
# how many items in the list
BATCH_SIZE=100

# JOB URL
JOB_URL="https://ci.rvperf.org/job/ml-fsf-gcc-master-ubuntu2004/build?token=${CI_JOB_TOKEN}"

# Pleasee make sure your $HOME/.pwclientrc has this config:

# # Sample .pwclientrc file for the gcc project,
# # running on patchwork.ozlabs.org.
# #
# # Just append this file to your existing ~/.pwclientrc
# # If you do not already have a ~/.pwclientrc, then copy this file to
# # ~/.pwclientrc, and uncomment the following two lines:
# # [options]
# # default=gcc
# 
# [gcc]
# url = https://patchwork.ozlabs.org/xmlrpc/


# Make sure you have installed pwclient
check_pwclient () {
	echo TODO
}

function trigger_ci () {
	ID="$1"
	curl "$JOB_URL"
}

function fetch_and_trigger () {
	pwclient list -p gcc -N "$BATCH_SIZE" | tail -n +3 > DEBUG.fetch
	cat DEBUG.fetch | cut -f1 -d' ' DEBUG.fetch \
	| while read ID; do
		grep -q -w "$ID" DATA.fetched && continue
		trigger_ci "$ID"
		echo "$ID" >> DATA.fetched
	done
}

while true; do
	fetch_and_trigger
	sleep "$FREQ"
done


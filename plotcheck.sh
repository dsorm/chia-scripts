#!/bin/bash
mkdir plotcheck > /dev/null
logfile="plotcheck/$(date +"%FT%H%M").txt"
chia plots check -l 2>&1 | tee -a "${logfile}"

warning="$(cat ${logfile} | grep WARNING)"
found="$(cat ${logfile} | grep Found)"

curl -s \
  --form-string "token=INSERT_PUSHOVER_TOKEN_HERE" \
  --form-string "user=INSERT_PUSHOVER_USER_HERE" \
  --form-string "message=plotcheck: ${found} ${warning}" \
  https://api.pushover.net/1/messages.json
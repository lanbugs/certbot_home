#!/usr/bin/env bash

#
# Certbot Home
# See https://github.com/lanbugs/certbot_home
# 26.12.2024 Maximilian Thoma https://lanbugs.de
#

set -euo pipefail

HETZNER_DNS_TOKEN="xxxxx"
DOMAIN="$CERTBOT_DOMAIN"
VALIDATION="$CERTBOT_VALIDATION"

ZONES_JSON=$(curl -s -X GET "https://dns.hetzner.com/api/v1/zones" \
  -H "Auth-API-Token: $HETZNER_DNS_TOKEN")

find_zone_id() {
  local d="$1"
  while [ -n "$d" ]; do
    local id
    id=$(echo "$ZONES_JSON" | jq -r --arg domain "$d" '.zones[] | select(.name == $domain) | .id')
    if [ -n "$id" ] && [ "$id" != "null" ]; then
      echo "$id"
      return 0
    fi
    d="${d#*.}"
  done
  echo ""
}

ZONE_ID=$(find_zone_id "$DOMAIN")
if [ -z "$ZONE_ID" ]; then
  exit 1
fi

RECORD_ID=$(curl -s -X GET "https://dns.hetzner.com/api/v1/records?zone_id=$ZONE_ID" \
  -H "Auth-API-Token: $HETZNER_DNS_TOKEN" \
  | jq -r --arg val "$VALIDATION" '.records[] | select(.value == $val and .type == "TXT") | .id')

if [ -n "$RECORD_ID" ]; then
  error=$(curl -s -X DELETE "https://dns.hetzner.com/api/v1/records/$RECORD_ID" \
    -H "Auth-API-Token: $HETZNER_DNS_TOKEN" | jq -r '.error')

  if [ "$error" != "{}" ]; then
    echo "Error: $error"
    exit 1
  else
    exit 0
  fi

fi

#!/usr/bin/env bash

#
# Certbot Home
# See https://github.com/lanbugs/certbot_home
# 26.12.2024 Maximilian Thoma https://lanbugs.de
#

set -euo pipefail

HETZNER_DNS_TOKEN="xxxx"
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

find_zone_name() {
  local d="$1"
  while [ -n "$d" ]; do
    local name
    name=$(echo "$ZONES_JSON" | jq -r --arg domain "$d" '.zones[] | select(.name == $domain) | .name')
    if [ -n "$name" ] && [ "$name" != "null" ]; then
      echo "$name"
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

ZONE_NAME=$(find_zone_name "$DOMAIN")
SUBDOMAIN="${DOMAIN%.$ZONE_NAME}"
if [ "$SUBDOMAIN" = "$DOMAIN" ] || [ -z "$ZONE_NAME" ]; then
  RECORD_NAME="_acme-challenge"
elif [ -z "$SUBDOMAIN" ]; then
  RECORD_NAME="_acme-challenge"
else
  RECORD_NAME="_acme-challenge.$SUBDOMAIN"
fi

CREATE_RESULT=$(curl -s -X POST "https://dns.hetzner.com/api/v1/records" \
  -H "Auth-API-Token: $HETZNER_DNS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"value\": \"$VALIDATION\",
    \"type\": \"TXT\",
    \"name\": \"$RECORD_NAME\",
    \"ttl\": 120,
    \"zone_id\": \"$ZONE_ID\"
  }")

RECORD_ID=$(echo "$CREATE_RESULT" | jq -r '.record.id // empty')
if [ -z "$RECORD_ID" ]; then
  exit 1
fi

sleep 30

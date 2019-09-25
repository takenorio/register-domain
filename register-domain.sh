#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

readonly REGION='us-east-1'
readonly DURATION_IN_YEARS=1

function usage() {
  RC="$1"
  echo "Usage: $0 -d domain-name -f json-file" >&2
  exit "${RC}"
}

while getopts "d:f:h" OPT; do
  case "${OPT}" in
    d) DOMAIN_NAME="${OPTARG}" ;;
    f) CONTACT_JSON="${OPTARG}" ;;
    h) usage 0 ;;
    *) usage 1 ;;
  esac
done

shift $((OPTIND - 1))

if [[ -z "${DOMAIN_NAME:=}" || -z "${CONTACT_JSON:=}" ]]; then
  usage 1
fi

AVAILABILITY=$(aws route53domains check-domain-availability \
  --region "${REGION}" \
  --domain-name "${DOMAIN_NAME}")

if ! echo "${AVAILABILITY}" | grep -q '"AVAILABLE"'; then
  echo "${AVAILABILITY}"
  exit 1
fi

ADMIN_CONTACT="${CONTACT_JSON}"
REGISTRANT_CONTACT="${CONTACT_JSON}"
TECH_CONTACT="${CONTACT_JSON}"

aws route53domains register-domain \
  --region "${REGION}" \
  --domain-name "${DOMAIN_NAME}" \
  --duration-in-years "${DURATION_IN_YEARS}" \
  --admin-contact "file://${ADMIN_CONTACT}" \
  --registrant-contact "file://${REGISTRANT_CONTACT}" \
  --tech-contact "file://${TECH_CONTACT}" \
  --auto-renew \
  --privacy-protect-admin-contact \
  --privacy-protect-registrant-contact \
  --privacy-protect-tech-contact

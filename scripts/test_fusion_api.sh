#!/usr/bin/env bash
#
# Quick connectivity test for the Oracle Fusion Expense Reports REST API.
# Run this first to confirm your host + credentials work, before wiring the
# integration into APEX.
#
# Usage:
#   FUSION_HOST=your-fusion-host.fa.ocs.oraclecloud.com \
#   FUSION_USER='your.user' \
#   FUSION_PASS='your-password' \
#   ./scripts/test_fusion_api.sh [optional ExpenseReportStatus filter]
#
# Example:
#   ... ./scripts/test_fusion_api.sh PAID
#
set -euo pipefail

: "${FUSION_HOST:?Set FUSION_HOST to your Fusion host (no https://, no trailing slash)}"
: "${FUSION_USER:?Set FUSION_USER to your Fusion user id}"
: "${FUSION_PASS:?Set FUSION_PASS to your Fusion password}"

RESOURCE="/fscmRestApi/resources/11.13.18.05/expenseReports"
URL="https://${FUSION_HOST}${RESOURCE}?onlyData=true&limit=10"

STATUS_FILTER="${1:-}"
if [[ -n "${STATUS_FILTER}" ]]; then
  # URL-encode the q expression: ExpenseReportStatus='<value>'
  URL="${URL}&q=$(printf "ExpenseReportStatus='%s'" "${STATUS_FILTER}" | \
        sed -e "s/ /%20/g" -e "s/'/%27/g")"
fi

echo "GET ${URL}"
echo "----------------------------------------------------------------------"

curl --silent --show-error --fail-with-body \
     --user "${FUSION_USER}:${FUSION_PASS}" \
     --header "Accept: application/json" \
     "${URL}" | { command -v jq >/dev/null 2>&1 && jq '.' || cat; }

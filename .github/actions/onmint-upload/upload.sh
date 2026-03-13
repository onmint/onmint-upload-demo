#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# OnMint Upload Script
# Uploads a zip artifact to the OnMint platform via the API controller
# =============================================================================

API_URL="${ONMINT_API_URL}"
API_KEY="${ONMINT_API_KEY}"
API_SECRET="${ONMINT_API_SECRET}"
STREAM_ID="${ONMINT_STREAM_ID}"
UPLOAD_PATH="${ONMINT_PATH:-.}"
ATTACHMENT_NAME="${ONMINT_NAME}"
ATTACHMENT_DESC="${ONMINT_DESCRIPTION}"

POLL_INTERVAL=5
POLL_TIMEOUT=600  # 10 minutes

# ---------- Helpers ----------

log() { echo "::group::$1"; }
endlog() { echo "::endgroup::"; }
fail() { echo "::error::$1"; exit 1; }

api_call() {
  local method="$1" endpoint="$2"
  shift 2
  curl -sf -X "$method" \
    -H "x-api-key: ${API_KEY}" \
    -H "x-api-secret: ${API_SECRET}" \
    -H "Content-Type: application/json" \
    "$@" \
    "${API_URL}${endpoint}"
}

# ---------- Step 1: Create zip ----------

log "Creating zip archive"

if [ -z "$ATTACHMENT_NAME" ]; then
  REPO_NAME="${GITHUB_REPOSITORY##*/}"
  REF="${GITHUB_REF_NAME:-$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')}"
  ATTACHMENT_NAME="${REPO_NAME}-${REF}"
fi

ZIP_FILE="/tmp/${ATTACHMENT_NAME}.zip"

if [ -f "$UPLOAD_PATH" ]; then
  cp "$UPLOAD_PATH" "$ZIP_FILE"
else
  cd "$UPLOAD_PATH"
  zip -r "$ZIP_FILE" . -x '.git/*' '.github/*' 'node_modules/*' '__pycache__/*' '*.pyc' '.env*'
  cd - > /dev/null
fi

FILE_SIZE=$(stat -c%s "$ZIP_FILE" 2>/dev/null || stat -f%z "$ZIP_FILE" 2>/dev/null)
echo "Archive created: ${ZIP_FILE} (${FILE_SIZE} bytes)"
endlog

# ---------- Step 2: Create attachment ----------

log "Creating attachment"

CREATE_BODY=$(cat <<EOF
{
  "stream_id": "${STREAM_ID}",
  "name": "${ATTACHMENT_NAME}",
  "description": "${ATTACHMENT_DESC}",
  "filename": "${ATTACHMENT_NAME}.zip",
  "estimated_size": ${FILE_SIZE},
  "upload_as_zip": true,
  "ledger": "POLYGON_POS"
}
EOF
)

CREATE_RESPONSE=$(api_call POST "/attachments" -d "$CREATE_BODY")
echo "Create response: ${CREATE_RESPONSE}"

ATTACHMENT_ID=$(echo "$CREATE_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null || true)
[ -z "$ATTACHMENT_ID" ] && fail "Failed to get attachment ID from response"

echo "Attachment ID: ${ATTACHMENT_ID}"
endlog

# ---------- Step 3: Upload file ----------

log "Uploading file"

# Presigned URLs come from GET, not the POST response
GET_RESPONSE=$(api_call GET "/attachments/${ATTACHMENT_ID}")
echo "Attachment details retrieved"

# The API returns presigned_urls as an array of {part, link} objects
PRESIGNED_URL=$(echo "$GET_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
urls = data.get('presigned_urls') or []
if urls:
    print(urls[0].get('link', ''))
else:
    print('')
" 2>/dev/null || true)

if [ -n "$PRESIGNED_URL" ] && [ "$PRESIGNED_URL" != "None" ] && [ "$PRESIGNED_URL" != "" ]; then
  echo "Uploading via presigned URL..."
  HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" -X PUT \
    -H "Content-Type: application/zip" \
    --data-binary "@${ZIP_FILE}" \
    "$PRESIGNED_URL")
  [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ] || fail "Upload failed with HTTP ${HTTP_CODE}"
  echo "Upload complete (HTTP ${HTTP_CODE})"
else
  fail "No presigned URL in response"
fi

endlog

# ---------- Step 4: Poll for completion ----------

log "Polling attachment status"

ELAPSED=0
FINAL_STATUS=""

while [ "$ELAPSED" -lt "$POLL_TIMEOUT" ]; do
  STATUS_RESPONSE=$(api_call GET "/attachments/${ATTACHMENT_ID}")
  CURRENT_STATUS=$(echo "$STATUS_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null || true)
  echo "Status: ${CURRENT_STATUS} (${ELAPSED}s elapsed)"

  case "$CURRENT_STATUS" in
    FILEDGR_DATA_ATTACHMENT_COMPLETED)
      FINAL_STATUS="$CURRENT_STATUS"
      break
      ;;
    ERROR)
      ERROR_MSG=$(echo "$STATUS_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('error_message','unknown'))" 2>/dev/null || true)
      fail "Attachment processing failed: ${ERROR_MSG}"
      ;;
  esac

  sleep "$POLL_INTERVAL"
  ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

[ -z "$FINAL_STATUS" ] && fail "Polling timed out after ${POLL_TIMEOUT}s (last status: ${CURRENT_STATUS})"

# Extract CID if available
CID=$(echo "$STATUS_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
files = data.get('files', [])
if files:
    print(files[0].get('cid', ''))
else:
    print('')
" 2>/dev/null || true)

echo ""
echo "====================================="
echo "  Upload Complete!"
echo "  Attachment ID: ${ATTACHMENT_ID}"
echo "  CID: ${CID}"
echo "  Status: ${FINAL_STATUS}"
echo "====================================="
endlog

# ---------- Outputs ----------

rm -f "$ZIP_FILE"

echo "attachment_id=${ATTACHMENT_ID}" >> "$GITHUB_OUTPUT"
echo "status=${FINAL_STATUS}" >> "$GITHUB_OUTPUT"
echo "cid=${CID}" >> "$GITHUB_OUTPUT"

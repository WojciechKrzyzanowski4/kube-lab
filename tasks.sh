#!/usr/bin/env bash

BASE_URL="${BASE_URL:-http://kube-lab-api.127.0.0.1.nip.io}"
TOTAL=20
SCORE=0

ok() {
  echo "[$1/$TOTAL] ✅ $2"
  SCORE=$((SCORE + 1))
}

fail() {
  echo "[$1/$TOTAL] ❌ $2"
}

curl_json() {
  local url="$1" method="${2:-GET}" data="$3"
  local tmp status body
  tmp="$(mktemp)"
  status=$(curl -s -o "$tmp" -w "%{http_code}" -H "Content-Type: application/json" -X "$method" ${data:+-d "$data"} "$url" 2>/dev/null || echo "000")
  body="$(cat "$tmp")"
  rm -f "$tmp"
  printf "%s\n%s" "$status" "$body"
}

pattern_check() {
  local file="$1" pattern="$2"
  python - "$file" "$pattern" <<'PY' >/dev/null 2>&1
import sys, re, pathlib
file, pat = sys.argv[1], sys.argv[2]
text = pathlib.Path(file).read_text()
sys.exit(0 if re.search(pat, text, re.S) else 1)
PY
}

desc="Health endpoint returns status ok JSON"
resp="$(curl_json "$BASE_URL/healthz")"
status="${resp%%$'\n'*}"
body="${resp#*$'\n'}"
if [ "$status" = "200" ] && echo "$body" | grep -qi '"status"[[:space:]]*:[[:space:]]*"ok"'; then ok 1 "$desc"; else fail 1 "$desc"; fi

desc="Config endpoint returns app_env"
resp="$(curl_json "$BASE_URL/config")"
status="${resp%%$'\n'*}"
body="${resp#*$'\n'}"
if [ "$status" = "200" ] && echo "$body" | grep -qi 'app_env'; then ok 2 "$desc"; else fail 2 "$desc"; fi

desc="Version endpoint returns version"
resp="$(curl_json "$BASE_URL/version")"
status="${resp%%$'\n'*}"
body="${resp#*$'\n'}"
if [ "$status" = "200" ] && echo "$body" | grep -qi 'version'; then ok 3 "$desc"; else fail 3 "$desc"; fi

desc="Secret-check endpoint reports token presence"
resp="$(curl_json "$BASE_URL/secret-check")"
status="${resp%%$'\n'*}"
body="${resp#*$'\n'}"
if [ "$status" = "200" ] && echo "$body" | grep -qi 'has_dummy_token'; then ok 7 "$desc"; else fail 7 "$desc"; fi

VALUES_FILE="devops/kube-lab/values.yaml"

desc="values.yaml sets api.replicas to 3"
if pattern_check "$VALUES_FILE" 'api:\s*\n(?:.*\n)*?replicas:\s*3'; then ok 11 "$desc"; else fail 11 "$desc"; fi

desc="values.yaml config defines GREETING_PREFIX"
if pattern_check "$VALUES_FILE" 'config:\s*\n(?:.*\n)*?GREETING_PREFIX:'; then ok 12 "$desc"; else fail 12 "$desc"; fi

desc="values.yaml config defines APP_VERSION"
if pattern_check "$VALUES_FILE" 'config:\s*\n(?:.*\n)*?APP_VERSION:'; then ok 13 "$desc"; else fail 13 "$desc"; fi

desc="values.yaml secret defines API_TOKEN"
if pattern_check "$VALUES_FILE" 'secret:\s*\n(?:.*\n)*?API_TOKEN:'; then ok 14 "$desc"; else fail 14 "$desc"; fi

desc="autoscaling.enabled set to true"
if pattern_check "$VALUES_FILE" 'autoscaling:\s*\n(?:.*\n)*?enabled:\s*true'; then ok 15 "$desc"; else fail 15 "$desc"; fi

desc="autoscaling.minReplicas set to 2"
if pattern_check "$VALUES_FILE" 'autoscaling:\s*\n(?:.*\n)*?minReplicas:\s*2'; then ok 16 "$desc"; else fail 16 "$desc"; fi

desc="autoscaling.maxReplicas set to 5"
if pattern_check "$VALUES_FILE" 'autoscaling:\s*\n(?:.*\n)*?maxReplicas:\s*5'; then ok 17 "$desc"; else fail 17 "$desc"; fi

desc="autoscaling.targetCPUUtilizationPercentage set to 60"
if pattern_check "$VALUES_FILE" 'autoscaling:\s*\n(?:.*\n)*?targetCPUUtilizationPercentage:\s*60'; then ok 18 "$desc"; else fail 18 "$desc"; fi

desc="Ingress hosts include kube-lab.local"
if grep -q "kube-lab.local" "$VALUES_FILE"; then ok 19 "$desc"; else fail 19 "$desc"; fi

desc="values.dev.yaml exists and sets replicas to 1"
DEV_FILE="devops/kube-lab/values.dev.yaml"
if [ -f "$DEV_FILE" ] && pattern_check "$DEV_FILE" 'replicas:\s*1'; then ok 20 "$desc"; else fail 20 "$desc"; fi

echo
echo "Score: $SCORE/$TOTAL"
if [ "$SCORE" -lt "$TOTAL" ]; then
  echo "Tip: ensure the app is running at $BASE_URL and that values.yaml matches the tasks."
fi

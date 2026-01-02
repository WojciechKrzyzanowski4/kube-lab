#!/usr/bin/env bash

BASE_URL="${BASE_URL:-http://kube-lab-api.127.0.0.1.nip.io}"
TOTAL=20
SCORE=0
VALUES_FILE="devops/kube-lab/values.yaml"
DEV_FILE="devops/kube-lab/values.dev.yaml"

ok() {
  echo "[$1/$TOTAL] ✅ $2"
  SCORE=$((SCORE + 1))
}

fail() {
  echo "[$1/$TOTAL] ❌ $2"
}

pattern_check() {
  local file="$1" pattern="$2"
  PERL_PATTERN="$pattern" perl -0777 -ne '$m=1 if /$ENV{PERL_PATTERN}/s; END { exit($m ? 0 : 1) }' "$file" >/dev/null 2>&1
}

task=1
desc="api.replicas set to 3"
if pattern_check "$VALUES_FILE" 'replicas:\s*3'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="image.pullPolicy set to Always"
if pattern_check "$VALUES_FILE" 'pullPolicy:\s*Always'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="config sets APP_GREETING to Welcome to the Lab"
if pattern_check "$VALUES_FILE" 'APP_GREETING:\s*"Welcome to the Lab"'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="config sets APP_ENV to lab"
if pattern_check "$VALUES_FILE" 'APP_ENV:\s*"?(lab)"?'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="secret defines API_KEY (non-empty)"
if pattern_check "$VALUES_FILE" 'API_KEY:\s*[^\s]'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="requests set: cpu 100m and memory 128Mi"
if pattern_check "$VALUES_FILE" 'cpu:\s*100m' && pattern_check "$VALUES_FILE" 'memory:\s*128Mi'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="limits set: cpu 250m and memory 256Mi"
if pattern_check "$VALUES_FILE" 'cpu:\s*250m' && pattern_check "$VALUES_FILE" 'memory:\s*256Mi'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="pod annotations include example.com/release: lab"
if pattern_check "$VALUES_FILE" 'example\.com/release:\s*"lab"'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="service annotations include prometheus scrape hints"
if pattern_check "$VALUES_FILE" 'prometheus\.io/scrape:\s*"true"' && pattern_check "$VALUES_FILE" 'prometheus\.io/port:\s*"5000"'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="rolling update strategy maxSurge=1, maxUnavailable=0"
if pattern_check "$VALUES_FILE" 'maxSurge:\s*1' && pattern_check "$VALUES_FILE" 'maxUnavailable:\s*0'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="nodeSelector sets kubernetes.io/os: linux"
if pattern_check "$VALUES_FILE" 'kubernetes\.io/os:\s*linux'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="tolerations include key=workload effect=NoSchedule"
if pattern_check "$VALUES_FILE" 'key:\s*workload' && pattern_check "$VALUES_FILE" 'effect:\s*NoSchedule'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="pod anti-affinity present (spread by app.kubernetes.io/name)"
if pattern_check "$VALUES_FILE" 'podAntiAffinity'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="autoscaling.enabled set to true"
if pattern_check "$VALUES_FILE" 'enabled:\s*true'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="autoscaling.minReplicas set to 2"
if pattern_check "$VALUES_FILE" 'minReplicas:\s*2'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="autoscaling.maxReplicas set to 5"
if pattern_check "$VALUES_FILE" 'maxReplicas:\s*5'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="autoscaling.targetCPUUtilizationPercentage set to 60"
if pattern_check "$VALUES_FILE" 'targetCPUUtilizationPercentage:\s*60'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="Ingress hosts include kube-lab.local"
if grep -q "kube-lab.local" "$VALUES_FILE"; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="Ingress TLS configured with secret kube-lab-tls"
if pattern_check "$VALUES_FILE" 'secretName:\s*kube-lab-tls'; then ok $task "$desc"; else fail $task "$desc"; fi

task=$((task+1))
desc="values.dev.yaml exists with replicas 1 and dev host"
if [ -f "$DEV_FILE" ] && pattern_check "$DEV_FILE" 'replicas:\s*1' && pattern_check "$DEV_FILE" 'kube-lab-dev\.127\.0\.0\.1\.nip\.io'; then ok $task "$desc"; else fail $task "$desc"; fi

echo
echo "Score: $SCORE/$TOTAL"
if [ "$SCORE" -lt "$TOTAL" ]; then
  echo "Tip: ensure the release is deployed and values.yaml/values.dev.yaml match the tasks."
fi

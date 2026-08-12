#!/bin/sh
# 병합된 윤문 룰 파일들에서 `- 금지어 → "대체 표현"` 쌍을 파싱해,
# 대상 파일에서 금지어 히트를 찾는다. fenced code block(```) 내부는 제외한다.
# 출력: <파일>:<줄>	<금지어>	<대체 표현>	<해당 줄 원문>
#
# usage: grep-pass.sh <rules.md ...> -- <target ...>
set -eu

rules=""
targets=""
seen_sep=0
for arg in "$@"; do
  if [ "$arg" = "--" ]; then
    seen_sep=1
    continue
  fi
  if [ "$seen_sep" -eq 0 ]; then
    rules="$rules $arg"
  else
    targets="$targets $arg"
  fi
done

if [ "$seen_sep" -eq 0 ] || [ -z "$rules" ] || [ -z "$targets" ]; then
  echo "usage: $0 <rules.md ...> -- <target ...>" >&2
  exit 2
fi

pairfile="$(mktemp)"
trap 'rm -f "$pairfile"' EXIT

# 1단계: 룰 파일에서 쌍 추출. 나중 파일의 같은 금지어가 앞의 것을 덮어쓴다(병합 우선순위).
# shellcheck disable=SC2086
grep -h '^- .* → ' $rules | sed 's/^- //' > "$pairfile"

# 2단계: 대상 파일 검색
# shellcheck disable=SC2086
awk -v pairfile="$pairfile" '
  BEGIN {
    while ((getline l < pairfile) > 0) {
      pos = index(l, " → ")
      if (pos == 0) continue
      term = substr(l, 1, pos - 1)
      repl = substr(l, pos + length(" → "))
      # 한정어 괄호는 검색어에서 제거: 발화(이벤트가) → 발화
      sub(/\(.*\)$/, "", term)
      gsub(/^"|"$/, "", repl)
      if (term != "") terms[term] = repl
    }
    close(pairfile)
  }
  FNR == 1 { in_code = 0 }
  /^```/ { in_code = !in_code; next }
  !in_code {
    for (t in terms) {
      if (index($0, t) > 0) {
        printf "%s:%d\t%s\t%s\t%s\n", FILENAME, FNR, t, terms[t], $0
      }
    }
  }
' $targets

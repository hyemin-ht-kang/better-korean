#!/bin/sh
# 병합된 윤문 룰 파일들에서 `- 금지어 → "대체 표현"` 쌍을 파싱해,
# 대상 파일에서 금지어 히트를 찾는다. fenced code block(```/~~~, 0~3칸 들여쓰기) 내부는 제외한다.
# 출력: <파일>:<줄>	<금지어>	<대체 표현>	<해당 줄 원문>
#
# usage: grep-pass.sh <rules.md ...> -- <target ...>
# exit: 0 정상(히트 유무 무관), 2 사용법 오류 또는 읽을 수 없는 파일
set -u

seen_sep=0
nrules=0
ntargets=0
for arg in "$@"; do
  if [ "$arg" = "--" ]; then
    seen_sep=1
    continue
  fi
  if [ ! -r "$arg" ]; then
    echo "grep-pass.sh: cannot read file: $arg" >&2
    exit 2
  fi
  if [ "$seen_sep" -eq 0 ]; then
    nrules=$((nrules + 1))
  else
    ntargets=$((ntargets + 1))
  fi
done

if [ "$seen_sep" -eq 0 ] || [ "$nrules" -eq 0 ] || [ "$ntargets" -eq 0 ]; then
  echo "usage: $0 <rules.md ...> -- <target ...>" >&2
  exit 2
fi

# 단일 awk 로 처리해 파일명의 공백·glob 문자를 보존한다.
# 인자 목록을 `is_rule=1 <룰 파일...> is_rule=0 <대상 파일...>` 로 재구성해 awk 에 넘긴다.
# "=" 가 든 파일명은 awk 가 변수 대입으로 오해하지 않도록 "./" 를 앞에 붙인다.
n=$#
set -- "$@" is_rule=1
i=0
while [ "$i" -lt "$n" ]; do
  arg=$1
  shift
  if [ "$arg" = "--" ]; then
    set -- "$@" is_rule=0
  else
    case $arg in
      /*) ;;
      *=*) arg="./$arg" ;;
    esac
    set -- "$@" "$arg"
  fi
  i=$((i + 1))
done

# 룰 파싱: 나중 파일의 같은 금지어가 앞의 것을 덮어쓴다(병합 우선순위).
awk '
  FNR == 1 { in_code = 0 }
  is_rule {
    if ($0 ~ /^- .* → /) {
      l = $0
      sub(/^- /, "", l)
      pos = index(l, " → ")
      term = substr(l, 1, pos - 1)
      repl = substr(l, pos + length(" → "))
      # 한정어 괄호는 검색어에서 제거: 발화(이벤트가) → 발화, 낡(다: 낡는다) → 낡
      sub(/\(.*\)$/, "", term)
      sub(/[ \t]+$/, "", term)
      sub(/^[ \t]+/, "", term)
      if (repl ~ /^"/) {
        # 따옴표로 시작하면 닫는 따옴표까지가 대체 표현, 뒤는 설명
        repl = substr(repl, 2)
        q = index(repl, "\"")
        if (q > 0) repl = substr(repl, 1, q - 1)
      }
      if (term != "") terms[term] = repl
    }
    next
  }
  # 대상 파일: fenced code block 상태기 (0~3칸 들여쓰기, ``` 또는 ~~~, 여는 길이 이상으로 닫힘)
  {
    if (match($0, /^ {0,3}(```+|~~~+)/)) {
      fence = substr($0, RSTART, RLENGTH)
      sub(/^ +/, "", fence)
      ch = substr(fence, 1, 1)
      len = length(fence)
      if (!in_code) {
        in_code = 1; fence_ch = ch; fence_len = len
        next
      } else if (ch == fence_ch && len >= fence_len) {
        rest = substr($0, RSTART + RLENGTH)
        if (rest ~ /^[ \t]*$/) { in_code = 0; next }
      }
    }
    if (in_code) next
    for (t in terms) {
      if (index($0, t) > 0) {
        printf "%s:%d\t%s\t%s\t%s\n", FILENAME, FNR, t, terms[t], $0
      }
    }
  }
' "$@"

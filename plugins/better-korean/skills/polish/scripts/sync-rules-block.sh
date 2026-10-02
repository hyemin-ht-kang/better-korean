#!/bin/sh
# 요약 룰 파일들을 이어 붙여 지침 파일(CLAUDE.md 또는 AGENTS.md) 안의 마커 블록을 갱신한다.
# 블록이 이미 있으면 그 자리를 교체하고, 없으면 파일 끝에 덧붙이며, 대상 파일이 없으면 새로 만든다.
# 블록 밖의 내용은 바꾸지 않는다.
#
# usage: sync-rules-block.sh <CLAUDE.md|AGENTS.md> <summary.md ...>
# exit: 0 정상, 2 사용법 오류 또는 읽을 수 없는 파일
#
# 블록 머리 주석에 입력 파일 목록을 기록한다. 플러그인 내장 요약본(스킬 디렉토리의 summary-rules.md)은
# 설치 경로가 버전마다 바뀌므로 경로 대신 `builtin` 으로 적고, 다시 생성할 때 스킬이 자기 디렉토리의
# summary-rules.md 로 치환한다.
#
# 갱신 뒤 결과 파일 크기를 출력하고, 대상이 어느 파일이든 Codex 가 프로젝트 지침으로 읽는 기본 상한
# (project_doc_max_bytes, 32 KiB) 을 넘으면 경고한다. 상한은 글로벌 AGENTS.md 와
# 레포 AGENTS.md 의 합산에 적용되므로, 경고가 없어도 두 파일에 같은 블록을 두면 넘칠 수 있다.
# 병합된 요약본이 SUMMARY_LIMIT 자를 넘으면 요약본이 너무 길다고 경고한다.
set -u

BEGIN_MARK='<!-- better-korean:begin -->'
END_MARK='<!-- better-korean:end -->'
LIMIT=32768
SUMMARY_LIMIT=2500

if [ "$#" -lt 2 ]; then
  echo "usage: $0 <CLAUDE.md|AGENTS.md> <summary.md ...>" >&2
  exit 2
fi

target=$1
shift
for f in "$@"; do
  if [ ! -r "$f" ]; then
    echo "sync-rules-block.sh: cannot read file: $f" >&2
    exit 2
  fi
done

tmp_block=$(mktemp) || exit 2
tmp_out=$(mktemp) || { rm -f "$tmp_block"; exit 2; }
trap 'rm -f "$tmp_block" "$tmp_out"' EXIT

sources=""
for f in "$@"; do
  case $f in
    */skills/polish/summary-rules.md) name=builtin ;;
    *) name=$f ;;
  esac
  if [ -z "$sources" ]; then sources=$name; else sources="$sources, $name"; fi
done

{
  echo "$BEGIN_MARK"
  echo "<!-- 이 블록은 better-korean 의 sync-rules-block.sh 가 생성한다. 손으로 고치지 말고 요약 룰 파일을 고친 뒤 다시 실행한다. -->"
  echo "<!-- better-korean:sources: $sources -->"
  first=1
  for f in "$@"; do
    [ "$first" -eq 1 ] || echo
    first=0
    cat "$f"
  done
  echo "$END_MARK"
} > "$tmp_block"

if [ -f "$target" ] && grep -qF "$BEGIN_MARK" "$target"; then
  if ! grep -qF "$END_MARK" "$target"; then
    echo "sync-rules-block.sh: begin marker without end marker in $target" >&2
    exit 2
  fi
  awk -v begin="$BEGIN_MARK" -v end="$END_MARK" -v block="$tmp_block" '
    $0 == begin { while ((getline line < block) > 0) print line; skipping = 1; next }
    $0 == end && skipping { skipping = 0; next }
    !skipping { print }
  ' "$target" > "$tmp_out"
else
  if [ -f "$target" ]; then
    cat "$target" > "$tmp_out"
    # 기존 내용이 개행으로 끝나지 않으면 보정하고, 블록 앞에 빈 줄을 하나 둔다.
    if [ -s "$tmp_out" ] && [ "$(tail -c 1 "$tmp_out" | od -An -c | tr -d ' ')" != '\n' ]; then
      echo >> "$tmp_out"
    fi
    [ -s "$tmp_out" ] && echo >> "$tmp_out"
  fi
  cat "$tmp_block" >> "$tmp_out"
fi

cat "$tmp_out" > "$target"
size=$(wc -c < "$target" | tr -d ' ')
summary_chars=$(cat "$@" | wc -m | tr -d ' ')
echo "updated: $target ($size bytes; summary $summary_chars chars from: $sources)"
if [ "$summary_chars" -gt "$SUMMARY_LIMIT" ]; then
  echo "warning: merged summary is $summary_chars chars, over $SUMMARY_LIMIT; trim the summary files before adding more" >&2
fi
if [ "$size" -gt "$LIMIT" ]; then
  echo "warning: $target is larger than $LIMIT bytes; Codex stops reading project instructions past project_doc_max_bytes" >&2
fi
exit 0

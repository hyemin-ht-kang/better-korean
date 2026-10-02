#!/bin/sh
# 세션 시작 훅. 지침 파일(CLAUDE.md/AGENTS.md)에 better-korean 요약 블록이 있고 그 블록의 버전이
# 설치된 플러그인 버전과 다르면, 블록이 구버전이라는 안내 한 줄을 stdout 에 내어 세션 컨텍스트에 넣는다.
# 블록이 없거나 버전이 같으면 아무것도 출력하지 않는다.
#
# Claude Code 와 Codex 모두 훅 명령을 세션 작업 디렉토리에서 실행하고 CLAUDE_PLUGIN_ROOT 를 넘겨 준다.
set -u

script_dir=$(cd "$(dirname "$0")" && pwd)
plugin_root=${CLAUDE_PLUGIN_ROOT:-$(cd "$script_dir/../../.." && pwd)}
installed=$(sed -n 's/^[[:space:]]*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$plugin_root/.claude-plugin/plugin.json" 2>/dev/null | head -1)
[ -n "$installed" ] || exit 0

for f in "$HOME/.claude/CLAUDE.md" "$PWD/CLAUDE.md" "$HOME/.codex/AGENTS.md" "$PWD/AGENTS.md"; do
  [ -f "$f" ] || continue
  grep -qF '<!-- better-korean:begin -->' "$f" || continue
  block_version=$(sed -n 's/^[[:space:]]*<!-- better-korean:version: \(.*\) -->[[:space:]]*$/\1/p' "$f" | head -1)
  [ -n "$block_version" ] || block_version="0.3.2 이전"
  if [ "$block_version" != "$installed" ]; then
    echo "better-korean: $f 의 요약 룰 블록은 플러그인 $block_version 기준이고 설치된 버전은 $installed 입니다. polish 스킬을 실행하면 블록 갱신 여부를 묻습니다."
  fi
done
exit 0

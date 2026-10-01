# 레포 작업 지침

## 구조

- 이 레포는 Claude Code 와 Codex 에 같이 설치되는 플러그인 하나를 배포한다.
- 구현은 `plugins/better-korean/skills/polish/` 에 있다. `SKILL.md` 가 검증 절차, `default-rules.md` 가 전체 룰, `summary-rules.md` 가 작성 시점 주입용 요약, `scripts/` 가 grep 검색과 지침 파일 블록 갱신 스크립트다.
- `.claude-plugin/marketplace.json` 과 `.agents/plugins/marketplace.json` 은 둘 다 `plugins/better-korean/` 을 가리킨다.
- 루트의 README, examples 는 설치본에 들어가지 않는다.

## 변경 규칙

- `SKILL.md`, 룰 파일, 스크립트는 두 클라이언트가 공유하는 동작이다. 플랫폼이 요구하지 않는 한 클라이언트별 분기를 두지 않는다.
- `plugins/better-korean/.claude-plugin/plugin.json` 과 `plugins/better-korean/.codex-plugin/plugin.json` 의 `version` 은 항상 같게 유지한다.
- 마켓플레이스 매니페스트는 플러그인 위치나 마켓플레이스 메타데이터가 바뀔 때만 수정한다. 구현이나 버전만 바뀌는 변경에서는 손대지 않는다.
- `default-rules.md` 의 룰을 바꾸면 그 룰이 글을 쓰는 시점에 알아야 할 원칙인지 판단해 `summary-rules.md` 에도 반영한다. 금지어 한 단어 추가는 요약에 넣지 않는다.
- 룰 파일과 요약본은 금지어를 이름으로 부르는 글이라 grep 검색에 걸린다. 레포 문서를 검증할 때 이 파일들은 대상에서 뺀다.
- 레포의 한국어 문서(README, 룰 파일 본문, 주석)는 `default-rules.md` 의 룰을 따른다.

## 검증

변경과 관련된 것을 실행한다.

```sh
python3 -m json.tool plugins/better-korean/.claude-plugin/plugin.json
python3 -m json.tool plugins/better-korean/.codex-plugin/plugin.json
python3 -m json.tool .claude-plugin/marketplace.json
python3 -m json.tool .agents/plugins/marketplace.json
sh plugins/better-korean/skills/polish/scripts/grep-pass.sh plugins/better-korean/skills/polish/default-rules.md -- README.md
git diff --check
```

## 배포

- Git 레포 자체가 마켓플레이스 소스다. 별도 패키지 배포 단계는 없다.
- 릴리스는 두 plugin.json 의 `version` 을 함께 올리고, 위 검증을 돌린 뒤 커밋해 push 한다. 태그와 GitHub Release 는 요청이 있을 때만 만든다.

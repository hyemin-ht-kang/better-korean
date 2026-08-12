# korean-polishing

한국어 윤문 룰 기반 텍스트 검증 Claude Code 플러그인. 압축 조어, 은유로 압축한 설계 문장, 명사 나열식 직역투, 발음만 한글로 옮겨 적은 영어 표기를 찾아 수정을 제안한다.

한국어 산출물(문서, 테이블·컬럼 comment, 분석 보고서, PR 본문)은 사람과 후속 AI 에이전트가 그대로 활용하는 자산이다. 문장이 어색하거나 부정확하면 읽는 쪽이 의미를 잘못 특정하고, AI 에이전트가 소비하는 경우 오류가 후속 산출물로 전파된다. 이 플러그인의 기준은 하나다: 처음 읽는 사람과 AI 에이전트가 문장만 보고 의미를 특정할 수 있어야 한다.

## 설치

```sh
claude plugin marketplace add <이 레포 URL>
claude plugin install korean-polishing
```

프로젝트 레벨로 설치를 제안하려면 대상 레포의 `.claude/settings.json` 에 marketplace 와 플러그인을 등록한다.

## 사용

- `/polish-ko <path>` — 파일 하나를 검증
- `/polish-ko` — 현재 `git diff` 의 추가된 텍스트만 검증
- 문서·PR 본문을 작성한 직후에는 스킬이 셀프 체크로도 동작한다
- CI: `examples/pr-review.yml` 을 레포에 복사하면 PR 마다 인라인 suggestion + 요약을 하나의 리뷰 세션으로 달아준다 (non-blocking)

## 룰 구조

- **표준 룰**: `skills/polish-ko/default-rules.md` — 이 플러그인이 제공하는 원본. 설치만 하면 이 룰로 검증된다.
- **프로젝트 룰**: `<repo>/.claude/korean-polishing-rules.md` — 팀 공유 추가분. 있으면 표준 룰에 병합된다.
- **개인 룰**: `~/.claude/korean-polishing-rules.md` — 개인 추가분. 있으면 병합된다 (프로젝트 룰이 더 우선).

병합은 합집합이고, 같은 항목이 충돌하면 프로젝트 > 개인 > 표준 순으로 이긴다. 프로젝트에서 특정 금지어를 허용하고 싶으면 프로젝트 룰 파일에 예외로 선언한다.

프로젝트 CLAUDE.md 가 룰 파일을 import(`@.claude/korean-polishing-rules.md`)하면 세션 주입과 가시성을 함께 얻는다 — 권장 구성이다.

## 룰 최신화가 운영의 핵심이다

룰 파일은 `.claude/` 하위에 있어 눈에 덜 띄고 갱신을 잊기 쉽다. 그래서 스킬이 최신화를 챙긴다: 세션 중 사용자가 표현을 정정하면 "이 항목을 룰 리스트에 추가할까요?"라고 묻고, 프로젝트 룰 또는 개인 룰에 추가한다.

표준 룰의 확장은 maintainer 의 운영이다: 개인 룰 파일에 쌓인 항목을 주기적으로 `default-rules.md` 로 옮겨 배포하고, 배포된 항목은 개인 파일에서 지운다.

## 구조

```
korean-polishing/
├── .claude-plugin/plugin.json
├── skills/
│   └── polish-ko/
│       ├── SKILL.md         # 검증 절차 (룰 본문 없음)
│       └── default-rules.md # 표준 룰 원본
├── scripts/
│   └── grep-pass.sh         # 금지어 쌍을 파싱해 기계 검색하는 스크립트
└── examples/
    └── pr-review.yml        # PR 리뷰 워크플로 템플릿
```

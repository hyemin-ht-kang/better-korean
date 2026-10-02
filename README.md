# better-korean

**Make AI-written Korean actually Korean.**

AI 가 쓴 한국어 IT·기술 문서에 흔히 남는 어색하고 장황한 말투를 사람이 실제로 쓰는 자연스러운 표현으로 고치는 플러그인입니다. 아래 예시처럼 읽는 흐름을 방해하는 AI 어투를 찾아, 풀어 쓴 대체 표현을 제시합니다.

- 영어 단어를 직역해서 한자어 하나로 축약한 조어
- 실제 작동 방식을 설명하지 않는 의인화/은유 표현
- 동사 없이 명사만 연속적으로 늘어놓은 직역투
- 뜻이 통하지 않게 발음만 한글로 옮겨 적은 영어 표기

문서와 테이블 comment, 분석 보고서, PR 본문은 사람만 읽는 글이 아니라 후속 AI 에이전트가 읽고 그대로 활용하는 데이터 자산이므로, 문장이 어색하거나 부정확하면 그 문장을 읽은 에이전트가 의미를 잘못 이해한 채 작업을 이어가고 그 오류가 다음 산출물로 이어집니다. 그래서 이 플러그인은 처음 읽는 사람과 AI 에이전트가 문장만 보고 의미를 특정할 수 있는지를 기준으로 검증하도록 설계되어 있습니다.

기본적으로는 IT·기술 문서를 기준으로 만들어져 있어서, 다른 분야에서는 정상 용어인 단어가 금지어에 들어 있을 수 있는데, 그런 단어는 프로젝트 룰 파일에 예외로 선언해 허용할 수 있습니다.

## 설치

마켓플레이스를 등록한 다음 플러그인을 설치합니다.

### Claude Code

```sh
claude plugin marketplace add hyemin-ht-kang/better-korean
claude plugin install better-korean@hmk-tools
```

Claude Code 세션 안에서는 슬래시 커맨드로도 같은 일을 할 수 있습니다.

```
/plugin marketplace add hyemin-ht-kang/better-korean
/plugin install better-korean@hmk-tools
```

설치가 끝나면 `/better-korean:polish` 를 쓸 수 있습니다.

### Codex

```sh
codex plugin marketplace add hyemin-ht-kang/better-korean
codex plugin add better-korean@hmk-tools
```

설치 뒤 새 스레드를 열면 `$polish` 를 쓸 수 있습니다. 플러그인 없이 스킬만 쓰려면 `plugins/better-korean/skills/polish/` 를 `~/.agents/skills/polish/`(개인) 또는 `<레포>/.agents/skills/polish/`(프로젝트)에 복사해도 됩니다.

### 팀 전체가 쓰게 하려면

대상 레포의 `.claude/settings.json` 에 마켓플레이스와 플러그인을 함께 적어 두면, 팀원은 레포를 clone 해서 프로젝트를 신뢰할 때 설치를 안내받고 플러그인이 활성화된 상태로 시작합니다.

```json
{
  "extraKnownMarketplaces": {
    "hmk-tools": {
      "source": {
        "source": "github",
        "repo": "hyemin-ht-kang/better-korean"
      }
    }
  },
  "enabledPlugins": {
    "better-korean@hmk-tools": true
  }
}
```

두 키는 역할이 나뉘어 있어서 함께 적어야 합니다.

- `extraKnownMarketplaces`: 마켓플레이스 등록
- `enabledPlugins`: 그 안의 플러그인 활성화

## 사용

검증 대상은 파일 경로를 넘기거나 인자 없이 불러서 지정합니다. Codex 에서는 `/better-korean:polish` 대신 `$polish` 로 부릅니다.

```
/better-korean:polish <파일 경로>   # 그 파일 전체를 검증합니다
/better-korean:polish               # git diff(스테이징 포함)에서 추가된 텍스트 줄만 검증합니다
```

검증 결과는 `위치 | 검출 방식(grep/판독) | 위반 룰 | 수정 제안` 표로 보고되고, 파일 수정은 확인을 받은 뒤에 진행합니다. 확신이 낮은 항목은 버리지 않고 판단이 필요한 건으로 남기기 때문에, 최종 판정은 작성자가 내리게 됩니다.

CI 로 돌리려면 `examples/pr-review.yml` 을 대상 레포에 복사합니다. PR 마다 확정 위반은 원클릭으로 적용할 수 있는 GitHub suggestion 으로, 판단이 필요한 건은 근거를 적은 코멘트로 달리며, 이 둘과 요약이 하나의 리뷰로 묶여 제출됩니다. CI 를 실패시키지는 않습니다.

## 예시

데이터 테이블 문서에서 흔히 보이는 문장을 검증하면 아래처럼 바뀝니다. `-` 가 원문, `+` 가 스킬의 수정 제안입니다.

```diff
- `daily_user_metrics` 는 일별 그레인이라 미적재 구간이 생기면 실측값을 정본 테이블과 대조해야 한다 — 어노말리 유저는 정제가 미내장이라 DAU 에 그대로 계상된다.
+ `daily_user_metrics` 는 일별 집계 단위라, 적재되지 않은 구간이 생기면 실제 측정값을 기준 테이블과 대조해야 한다. 비정상(anomaly) 유저는 정제되어 있지 않아 DAU 에 그대로 집계된다.

- 지표 정의는 `dim_user` 의 결을 따라 준용하고, 세부 기준은 wiki 에 박아 둔 문서를 참조한다 (링크가 죽은 채 낡은 사본만 남아 있을 수 있음).
+ 지표 정의는 `dim_user` 의 기존 정의와 같은 방식으로 맞추고, 세부 기준은 wiki 에 적어 둔 문서를 참조한다 (링크가 끊어지고 갱신되지 않은 사본만 남아 있을 수 있음).

- 실패 깨움 기반 재적재 복원 로직이 돈다. 관측이 쌓이면 갱신된다. probe 쿼리로 구조적 이슈를 확인한다.
+ 적재가 실패하면 그 실패를 감지해 재적재하는 복원 로직이 돌고 유저 활동 데이터가 쌓이면 갱신되므로, 확인용 쿼리로 파티션 단위로 통째로 빠진 구간이 있는지 확인한다.
```

원문 세 문장에서 18건이 잡혔습니다. 금지어 목록으로 기계 검색한 grep 패스가 12건, 문단을 읽고 판단한 판독 패스가 6건입니다. 판독 패스가 잡은 것은 아래와 같습니다.

| 원문 | 위반 룰 | 왜 문제인가 |
|---|---|---|
| `dim_user` 의 결을 따라 | 은유로 압축한 방침 문장 | "결"이 무엇을 따르라는 건지 문장만 보고 알 수 없다 |
| 박아 둔 문서 | "박다" 계열 표현 | 구어 은유가 기술 문서에 맞지 않는다 |
| 실패 깨움 기반 재적재 복원 로직 | 명사 나열식 직역투 | 동사가 없어 무엇이 무엇을 하는지 드러나지 않는다 |
| 로직이 돈다. 관측이 쌓이면 갱신된다. ~ 확인한다. | 논리 관계가 있는 문장을 끊어 쓰지 않는다 | 인과로 이어지는 내용을 짧은 문장으로 끊어 놓아 관계가 사라진다 |
| 관측이 쌓이면 | "관측"은 대비가 핵심일 때만 | 정의된 전체 집합과 실제 데이터의 대비가 없는 자리다 |
| 구조적 이슈 | "구조적 X" 단독 서술 | 무엇의 구조가 어떻게 문제인지 드러나지 않는다 |

## 검증 방식

검증은 grep 패스와 판독 패스로 나뉩니다.

- **grep 패스**: 룰의 금지어 목록을 파싱해 기계적으로 검색하므로 목록에 있는 단어를 빠뜨리지 않고 잡아냅니다.
- **판독 패스**: 기계 검색으로 잡을 수 없는 것을 문단 단위로 판단합니다. 은유로 압축한 설계 문장, 명사만 늘어놓은 직역투, 정의 없이 등장한 새 용어, 목록에 없지만 같은 패턴인 신조어가 여기서 걸립니다.

## 룰 위치

룰은 아래 위치에서 읽어 합칩니다.

| 위치 | 성격 |
|---|---|
| `plugins/better-korean/skills/polish/default-rules.md` | 이 플러그인이 제공하는 표준 룰입니다. 설치만 하면 이 룰로 검증됩니다. |
| `~/.agents/better-korean-rules.md` | 개인이 추가한 룰입니다. 모든 프로젝트에 적용됩니다. |
| `<레포>/.agents/better-korean-rules.md` | 팀이 공유하는 프로젝트 룰입니다. |

개인·프로젝트 룰을 `.agents/` 에 두는 이유는 Claude Code 와 Codex 가 같은 파일을 읽게 하기 위해서입니다. 클라이언트마다 다른 파일을 읽으면 어느 쪽에서 쓰느냐에 따라 결과가 달라집니다. 이전 버전이 쓰던 `~/.claude/better-korean-rules.md` 와 `<레포>/.claude/better-korean-rules.md` 는 더 이상 읽지 않으며, 그 자리에 파일이 있으면 보고서 머리에 옮기라는 경고가 나옵니다.

항목은 합집합으로 합치고, 같은 항목이 충돌하면 프로젝트 룰이 개인 룰을, 개인 룰이 표준 룰을 이깁니다. 그래서 표준 룰이 금지한 단어를 특정 프로젝트에서 쓰고 싶으면 프로젝트 룰 파일에 예외로 선언하면 됩니다. 룰 파일을 새로 만들 때는 표준 룰과 같은 구조로 쓰고, 금지어는 `금지어 → "대체 표현"` 형식으로 적어야 grep 패스가 파싱할 수 있습니다.

## 글을 쓰는 시점에도 룰을 적용하려면

검증은 설치만 하면 동작하지만, 글을 쓰는 시점부터 룰이 적용되게 하려면 세션마다 룰이 지침으로 주입되어야 합니다. 이 설정은 선택 사항이고, 설치가 CLAUDE.md 나 AGENTS.md 를 자동으로 고치지는 않습니다. 스킬을 레포에서 처음 실행하면 설정할지 한 번 묻고, 동의할 때만 아래 스크립트를 실행합니다.

주입에는 전체 룰 대신 원칙만 추린 요약본(`summary-rules.md`)을 씁니다. 전체 룰은 금지어별 대체 표현까지 들어 있어 세션마다 아래만큼 컨텍스트를 씁니다.

| | Claude 토큰 | Codex 토큰 |
|---|---|---|
| 요약본 | 약 1,600 | 약 1,000 |
| 전체 룰 | 약 9,000 | 약 5,800 |

요약본은 각 제품별 에이전트 지침 파일 안의 생성 블록으로 넣습니다.

```sh
# Claude Code: 프로젝트 CLAUDE.md 또는 ~/.claude/CLAUDE.md
sh <스킬 디렉토리>/scripts/sync-rules-block.sh CLAUDE.md <스킬 디렉토리>/summary-rules.md

# Codex: 레포 AGENTS.md 또는 ~/.codex/AGENTS.md
sh <스킬 디렉토리>/scripts/sync-rules-block.sh AGENTS.md <스킬 디렉토리>/summary-rules.md
```

스크립트는 `<!-- better-korean:begin -->` 과 `<!-- better-korean:end -->` 사이만 갈아 끼우고 블록 밖은 건드리지 않습니다. 블록 머리에는 만든 플러그인 버전과 입력 파일 목록이 기록됩니다. 플러그인을 업데이트하면 세션 시작 훅이 블록 버전과 설치 버전을 비교해 다를 때 안내를 띄우고, `polish` 를 실행하면 갱신 여부를 묻습니다. Codex 는 플러그인에 번들된 훅을 사용자가 검토해 신뢰한 뒤에만 실행하므로, 설치 후 Codex 가 훅 신뢰를 물으면 승인해야 안내가 동작합니다. 개인·프로젝트에서 요약에 더 넣을 원칙은 `~/.agents/better-korean-summary.md` 와 `<레포>/.agents/better-korean-summary.md` 에 적고 스크립트 인자로 뒤에 붙입니다. Codex 는 글로벌과 레포 AGENTS.md 를 합쳐 기본 32 KiB 까지만 읽으므로 블록은 한쪽에만 두고, 스크립트가 출력하는 크기 경고를 확인합니다.

## 플러그인을 사용하시면서 룰을 계속 추가해보세요

어색한 표현은 실제 문서를 쓰고 읽는 과정에서 발견되므로, 룰 목록은 쓰면서 늘려 갈수록 더 유용해집니다. 룰 파일이 `.agents/` 하위에 있어 눈에 덜 띄고 갱신을 잊기 쉬우므로, 스킬을 써서 넣도록 할 수 있습니다. 세션 중에 표현을 정정하면 그 항목을 룰에 추가할지 묻고, 개인 룰과 프로젝트 룰 중 어디에 넣을지 함께 제안합니다. 지침 파일에 요약 룰 블록을 넣어 둔 경우에는 요약본에도 반영할지 같이 묻고, 동의하면 룰 추가와 블록 갱신을 한 번에 합니다. 요약본은 세션마다 주입되므로 범주당 예시 하나, 쓰는 시점에 꼭 피하고 싶은 단어는 `자주 쓰는 금지어` 한 줄(10개 상한)이라는 형식으로 길이를 묶어 둡니다.

## 구조

두 클라이언트가 같은 디렉토리를 설치하고, 매니페스트만 다릅니다.

```
better-korean/
├── .claude-plugin/marketplace.json     # Claude Code 마켓플레이스 목록
├── .agents/plugins/marketplace.json    # Codex 마켓플레이스 목록
├── plugins/better-korean/              # 두 목록이 가리키는 설치 대상
│   ├── .claude-plugin/plugin.json      # Claude Code 플러그인 매니페스트
│   ├── .codex-plugin/plugin.json       # Codex 플러그인 매니페스트
│   ├── hooks/hooks.json                # 세션 시작 훅 (요약 블록 버전 안내)
│   └── skills/polish/
│       ├── SKILL.md                    # 검증 절차 (룰 본문은 두지 않습니다)
│       ├── default-rules.md            # 표준 룰 원본
│       ├── summary-rules.md            # 글을 쓰는 시점에 주입하는 요약
│       └── scripts/
│           ├── grep-pass.sh            # 금지어 쌍을 파싱해 기계 검색
│           ├── sync-rules-block.sh     # 지침 파일의 요약 블록 갱신
│           └── check-rules-block.sh    # 블록 버전과 설치 버전 비교
└── examples/
    └── pr-review.yml                   # PR 리뷰 워크플로 템플릿
```

## 관리자용 안내

표준 룰을 확장하는 것은 관리자가 하는 일입니다. 개인 룰 파일에 쌓인 항목 중 여러 프로젝트에 공통으로 적용할 만한 것을 `default-rules.md` 로 옮기고, `.claude-plugin/plugin.json` 과 `.codex-plugin/plugin.json` 의 `version` 을 같은 값으로 올려 배포합니다. 사용자는 이 값이 바뀔 때 업데이트를 받습니다.

사용자가 새 버전을 받으려면 마켓플레이스를 갱신한 뒤 플러그인을 업데이트합니다.

```sh
# Claude Code
claude plugin marketplace update hmk-tools
claude plugin update better-korean@hmk-tools

# Codex
codex plugin marketplace upgrade hmk-tools
codex plugin add better-korean@hmk-tools
```

버전별 변경 내용은 [Releases 페이지](https://github.com/hyemin-ht-kang/better-korean/releases)에서 확인할 수 있습니다.

## 라이선스

[MIT](LICENSE)

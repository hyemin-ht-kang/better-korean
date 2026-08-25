# better-korean

**Make AI-written Korean actually Korean.**

AI 가 쓴 한국어 문서에 흔히 남는 어색하고 장황한 말투를 사람이 실제로 쓰는 자연스러운 표현으로 고치는 Claude Code 플러그인입니다. 서술을 한자어 명사 하나에 눌러 담은 압축 조어, 실제 메커니즘을 가리는 은유 문장, 동사 없이 명사만 늘어놓은 직역투, 뜻이 통하지 않게 발음만 한글로 옮겨 적은 영어 표기처럼 읽는 사람을 한 번 멈추게 만드는 표현을 찾아 풀어 쓴 대체 표현을 제시합니다.

문서와 테이블 comment, 분석 보고서, PR 본문은 사람만 읽는 글이 아니라 후속 AI 에이전트가 읽고 그대로 활용하는 데이터 자산이므로, 문장이 어색하거나 부정확하면 그 문장을 읽은 에이전트가 의미를 잘못 이해한 채 작업을 이어가고 그 오류가 다음 산출물로 이어집니다. 그래서 이 플러그인은 처음 읽는 사람과 AI 에이전트가 문장만 보고 의미를 특정할 수 있는지를 기준으로 검증합니다.

## 설치

마켓플레이스를 등록한 다음 플러그인을 설치합니다.

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

두 키는 역할이 나뉘어 있어서 함께 적어야 합니다. `extraKnownMarketplaces` 는 마켓플레이스를 등록하고, `enabledPlugins` 는 그 안의 플러그인을 활성화합니다.

## 사용

검증 대상을 지정하는 방법이 두 가지 있습니다.

```
/better-korean:polish <파일 경로>   # 그 파일 전체를 검증합니다
/better-korean:polish               # git diff(스테이징 포함)에서 추가된 텍스트 줄만 검증합니다
```

검증 결과는 `위치 | 층(grep/판독) | 위반 룰 | 수정 제안` 표로 보고되고, 파일 수정은 확인을 받은 뒤에 진행합니다. 확신이 낮은 항목은 버리지 않고 판단이 필요한 건으로 남기기 때문에, 최종 판정은 작성자가 내리게 됩니다.

문서나 PR 본문, 테이블 comment 를 작성한 직후라면 따로 부르지 않아도 스킬이 방금 만든 산출물을 스스로 점검합니다.

CI 로 돌리려면 `examples/pr-review.yml` 을 대상 레포에 복사합니다. PR 마다 확정 위반은 원클릭으로 적용할 수 있는 GitHub suggestion 으로, 판단이 필요한 건은 근거를 담은 코멘트로 달리며, 이 둘과 요약이 하나의 리뷰로 묶여 제출됩니다. CI 를 실패시키지는 않습니다.

## 검증 방식

검증은 두 단계로 나뉩니다. **grep 패스**는 룰의 금지어 목록을 파싱해 기계적으로 검색하므로 목록에 있는 단어를 빠뜨리지 않고 잡아냅니다. **판독 패스**는 기계 검색으로 잡을 수 없는 것을 문단 단위로 판단합니다. 은유로 압축한 설계 문장, 명사만 늘어놓은 직역투, 정의 없이 등장한 새 용어, 목록에 없지만 같은 패턴인 신조어가 여기서 걸립니다.

## 룰이 어디에 있고 어떻게 합쳐지는가

룰은 세 곳에서 읽어 합칩니다.

| 위치 | 성격 |
|---|---|
| `skills/polish/default-rules.md` | 이 플러그인이 제공하는 표준 룰입니다. 설치만 하면 이 룰로 검증됩니다. |
| `~/.claude/better-korean-rules.md` | 개인이 추가한 룰입니다. 모든 프로젝트에 적용됩니다. |
| `<레포>/.claude/better-korean-rules.md` | 팀이 공유하는 프로젝트 룰입니다. |

항목은 합집합으로 합치고, 같은 항목이 충돌하면 프로젝트 룰이 개인 룰을, 개인 룰이 표준 룰을 이깁니다. 그래서 표준 룰이 금지한 단어를 특정 프로젝트에서 쓰고 싶으면 프로젝트 룰 파일에 예외로 선언하면 됩니다. 룰 파일을 새로 만들 때는 표준 룰과 같은 구조로 쓰고, 금지어는 `금지어 → "대체 표현"` 형식으로 적어야 grep 패스가 파싱할 수 있습니다.

프로젝트 CLAUDE.md 가 룰 파일을 `@.claude/better-korean-rules.md` 로 import 하면, 검증할 때만 읽히는 것이 아니라 매 세션 주입되어 문서를 작성하는 시점에도 룰이 적용됩니다. 권장하는 구성입니다.

## 룰을 계속 추가해 나가는 것이 이 플러그인의 사용법입니다

룰 목록은 완성해 두고 쓰는 것이 아니라 쓰면서 늘려 가는 것입니다. 어색한 표현은 실제 문서를 쓰고 읽는 과정에서 발견되기 때문입니다. 룰 파일이 `.claude/` 하위에 있어 눈에 덜 띄고 갱신을 잊기 쉬우므로, 스킬이 이 일을 챙깁니다. 세션 중에 표현을 정정하면 그 항목을 룰에 추가할지 묻고, 개인 룰과 프로젝트 룰 중 어디에 넣을지 함께 제안합니다.

## 구조

```
better-korean/
├── .claude-plugin/
│   ├── plugin.json          # 플러그인 매니페스트
│   └── marketplace.json     # 마켓플레이스 목록
├── skills/
│   └── polish/
│       ├── SKILL.md         # 검증 절차 (룰 본문은 담지 않습니다)
│       └── default-rules.md # 표준 룰 원본
├── scripts/
│   └── grep-pass.sh         # 금지어 쌍을 파싱해 기계 검색하는 스크립트
└── examples/
    └── pr-review.yml        # PR 리뷰 워크플로 템플릿
```

## 관리자용 안내

표준 룰을 확장하는 것은 관리자가 하는 일입니다. 개인 룰 파일에 쌓인 항목 중 여러 프로젝트에 공통으로 적용할 만한 것을 `default-rules.md` 로 옮기고, `plugin.json` 의 `version` 을 올려 배포합니다. 사용자는 이 값이 바뀔 때 업데이트를 받습니다.

## 라이선스

[MIT](LICENSE)

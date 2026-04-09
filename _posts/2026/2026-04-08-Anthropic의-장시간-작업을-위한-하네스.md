---
title : "Anthropic의 장시간 작업을 위한 하네스"
date : 2026-04-08 21:40:00 +09:00
categories : [Claude, Harness]
tags : [Harness]
---

AI 코딩 에이전트에게 "이 기능 만들어줘"라고 던져놓고, 한 시간 뒤에 돌아와서 결과물을 보다가 머리를 짚어본 적이 있을 것이다. "어딘가 중간부터 길을 잃었다..." 는 생각이 뇌를 지배한다. 화면에는 절반쯤 고친 코드, 절반쯤 만든 테스트, 그리고 무엇보다 *그 다음에 뭘 해야 하는지 모르는 상태*가 있다. 이런 현상은 에이전트와의 대화가 길어졌을 때 겪을 수 있다. 컨텍스트가 커지면 압축이 일어나고, 그러면 에이전트는 처음부터 다시 파일들을 읽기 시작하기 때문에 이미 한 일을 다시 하거나 아예 다른 방향으로 가버릴 수 있다.

이 글의 출발점이 거기에 있다. — **에이전트에게 코드를 맡길 때 진짜 병목은 모델의 능력이 아니라 세션의 경계다.** — 한 세션 안에서 에이전트가 얼마나 똑똑한지보다, 세션과 세션 사이에 무엇이 살아남는지가 작업의 성패를 가른다. Anthropic의 한 엔지니어링 글이 이 문제를 다루는데, 백엔드 개발자에게는 이 글이 낯설지 않은 느낌으로 다가온다. — 코드 핸드오프, 교대 인수인계, PR 제출. — 우리가 이미 동료들과 경험했던 문제들이다. 단지 상대가 사람이 아닐 뿐이다.

이 글에서는 그 병목을 해소하는 틀(**harness**)이 무엇인지 알아보고, 다른 방법들과는 어떻게 다른지를 정리해본다.

## 1. Summary — Anthropic이 제안하는 harness의 골격

[원문](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)은 크게 세 가지 가이드라인으로 요약된다. 두 개의 프롬프트, 네 개의 artifact, 그리고 모든 코딩 세션이 따라야 하는 7단계 workflow.

**두 종류의 첫 프롬프트.** 원문이 강조하는 것은 이게 두 개의 다른 agent가 아니라는 점이다. System prompt도, tool set도, harness도 모두 동일하다. 다른 것은 첫 user prompt 단 하나뿐이다. 그럼에도 이 한 가지 차이로 두 가지 역할이 만들어진다. Initializer 역할은 프로젝트의 뼈대를 깐다 — 요구사항을 feature 단위로 쪼개고, 테스트 전략을 정하고, 작업 목록 파일을 만든다. 첫 세션에 한 번만 돈다. Coding 역할은 그 뼈대 위에서 실제 기능을 하나씩 구현한다. 세션마다 반복해서 돈다.

**네 개의 artifact.** Harness가 유지되는 것은 모델의 기억력 덕분이 아니라, 세션 밖에 쌓이는 네 개의 파일 덕분이다.

- **feature_list.json** — 할 일 목록. 반드시 JSON이다. 원문은 이 규칙을 강하게 못박는데, 이유가 흥미롭다. Markdown 체크리스트는 사람이 보기엔 예쁘지만, 에이전트가 "이 항목이 끝났는지" 판단할 때마다 자연어를 다시 해석해야 한다. JSON의 `passes: true/false` 같은 boolean 필드는 해석 비용이 0에 가깝다. 작은 차이 같지만, 세션이 길어질수록 이 차이가 context window 효율을 바꾼다.
- **init.sh** — 세션을 시작할 때마다 실행되는 스크립트. 저장소 상태를 점검하고, 빌드가 되는지 확인하고, 테스트가 돌아가는지 확인한다. "이전 세션이 멀쩡한 상태로 끝났는가?"를 사람 대신 묻는 관문이다.
- **claude-progress.txt** — 원문 표현으로는 "log of what agents have done", 즉 이전 세션들이 무엇을 했는지가 적히는 파일이다. 다음 세션의 첫 작업은 git log와 함께 이 파일을 읽는 것이다. 원문은 이 파일이 정확히 무엇을 담아야 하는지 schema 수준으로 못박지는 않는데, 실제로 굴려보면 "이번에 한 일 / 알려진 이슈 / 다음에 이어야 할 자리" 정도가 자연스럽게 자리잡는다.
- **Git 저장소** — 위 세 파일이 흩어지지 않게 묶어두는 바인더. 모든 세션의 끝에서 commit이 강제된다. commit은 곧 체크포인트다.

**세션 절차.** 원문은 coding 세션이 어떻게 시작되어야 하는지에 대해 구체적으로 세 단계를 명시한다. (1) `pwd`로 작업 디렉토리 확인, (2) progress 파일과 git log 읽기, (3) feature 목록에서 다음 작업 고르기. 그리고 끝나는 쪽에 대해서는 별도의 단계 명명 없이 "git commit과 progress 파일 갱신으로 세션을 닫는다", "feature는 충분한 검증 후에만 passing으로 표시한다" 같은 식으로 규칙을 정해준다.

**7단계 workflow.** 세션의 전체 흐름을 정리하면 대략 7단계가 된다. 이 7단계 명명은 원문에 그대로 등장하는 것이 아니라 내가 글을 위해 묶은 것임을 미리 밝혀둔다. — Orient(progress와 git log 읽기) → Verify(init.sh로 환경 점검) → Select(다음 feature 고르기) → Implement → Test end-to-end → Commit/Document → Leave merge-ready. 이렇게 정리하면 4장에서 다른 도구들과 비교하기가 쉬워진다.

<svg width="100%" viewBox="0 0 680 620" role="img" xmlns="http://www.w3.org/2000/svg">
<title style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">7단계 workflow와 4개 artifact의 관계</title>
<desc style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">Orient부터 Leave merge-ready까지의 원형 루프와 각 단계에서 읽고 쓰는 feature_list.json, init.sh, claude-progress.txt, git 저장소</desc>
<defs>
<marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
<path d="M2 1L8 5L2 9" fill="none" stroke="context-stroke" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</marker>
<mask id="imagine-text-gaps-lymlai" maskUnits="userSpaceOnUse"><rect x="0" y="0" width="680" height="620" fill="white"/><rect x="269.58941650390625" y="13.83324909210205" width="140.82115173339844" height="21.944551467895508" fill="black" rx="2"/><rect x="237.2262725830078" y="31.833248138427734" width="205.54747009277344" height="21.944551467895508" fill="black" rx="2"/><rect x="308.5086364746094" y="89.02772521972656" width="62.98273468017578" height="21.944551467895508" fill="black" rx="2"/><rect x="278.8843994140625" y="107.02772521972656" width="122.23123168945312" height="21.944551467895508" fill="black" rx="2"/><rect x="528.2725219726562" y="151.02772521972656" width="64.17903518676758" height="21.944551467895508" fill="black" rx="2"/><rect x="526.5016479492188" y="169.02772521972656" width="66.99664688110352" height="21.944551467895508" fill="black" rx="2"/><rect x="547.7373046875" y="273.0277099609375" width="64.52533340454102" height="21.944551467895508" fill="black" rx="2"/><rect x="525.0548095703125" y="291.0277099609375" width="109.89041900634766" height="21.944551467895508" fill="black" rx="2"/><rect x="452.69696044921875" y="395.0277099609375" width="94.60606384277344" height="21.944551467895508" fill="black" rx="2"/><rect x="472.6563415527344" y="413.0277099609375" width="54.687313079833984" height="21.944551467895508" fill="black" rx="2"/><rect x="300.5201721191406" y="451.0277099609375" width="78.95967864990234" height="21.944551467895508" fill="black" rx="2"/><rect x="291.9020690917969" y="469.0277099609375" width="96.19589233398438" height="21.944551467895508" fill="black" rx="2"/><rect x="142.18081665039062" y="395.0277099609375" width="75.63836669921875" height="21.944551467895508" fill="black" rx="2"/><rect x="114.689453125" y="413.0277099609375" width="130.62109375" height="21.944551467895508" fill="black" rx="2"/><rect x="69.46095275878906" y="273.0277099609375" width="61.70772171020508" height="21.944551467895508" fill="black" rx="2"/><rect x="42.008941650390625" y="291.0277099609375" width="115.98212432861328" height="21.944551467895508" fill="black" rx="2"/><rect x="166" y="163.833251953125" width="54.687313079833984" height="21.944551467895508" fill="black" rx="2"/><rect x="286.82562255859375" y="201.833251953125" width="106.34872436523438" height="21.944551467895508" fill="black" rx="2"/><rect x="290.6664123535156" y="231.44439697265625" width="98.66720581054688" height="21.00010108947754" fill="black" rx="2"/><rect x="318.8110046386719" y="263.44439697265625" width="42.37798309326172" height="19.1112003326416" fill="black" rx="2"/><rect x="280.6316223144531" y="295.44439697265625" width="118.73676300048828" height="19.1112003326416" fill="black" rx="2"/><rect x="310.72808837890625" y="326.0277099609375" width="58.54381561279297" height="21.944551467895508" fill="black" rx="2"/><rect x="-4" y="-16.16675090789795" width="30.068649291992188" height="21.944551467895508" fill="black" rx="2"/><rect x="26" y="3.833249568939209" width="67.92535400390625" height="21.944551467895508" fill="black" rx="2"/><rect x="146" y="3.833249568939209" width="71.87630081176758" height="21.944551467895508" fill="black" rx="2"/><rect x="266" y="3.833249568939209" width="54.687313079833984" height="21.944551467895508" fill="black" rx="2"/></mask></defs>

<text x="340" y="30" text-anchor="middle" style="fill:rgb(20, 20, 19);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:auto">Coding session loop</text>
<text x="340" y="48" text-anchor="middle" style="fill:rgb(61, 61, 58);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:auto">세션마다 반복되는 7단계 + 4개 artifact</text>

<!-- Step 1: Orient (top) -->
<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="270" y="78" width="140" height="56" rx="8" stroke-width="0.5" style="fill:rgb(238, 237, 254);stroke:rgb(83, 74, 183);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="340" y="100" text-anchor="middle" dominant-baseline="central" style="fill:rgb(60, 52, 137);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">1. Orient</text>
<text x="340" y="118" text-anchor="middle" dominant-baseline="central" style="fill:rgb(83, 74, 183);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">progress, git log 읽기</text>
</g>

<!-- Step 2: Verify (top-right) -->
<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="490" y="140" width="140" height="56" rx="8" stroke-width="0.5" style="fill:rgb(238, 237, 254);stroke:rgb(83, 74, 183);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="560" y="162" text-anchor="middle" dominant-baseline="central" style="fill:rgb(60, 52, 137);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">2. Verify</text>
<text x="560" y="180" text-anchor="middle" dominant-baseline="central" style="fill:rgb(83, 74, 183);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">init.sh 실행</text>
</g>

<!-- Step 3: Select (right) -->
<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="510" y="262" width="140" height="56" rx="8" stroke-width="0.5" style="fill:rgb(238, 237, 254);stroke:rgb(83, 74, 183);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="580" y="284" text-anchor="middle" dominant-baseline="central" style="fill:rgb(60, 52, 137);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">3. Select</text>
<text x="580" y="302" text-anchor="middle" dominant-baseline="central" style="fill:rgb(83, 74, 183);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">다음 feature 고르기</text>
</g>

<!-- Step 4: Implement (bottom-right) -->
<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="430" y="384" width="140" height="56" rx="8" stroke-width="0.5" style="fill:rgb(225, 245, 238);stroke:rgb(15, 110, 86);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="500" y="406" text-anchor="middle" dominant-baseline="central" style="fill:rgb(8, 80, 65);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">4. Implement</text>
<text x="500" y="424" text-anchor="middle" dominant-baseline="central" style="fill:rgb(15, 110, 86);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">기능 구현</text>
</g>

<!-- Step 5: Test E2E (bottom) -->
<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="270" y="440" width="140" height="56" rx="8" stroke-width="0.5" style="fill:rgb(225, 245, 238);stroke:rgb(15, 110, 86);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="340" y="462" text-anchor="middle" dominant-baseline="central" style="fill:rgb(8, 80, 65);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">5. Test E2E</text>
<text x="340" y="480" text-anchor="middle" dominant-baseline="central" style="fill:rgb(15, 110, 86);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">end-to-end 검증</text>
</g>

<!-- Step 6: Commit/Document (bottom-left) -->
<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="110" y="384" width="140" height="56" rx="8" stroke-width="0.5" style="fill:rgb(250, 236, 231);stroke:rgb(153, 60, 29);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="180" y="406" text-anchor="middle" dominant-baseline="central" style="fill:rgb(113, 43, 19);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">6. Commit</text>
<text x="180" y="424" text-anchor="middle" dominant-baseline="central" style="fill:rgb(153, 60, 29);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">progress 갱신, commit</text>
</g>

<!-- Step 7: Leave merge-ready (left) -->
<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="30" y="262" width="140" height="56" rx="8" stroke-width="0.5" style="fill:rgb(250, 236, 231);stroke:rgb(153, 60, 29);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="100" y="284" text-anchor="middle" dominant-baseline="central" style="fill:rgb(113, 43, 19);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">7. Leave</text>
<text x="100" y="302" text-anchor="middle" dominant-baseline="central" style="fill:rgb(153, 60, 29);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">merge-ready 상태로</text>
</g>

<!-- Loop arrows between steps -->
<path d="M 410 106 Q 480 110 515 140" fill="none" stroke="#5F5E5A" stroke-width="0.8" marker-end="url(#arrow)" style="fill:none;stroke:rgb(95, 94, 90);color:rgb(0, 0, 0);stroke-width:0.8px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<path d="M 580 196 Q 595 230 585 262" fill="none" stroke="#5F5E5A" stroke-width="0.8" marker-end="url(#arrow)" style="fill:none;stroke:rgb(95, 94, 90);color:rgb(0, 0, 0);stroke-width:0.8px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<path d="M 575 318 Q 555 360 525 384" fill="none" stroke="#5F5E5A" stroke-width="0.8" marker-end="url(#arrow)" style="fill:none;stroke:rgb(95, 94, 90);color:rgb(0, 0, 0);stroke-width:0.8px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<!-- Implement -> Test E2E (smooth curve) -->
<path d="M 450 440 Q 420 470 410 468" fill="none" stroke="#5F5E5A" stroke-width="0.8" marker-end="url(#arrow)" style="fill:none;stroke:rgb(95, 94, 90);color:rgb(0, 0, 0);stroke-width:0.8px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<!-- Test E2E -> Commit (smooth curve) -->
<path d="M 270 468 Q 260 470 250 440" fill="none" stroke="#5F5E5A" stroke-width="0.8" marker-end="url(#arrow)" style="fill:none;stroke:rgb(95, 94, 90);color:rgb(0, 0, 0);stroke-width:0.8px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<path d="M 145 380 Q 115 350 105 318" fill="none" stroke="#5F5E5A" stroke-width="0.8" marker-end="url(#arrow)" style="fill:none;stroke:rgb(95, 94, 90);color:rgb(0, 0, 0);stroke-width:0.8px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<!-- Loop back from Leave to Orient -->
<path d="M 120 262 Q 140 140 270 108" fill="none" stroke="#D85A30" stroke-width="1.2" stroke-dasharray="4 3" marker-end="url(#arrow)" style="fill:none;stroke:rgb(216, 90, 48);color:rgb(0, 0, 0);stroke-width:1.2px;stroke-dasharray:4px, 3px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="170" y="180" fill="#993C1D" style="fill:rgb(61, 61, 58);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:start;dominant-baseline:auto">다음 세션</text>

<!-- Artifacts in the center -->
<rect x="240" y="200" width="200" height="160" rx="8" fill="none" stroke="#888780" stroke-width="0.5" stroke-dasharray="3 3" style="fill:none;stroke:rgb(136, 135, 128);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-dasharray:3px, 3px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="340" y="218" text-anchor="middle" fill="#5F5E5A" style="fill:rgb(61, 61, 58);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:auto">Artifacts (세션 밖)</text>

<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="254" y="228" width="172" height="26" rx="4" stroke-width="0.5" style="fill:rgb(250, 238, 218);stroke:rgb(133, 79, 11);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="340" y="241" text-anchor="middle" dominant-baseline="central" style="fill:rgb(133, 79, 11);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">feature_list.json</text>
</g>
<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="254" y="260" width="172" height="26" rx="4" stroke-width="0.5" style="fill:rgb(250, 238, 218);stroke:rgb(133, 79, 11);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="340" y="273" text-anchor="middle" dominant-baseline="central" style="fill:rgb(133, 79, 11);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">init.sh</text>
</g>
<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="254" y="292" width="172" height="26" rx="4" stroke-width="0.5" style="fill:rgb(250, 238, 218);stroke:rgb(133, 79, 11);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="340" y="305" text-anchor="middle" dominant-baseline="central" style="fill:rgb(133, 79, 11);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">claude-progress.txt</text>
</g>
<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="254" y="324" width="172" height="26" rx="4" stroke-width="0.5" style="fill:rgb(250, 238, 218);stroke:rgb(133, 79, 11);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="340" y="337" text-anchor="middle" dominant-baseline="central" style="fill:rgb(133, 79, 11);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">git 저장소</text>
</g>

<!-- Read connections (blue dashed) -->
<path d="M 340 134 L 340 292" fill="none" stroke="#378ADD" stroke-width="0.6" stroke-dasharray="2 2" mask="url(#imagine-text-gaps-lymlai)" style="fill:none;stroke:rgb(55, 138, 221);color:rgb(0, 0, 0);stroke-width:0.6px;stroke-dasharray:2px, 2px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<path d="M 310 134 L 310 180 L 230 180 L 230 337 L 254 337" fill="none" stroke="#378ADD" stroke-width="0.6" stroke-dasharray="2 2" style="fill:none;stroke:rgb(55, 138, 221);color:rgb(0, 0, 0);stroke-width:0.6px;stroke-dasharray:2px, 2px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<path d="M 490 168 L 426 273" fill="none" stroke="#378ADD" stroke-width="0.6" stroke-dasharray="2 2" style="fill:none;stroke:rgb(55, 138, 221);color:rgb(0, 0, 0);stroke-width:0.6px;stroke-dasharray:2px, 2px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<path d="M 510 290 L 426 241" fill="none" stroke="#378ADD" stroke-width="0.6" stroke-dasharray="2 2" style="fill:none;stroke:rgb(55, 138, 221);color:rgb(0, 0, 0);stroke-width:0.6px;stroke-dasharray:2px, 2px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>

<!-- Write connections (orange solid) from Commit -->
<path d="M 180 384 L 180 214 L 254 214 L 254 228" fill="none" stroke="#D85A30" stroke-width="0.9" marker-end="url(#arrow)" style="fill:none;stroke:rgb(216, 90, 48);color:rgb(0, 0, 0);stroke-width:0.9px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<path d="M 210 384 L 210 305 L 254 305" fill="none" stroke="#D85A30" stroke-width="0.9" marker-end="url(#arrow)" style="fill:none;stroke:rgb(216, 90, 48);color:rgb(0, 0, 0);stroke-width:0.9px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<path d="M 240 384 L 240 365 L 254 365 L 254 350" fill="none" stroke="#D85A30" stroke-width="0.9" marker-end="url(#arrow)" style="fill:none;stroke:rgb(216, 90, 48);color:rgb(0, 0, 0);stroke-width:0.9px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>

<!-- Legend -->
<g transform="translate(40, 540)" style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<text x="0" y="0" fill="#5F5E5A" style="fill:rgb(61, 61, 58);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:start;dominant-baseline:auto">범례</text>
<line x1="0" y1="16" x2="24" y2="16" stroke="#378ADD" stroke-width="0.6" stroke-dasharray="2 2" style="fill:rgb(0, 0, 0);stroke:rgb(55, 138, 221);color:rgb(0, 0, 0);stroke-width:0.6px;stroke-dasharray:2px, 2px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="30" y="20" style="fill:rgb(61, 61, 58);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:start;dominant-baseline:auto">읽기 (read)</text>
<line x1="120" y1="16" x2="144" y2="16" stroke="#D85A30" stroke-width="0.9" marker-end="url(#arrow)" style="fill:rgb(0, 0, 0);stroke:rgb(216, 90, 48);color:rgb(0, 0, 0);stroke-width:0.9px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="150" y="20" style="fill:rgb(61, 61, 58);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:start;dominant-baseline:auto">쓰기 (write)</text>
<line x1="240" y1="16" x2="264" y2="16" stroke="#D85A30" stroke-width="1.2" stroke-dasharray="4 3" marker-end="url(#arrow)" style="fill:rgb(0, 0, 0);stroke:rgb(216, 90, 48);color:rgb(0, 0, 0);stroke-width:1.2px;stroke-dasharray:4px, 3px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="270" y="20" style="fill:rgb(61, 61, 58);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:start;dominant-baseline:auto">세션 반복</text>
</g>
</svg>
_세션 절차의 세 단계가 Orient/Select 단계와 매칭된다._

## 2. 읽고 알게 된 것들

원문을 두세 번 다시 읽으면서 처음 읽을 때는 그냥 지나쳤던 두 가지가 뒤늦게 눈에 들어왔다. 둘 다 "이 규칙이 뭐다"보다 "이 규칙이 *왜* 그렇게 생겼나"에 대한 답이었고, 그 답들이 이 글 전체에서 가장 흥미로운 부분이다.

**`feature_list.json`이 JSON인 이유.** Section 1에서는 이 규칙을 "해석 비용이 싸다 / context budget을 아낀다"로 정리했다. 그런데 더 본질적인 동기는 효율이 아니라 *신뢰*에 있다. Markdown 체크리스트는 사람이 보기에도 예쁘지만, 무엇보다 *에이전트가 보기에도 편집하기 좋은 포맷*이다. 한 줄 지우고 다른 한 줄을 끼워넣는 것이 자연어 안에서 너무 매끄럽게 일어난다. 반면 `passes: true/false`로 못박힌 JSON 항목을 에이전트가 슬쩍 고쳐쓰는 것은 어색하다. 스키마를 깨야 하기 때문이다. 즉 JSON 포맷은 "사람이 정한 todo list를 에이전트가 조용히 다시 쓰는 것"을 막기 위한 가드레일이다. 효율은 부산물이고, 본질은 권한 분리다. 누가 spec을 바꿀 수 있는가에 대한 답을 파일 포맷 차원에서 못박아둔 것이다.

**두 프롬프트로 굳이 왜 나누는가.** Initializer와 coding 프롬프트가 같은 모델에 다른 프롬프트라면, 그냥 하나의 긴 프롬프트에 두 단계를 다 적어두면 안 되나? 처음엔 단순히 "역할 분리가 깔끔해서"라고 생각했는데, 다시 읽으니 더 분명한 이득이 있다. Coding 프롬프트에는 *계획을 다시 짠다는 어휘 자체가 없다*. "feature를 재정의한다"거나 "전략을 수정한다"는 말이 프롬프트 어디에도 등장하지 않으니, 에이전트가 그 방향으로 흘러갈 수 있는 통로가 처음부터 막혀 있다. 금지 사항을 길게 나열하는 대신, *어휘를 빼버리는 것*이 가드레일이 된다. 가장 저렴한 가드레일은 "하지 마"가 아니라 "그 단어를 모름"이다. 두 프롬프트 분리는 이 메커니즘을 활용하기 위한 구조적 트릭에 가깝다.

## 3. 내 작업에 어떻게 적용할 것인가

원문을 읽고 머릿속에 떠오른 첫 번째 그림은 "이걸 내 다음 사이드 프로젝트에 그대로 붙이면 어떻게 생겼을까"였다. 그래서 가장 평범하게 Spring Boot로 만드는 회원가입 API 작업에 적용했다. `POST /users` 하나, 이메일 유효성 검증, 비밀번호 해싱, 이메일 중복 체크. 백엔드 개발자라면 누구나 쉽게 짤 수 있는 기능이다.

먼저 `feature_list.json`을 만들어야 한다. Initializer 프롬프트가 한 번 돌고 나면 이런 모양이 나올 것이다.

```json
{
  "features": [
    { "id": 1, "name": "add-user-entity", "passes": false },
    { "id": 2, "name": "add-registration-endpoint", "passes": false },
    { "id": 3, "name": "add-duplicate-email-check", "passes": false }
  ]
}
```

세 개로 쪼갠 이유는 단순하다. 하나의 세션에 feature 하나씩만 닫는다는 "세션 1개 분량 = entry 1개" 원칙을 적용한 것이다. 하나의 feature 안에 "엔티티도 만들고 엔드포인트도 만들고 검증도 추가한다"를 다 우겨넣으면 그 세션은 절대 끝나지 않는다. 거꾸로 너무 잘게 쪼개면 한 세션이 5분 만에 끝나면서 commit/document 비용이 작업 비용보다 커진다.

`init.sh`는 Spring 프로젝트라면 거의 자동으로 채울 수 있다. `./gradlew bootRun`이 뜨는지, `/actuator/health`가 200을 주는지, `./gradlew test`가 통과하는지. 이전 세션이 멀쩡한 상태로 끝났는지를 사람에게 묻는 대신 세 줄짜리 스크립트면 충분하다. 핵심은 새로 짜는 게 아니라, 우리가 평소에 PR 머지 전에 손으로 확인하던 항목들을 그대로 옮겨 적는 것이다.

7단계 workflow도 우리에게 익숙하다. Orient(progress 읽기) = 어제 작성한 PR 설명과 코멘트 다시 읽기. Verify(init.sh) = 로컬에서 `bootRun` 한 번 띄워보기. 그리고 Implement → Test E2E → Commit → Leave merge-ready = PR을 머지 가능한 상태로 떠나는 흐름 그 자체.  

"세션 하나에 feature 하나만 닫는다"는 규칙은 "한 PR에 한 가지 일만 한다"는 우리가 이미 지키려고 하는 원칙이다. 결국 이 harness가 에이전트에게 부과하는 룰은 사람에게 부과되는 것과 거의 같다. 다른 점은 하나뿐이다. 사람은 규칙을 어기게 되면 본인이 부끄러워서 다음번엔 지키려 하지만, 에이전트는 부끄러움이 없으므로 파일과 스크립트로 강제해야 한다.

여기까지 그려보고 든 생각은, 내가 이 가상 시나리오에서 한 일이 결국 *원문 패턴을 거의 그대로 복사한 것*이라는 점이다. 예시를 Spring으로 바꿨을 뿐, 구조는 한 줄도 비틀지 않았다. 그게 이 패턴의 강점이기도 하고 백엔드 디시플린과 동형이기 때문에 큰 어려움 없이 그대로 적용된다. 동시에 한계의 출발점이기도 하다. 이제는 같은 문제를 다른 각도에서 접근하면 어떻게 되는지가 궁금해진다.

## 4. 관련 오픈소스 — 같은 문제를 다르게 푸는 세 갈래

### 4.0 같은 문제, 세 개의 다른 시점

원문이 제안하는 harness가 풀려는 문제 — *에이전트가 spec을 잃어버리거나 멋대로 바꾸는 것* — 는 분명히 한 가지인데, 이걸 푸는 방식은 한 가지가 아니다. 이 문제를 어디서 잡느냐에 따라 도구가 갈린다.

사람의 의도가 spec으로 굳고, spec을 가지고 코드가 생성되고, 그 코드가 실행되고 검증된다

**Q00/ouroboros**는 spec이 굳기 *직전*에 손을 댄다. 사람이 던진 요구사항이 충분히 명확한지를 정량적으로 측정해서, 임계값을 못 넘으면 코드 생성 단계로 진입조차 못 시킨다. 가장 이른 시점이다.

**Anthropic 원문**은 spec이 이미 만들어진 *후*, 세션과 세션 사이에 손을 댄다. 파일 포맷과 7-step workflow로 "에이전트가 이 spec을 임의로 다시 쓰지 못하게" 잠그는 방식이다. Section 3에서 본 `feature_list.json`이 JSON인 진짜 이유 — 누가 spec을 바꿀 수 있는가에 대한 답을 파일 차원에서 못박는 것 — 가 정확히 이 지점이다.

**oh-my-claudecode와 oh-my-codex**는 spec이 만들어지고 코드가 *실행되는 동안*에 손을 댄다. 7-step workflow가 사람의 손을 떠나 런타임 안에서 자동으로 굴러가게 만드는 방향이다. 가장 늦은 시점이다.

<svg width="100%" viewBox="0 0 680 430" role="img" xmlns="http://www.w3.org/2000/svg">
<title style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">에이전트 파이프라인의 세 가지 잠금 지점</title>
<desc style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">사람의 의도에서 실행/검증까지 이어지는 4단계 파이프라인 위에, Q00/ouroboros는 spec 직전, Anthropic harness는 세션 사이, OMC/OmX는 런타임 내부에 잠금을 건다는 것을 보여주는 다이어그램.</desc>
<defs>
<marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M2 1L8 5L2 9" fill="none" stroke="context-stroke" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></marker>
</defs>

<text x="40" y="32" style="fill:rgb(61, 61, 58);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:start;dominant-baseline:auto">상류 (의도)</text>
<text x="640" y="32" text-anchor="end" style="fill:rgb(61, 61, 58);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:end;dominant-baseline:auto">하류 (결과물)</text>

<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="40" y="50" width="130" height="56" rx="8" stroke-width="0.5" style="fill:rgb(241, 239, 232);stroke:rgb(95, 94, 90);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="105" y="74" text-anchor="middle" dominant-baseline="central" style="fill:rgb(68, 68, 65);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">사람의 의도</text>
<text x="105" y="92" text-anchor="middle" dominant-baseline="central" style="fill:rgb(95, 94, 90);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">요구사항</text>
</g>

<line x1="170" y1="78" x2="210" y2="78" marker-end="url(#arrow)" style="fill:none;stroke:rgb(115, 114, 108);color:rgb(0, 0, 0);stroke-width:1.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>

<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="210" y="50" width="130" height="56" rx="8" stroke-width="0.5" style="fill:rgb(241, 239, 232);stroke:rgb(95, 94, 90);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="275" y="74" text-anchor="middle" dominant-baseline="central" style="fill:rgb(68, 68, 65);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">spec</text>
<text x="275" y="92" text-anchor="middle" dominant-baseline="central" style="fill:rgb(95, 94, 90);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">feature 목록</text>
</g>

<line x1="340" y1="78" x2="380" y2="78" marker-end="url(#arrow)" style="fill:none;stroke:rgb(115, 114, 108);color:rgb(0, 0, 0);stroke-width:1.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>

<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="380" y="50" width="130" height="56" rx="8" stroke-width="0.5" style="fill:rgb(241, 239, 232);stroke:rgb(95, 94, 90);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="445" y="74" text-anchor="middle" dominant-baseline="central" style="fill:rgb(68, 68, 65);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">코드 생성</text>
<text x="445" y="92" text-anchor="middle" dominant-baseline="central" style="fill:rgb(95, 94, 90);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">세션 루프</text>
</g>

<line x1="510" y1="78" x2="550" y2="78" marker-end="url(#arrow)" style="fill:none;stroke:rgb(115, 114, 108);color:rgb(0, 0, 0);stroke-width:1.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>

<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="550" y="50" width="90" height="56" rx="8" stroke-width="0.5" style="fill:rgb(241, 239, 232);stroke:rgb(95, 94, 90);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="595" y="74" text-anchor="middle" dominant-baseline="central" style="fill:rgb(68, 68, 65);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">실행/검증</text>
<text x="595" y="92" text-anchor="middle" dominant-baseline="central" style="fill:rgb(95, 94, 90);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">테스트</text>
</g>

<line x1="190" y1="120" x2="190" y2="170" stroke="#534AB7" stroke-width="1.5" stroke-dasharray="4 3" style="fill:rgb(0, 0, 0);stroke:rgb(83, 74, 183);color:rgb(0, 0, 0);stroke-width:1.5px;stroke-dasharray:4px, 3px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<circle cx="190" cy="120" r="5" fill="#534AB7" style="fill:rgb(83, 74, 183);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>

<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="60" y="170" width="260" height="70" rx="8" stroke-width="0.5" style="fill:rgb(238, 237, 254);stroke:rgb(83, 74, 183);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="190" y="194" text-anchor="middle" dominant-baseline="central" style="fill:rgb(60, 52, 137);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">Q00 / ouroboros</text>
<text x="190" y="214" text-anchor="middle" dominant-baseline="central" style="fill:rgb(83, 74, 183);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">명확도 게이트로 spec 진입 차단</text>
<text x="190" y="230" text-anchor="middle" dominant-baseline="central" style="fill:rgb(83, 74, 183);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">가장 이른 시점</text>
</g>

<line x1="360" y1="120" x2="360" y2="260" stroke="#0F6E56" stroke-width="1.5" stroke-dasharray="4 3" style="fill:rgb(0, 0, 0);stroke:rgb(15, 110, 86);color:rgb(0, 0, 0);stroke-width:1.5px;stroke-dasharray:4px, 3px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<circle cx="360" cy="120" r="5" fill="#0F6E56" style="fill:rgb(15, 110, 86);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>

<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="210" y="260" width="300" height="70" rx="8" stroke-width="0.5" style="fill:rgb(225, 245, 238);stroke:rgb(15, 110, 86);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="360" y="284" text-anchor="middle" dominant-baseline="central" style="fill:rgb(8, 80, 65);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">Anthropic harness</text>
<text x="360" y="304" text-anchor="middle" dominant-baseline="central" style="fill:rgb(15, 110, 86);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">JSON 스키마로 세션 사이 잠금</text>
<text x="360" y="320" text-anchor="middle" dominant-baseline="central" style="fill:rgb(15, 110, 86);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">한가운데를 사람 손에</text>
</g>

<line x1="525" y1="120" x2="525" y2="350" stroke="#993C1D" stroke-width="1.5" stroke-dasharray="4 3" style="fill:rgb(0, 0, 0);stroke:rgb(153, 60, 29);color:rgb(0, 0, 0);stroke-width:1.5px;stroke-dasharray:4px, 3px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<circle cx="525" cy="120" r="5" fill="#993C1D" style="fill:rgb(153, 60, 29);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>

<g style="fill:rgb(0, 0, 0);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto">
<rect x="380" y="350" width="260" height="70" rx="8" stroke-width="0.5" style="fill:rgb(250, 236, 231);stroke:rgb(153, 60, 29);color:rgb(0, 0, 0);stroke-width:0.5px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:16px;font-weight:400;text-anchor:start;dominant-baseline:auto"/>
<text x="510" y="374" text-anchor="middle" dominant-baseline="central" style="fill:rgb(113, 43, 19);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:14px;font-weight:500;text-anchor:middle;dominant-baseline:central">OMC / OmX</text>
<text x="510" y="394" text-anchor="middle" dominant-baseline="central" style="fill:rgb(153, 60, 29);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">7단계 루프를 런타임에 내장</text>
<text x="510" y="410" text-anchor="middle" dominant-baseline="central" style="fill:rgb(153, 60, 29);stroke:none;color:rgb(0, 0, 0);stroke-width:1px;stroke-linecap:butt;stroke-linejoin:miter;opacity:1;font-family:&quot;Anthropic Sans&quot;, -apple-system, BlinkMacSystemFont, &quot;Segoe UI&quot;, sans-serif;font-size:12px;font-weight:400;text-anchor:middle;dominant-baseline:central">가장 늦은 시점</text>
</g>
</svg>

<br>
정리하면 이렇다 — 같은 문제를 Q00은 가장 이른 시점에서, 원문은 중간에서, OMC/OmX는 가장 늦은 시점에서 잡는다. 어느 쪽이 옳다는 얘기가 아니다. 셋 다 에이전트가 잘못 굴러가는 것을 막으려는 시도이고, 단지 *언제 막느냐*에 대한 답이 다를 뿐이다.

### 4.1 oh-my-claudecode — 7-step workflow를 런타임에 박아넣기

가장 먼저 볼 도구는 **oh-my-claudecode**(OMC)다. 한국 개발자 Yeachan Heo가 만들었고, instructkr 커뮤니티를 중심으로 활발하게 개발되고 있는 Claude Code 플러그인이다.

OMC의 시그니처 기능은 **ralph mode**라고 부르는 실행 루프다. 한 번 시작하면 작업 목록이 비거나 중단 조건이 걸릴 때까지 에이전트가 스스로 다음 작업을 골라서, 구현하고, 검증하고, 그 결과로 자신의 상태를 갱신하고, 다시 다음 작업을 고른다. 사람이 세션을 끊고 다시 붙이는 동작이 없다.

여기서 흥미로운 건 ralph mode가 *완전히 새로운 무언가*가 아니라는 점이다. 앞서 내가 묶은 7단계를 다시 떠올려보면 *사람이 한 세션마다 손으로 굴리는* 절차였다. 사람이 progress를 읽고, 사람이 init.sh를 돌리고, 사람이 다음 feature를 골랐다. OMC 측은 이렇게 묘사하지 않지만, 두 패턴을 나란히 놓고 보면 ralph mode는 이 7단계를 사람의 손에서 떼어내 런타임 안으로 옮긴 것이다. 7단계의 *내용*은 거의 그대로지만, 그것을 굴리는 *주체*가 바뀐 것이다.

ralph mode가 *7-step 루프*를 런타임으로 옮긴 것이라면, **team**은 그 루프가 *여러 에이전트 사이에 분배되는 단계*까지 한 걸음 더 들어간다. N개의 에이전트가 하나의 공유 작업 목록에서 각자 작업을 하나씩 집어 가 처리하고, 결과를 다시 그 목록에 반영하고, 서로의 진행 상황을 실시간으로 주고받는다. 여기서 한 가지 짚을 점은, 이게 가능하려면 *에이전트들이 서로의 작업 상태를 런타임 안에서 공유할 수 있어야 한다*는 것이다. 원문에서는 사람이 progress 파일과 git commit을 통해 세션 사이에 그 정보를 전달했다. OMC team은 같은 정보 흐름을 native primitive로 옮긴 셈이다. 사람이 세션 경계에서 손으로 하던 인수인계가, 런타임 안에서 에이전트들끼리의 메시지로 바뀌었다고 생각하면 된다. 그 외에도 고수준 아이디어 하나를 던지면 끝까지 자동으로 가는 **autopilot**, 컨텍스트 사용량과 진행 상황을 실시간으로 보여주는 **HUD** statusline 등의 기능들이 모두 같은 방향에 놓여 있다.

ralph mode와 team이 함께 보여주는 것은, 원문이 *사람이 할 작업*으로 남겨둔 부분을 OMC가 *런타임의 일부*로 옮겼다는 사실이다. 7단계를 누가 굴리는가, progress를 누가 읽는가, 다음 작업을 누가 고르는가 — 이 질문들에 대한 답이 사람에서 시스템으로 넘어간다.

### 4.2 oh-my-codex — 같은 역할, 다른 런타임

**oh-my-codex**(OmX)는 OMC를 만든 같은 저자(Yeachan Heo)가 OpenAI Codex CLI 위에 옮겨놓은 자매 프로젝트다. OMC와 역할이 같다. 다른 점은 그 기능을 어떻게 노출하는가이다. OMC가 Claude Code 플러그인 런타임 안쪽에 기능을 박아넣었다면, OmX는 `omx team queue`, `omx team claim`, `omx team complete` 같은 CLI 명령으로 같은 task lifecycle을 바깥으로 끄집어낸다. 워커는 tmux pane 위에서 돈다. 같은 패턴, 다른 표면이다.

여기서 한 가지 짚을 점이 있다. OMC와 OmX가 *같은 사람이 다른 모델 위에 같은 패턴을 두 번 구현한 결과물*이라는 사실은, 이 패턴 자체가 특정 모델에 종속되는 녀석이 아니라는 증거가 된다. 실제로 OmX는 claw-code라는 Rust 포팅 작업을 end-to-end로 굴려서 만들어냈다.

### 4.3 ouroboros — spec이 굳기 전에 잠근다

마지막으로 볼 도구는 **Q00/ouroboros**다. 4.0의 분류로 말하면, spec이 굳기 *직전*에 손을 대는 도구다. 사람의 모호한 요구사항이 spec으로 변환되는 그 순간을 노린다.

ouroboros의 파이프라인은 Interview → Seed → Execute → Evaluate 네 단계로 나뉜다. 이는 평범한 에이전트의 워크플로우 같지만, 다른 도구들과 가르는 지점은 첫 단계인 Interview에 있다. 이 하네스는 사람이 던진 요구사항을 받아서 곧바로 Seed(코드 생성용 spec)로 굳히지 않고, 그 요구사항이 *얼마나 명확한지*를 가중치 기반으로 정량화한다. 명확도가 임계값 — 보통 0.8 — 을 넘기지 못하면 Seed로 진입할 수 없다. "누가 spec을 바꿀 수 있는가" 라는 질문에 ouroboros는 "애초에 spec이 굳을 자격이 있는지부터 따진다"고 답하는 셈이다.

이 잠금 장치는 원문의 그것과 닮아있으면서도 다르다. 원문에서는 JSON 스키마가 "이미 만들어진 spec을 에이전트가 슬쩍 다시 쓰지 못하게" 잠근다. ouroboros에서는 명확도 게이트가 "애매한 의도가 spec으로 굳어버리는 것 자체를" 잠근다. 둘 다 권한 분리의 도구이지만, 한쪽은 spec이 만들어진 다음을 지키고, 다른 한쪽은 spec이 만들어지는 그 순간을 지킨다. 이 차이는 곧 4.0에서 말한 "어느 시점에 손을 대느냐"의 차이다.

ouroboros가 그 후에 두는 3단계 검증(Mechanical → Semantic → Multi-Model Consensus)도 물론 있지만, 이 도구의 무게중심은 그 뒤쪽이 아니라 앞쪽이다. 코드 한 줄이 생기기 전에 "이건 아직 시작할 수 없다"고 멈출 수 있다는 사실, 그게 ouroboros가 다른 두 진영과 갈라지는 자리다.

### 4.4 상류부터 하류까지 한 바퀴 돈 뒤에는

지금까지 사람의 의식(상류)부터 결과물(하류)까지의 흐름에서 서로 다른 곳에 잠금 장치를 거는 세 가지 도구를 살펴보았다. 여기까지 살펴보고 나니 원문의 위치가 다르게 읽힌다. 어느 시점에 손을 대느냐의 양 끝 — Q00과 OMC — 사이에서, 원문은 한가운데를 사람의 손에 남겨두는 쪽을 골랐다. 처음엔 이게 가장 소극적인 위치로 보였지만, 지금은 spec과 런타임 양쪽 어떤 것도 미리 깨지 않는, 가장 늦게까지 잠그지 않아도 되는 자리로 읽힌다.

## 5. Reference

여기까지 정리한 내용의 출발점이 된 글은 Anthropic Engineering 블로그에 올라온 [**Effective harnesses for long-running agents**](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)다. Justin Young이 쓴 글로, Claude Agent SDK가 여러 context window를 가로질러 작업할 수 있게 만든 initializer/coding 두 프롬프트 패턴을 처음으로 정리해 공개했다. 이후 Anthropic은 같은 문제에 multi-agent 구조로 답한 후속 글도 냈는데, 이 글은 그 흐름의 *첫 번째* 글 — 단일 에이전트와 외부 artifact만으로 어디까지 갈 수 있는지를 보여주는 출발점 — 에 해당한다. 후속 글들은 이 시리즈의 2편과 3편에서 차례로 다룰 예정이다. 

## 닫는 말

다음에 Claude Code나 비슷한 도구로 하루 이상 가는 작업을 한다면 `init.sh`와 `feature_list.json`을 만들자. 두 파일을 만드는 비용은 싸고, 세션 하나만 돌려봐도 이 글이 말한 병목이 사라진, 이전과는 다른 결과물이 확인될 것이다(필자가 경험함).

이 글에서 자주 등장한 *context window* 자체가 어떻게 관리되고 있는가는 그 자체로 한 편 분량의 이야기다. 다음 글에서는 Anthropic이 같은 블로그에서 따로 다룬 [context engineering](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) 글을 같은 방식으로 — 읽고, 정리하고, 풀어볼 예정이다. 이 harness 글이 *세션 사이*의 문제를 다뤘다면, 그 글은 *세션 안*의 문제를 다룬다.

시리즈의 마지막 글에서는 Anthropic이 multi-agent harness로 같은 문제를 다시 푼 후속 사례를 다룬다. 1편이 단일 에이전트와 파일 네 개로 어디까지 갈 수 있는지를 보여줬다면, 그 글은 상한선을 어떻게 뚫었는지에 대한 답이다.

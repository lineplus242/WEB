# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Deploy

**Java 컴파일** (소스 수정 후 반드시 실행):
```bash
javac -cp "/var/lib/tomcat/webapps/app/WEB-INF/lib/*:/usr/share/tomcat/lib/*" \
  -d /var/lib/tomcat/webapps/app/WEB-INF/classes \
  /var/lib/tomcat/webapps/app/WEB-INF/src/*.java
```

**Tomcat 재시작** (클래스 변경 반영):
```bash
systemctl restart tomcat
```

**DB 접속** (MariaDB, admin_db):
```bash
mariadb -u root -p'wkd11!#Eod' admin_db
```

## Architecture

빌드 도구(Maven/Gradle) 없는 순수 Jakarta Servlet + JSP + MariaDB 구조로, Tomcat 10 / Java 21에서 실행된다.

### 요청 흐름
```
브라우저 → @WebServlet (비즈니스 로직 + DB) → req.setAttribute() → JSP (렌더링)
```
각 서블릿이 GET/POST `action` 파라미터로 내부 메서드를 라우팅한다 (`switch (action)`). JSON 응답이 필요한 경우(updateItem, stats 등) JSP 포워드 없이 `resp.getWriter()`로 직접 출력한다.

### 서블릿 목록
| URL 패턴 | 파일 | 역할 |
|---|---|---|
| `/LoginServlet` | `LoginServlet.java` | 로그인/세션 생성 |
| `/LogoutServlet` | `LogoutServlet.java` | 세션 무효화 |
| `/DashboardServlet` | `DashboardServlet.java` | 대시보드 통계 JSON |
| `/UserServlet` | `UserServlet.java` | 사용자 CRUD (목록/등록/수정/삭제, ADMIN 전용) |
| `/CustomerServlet` | `CustomerServlet.java` | 고객사 목록/등록 |
| `/CustomerDetailServlet` | `CustomerDetailServlet.java` | 고객사 상세 (프로젝트·담당자·랙·자산) |
| `/AssetDetailServlet` | `AssetDetailServlet.java` | IT 자산 상세/사진/포트맵 |
| `/SecurityScan` | `SecurityScanServlet.java` | 보안점검 업로드·조회·수정·엑셀 다운로드 |
| `/ImageLibraryServlet` | `ImageLibraryServlet.java` | 이미지 라이브러리 |

### 주요 DB 테이블
- `tb_user` — 사용자 (role: ADMIN/USER, 비밀번호 `HEX(SHA2(..., 256))`)
- `tb_customer` / `tb_customer_manager` / `tb_project` — 고객사·담당자·사업
- `tb_rack` / `tb_rack_unit` — 랙·슬롯
- `tb_asset` / `tb_asset_photo` / `tb_port_map` — IT 자산 (계층구조: `parent_seq`)
- `security_scan_batch` / `security_scan` / `security_scan_item` — 보안점검

### 세션 인증
모든 서블릿은 `req.getSession(false)`로 세션을 확인하고, `loginUser`(아이디)·`loginRole`(ADMIN/USER) 속성으로 접근 제어한다. 미인증 시 `login.jsp`로 리다이렉트.

### 보안점검(SecurityScan) 기능 상세
- 업로드: `.tar` 파일 → `/tmp`에 압축 해제 → XML(점검결과) + TXT(현황) + `_REF.txt`(참조현황) 파싱 → DB 저장
- 엑셀 다운로드: `/WEB-INF/template/unix_template.xlsx` 템플릿 기반, Apache POI로 시트 복제
  - `Ⅲ. 점검대상` 시트: 서버 목록
  - `template` 시트: 서버별 복제 (탭 색상 `#A6C9EC`)
  - `Ⅳ. 보안점검 결과` 시트: G4열부터 서버별 결과 매트릭스
- `evidence_types` 컬럼: 항목별 현황 출력 소스 선택 (`xml`, `txt`, `ref` 조합, 기본값 `xml,txt,ref`)

### 공통 패턴
- 소프트 삭제: `del_yn='Y'` (실제 DELETE 미사용)
- 모든 서블릿에 DB 접속 정보(`DB_URL`, `DB_USER`, `DB_PASS`) 상수로 중복 선언됨
- `tb_asset.account_info`: JSON 문자열로 자격증명 저장
- `js/common.js`: Backspace 뒤로가기 전역 차단

# CLAUDE.md

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.

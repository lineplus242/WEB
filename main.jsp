<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.time.LocalDateTime, java.time.format.DateTimeFormatter" %>
<%
    // 로그인 세션 체크 — 없으면 로그인 페이지로
    String loginUser = (String) session.getAttribute("loginUser");
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");

    if (loginUser == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // 오늘 날짜
    String today = LocalDateTime.now()
            .format(DateTimeFormatter.ofPattern("yyyy년 MM월 dd일"));
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>대시보드 - 관리 시스템</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
    <script>(function(){if(localStorage.getItem('theme')==='light')document.documentElement.setAttribute('data-theme','light');})()</script>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'DM Sans', sans-serif;
            background: #0e0f11;
            color: #e8e9eb;
            min-height: 100vh;
            display: flex;
        }

        /* ── 사이드바 ── */
        .sidebar {
            width: 220px;
            background: #0b0c0f;
            border-right: 1px solid #1e2025;
            display: flex;
            flex-direction: column;
            position: fixed;
            top: 0; left: 0;
            height: 100vh;
            z-index: 100;
        }

        .sb-brand {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 20px 20px 16px;
            border-bottom: 1px solid #1e2025;
        }

        .sb-icon {
            width: 28px; height: 28px;
            background: #3b6ef5;
            border-radius: 7px;
            display: flex; align-items: center; justify-content: center;
            flex-shrink: 0;
        }

        .sb-icon svg { width: 15px; height: 15px; fill: #fff; }

        .sb-name {
            font-size: 13px;
            font-weight: 500;
            color: #e8e9eb;
            letter-spacing: 0.02em;
        }

        .sb-dot { color: #3b6ef5; }

        .sb-section {
            padding: 16px 20px 6px;
            font-size: 10px;
            font-weight: 500;
            color: #3d4251;
            letter-spacing: 0.08em;
            text-transform: uppercase;
        }

        .sb-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 8px 12px;
            border-radius: 7px;
            margin: 1px 8px;
            font-size: 13px;
            color: #6b7280;
            cursor: pointer;
            text-decoration: none;
            transition: background 0.12s, color 0.12s;
        }

        .sb-item:hover { background: #161820; color: #c8cad0; }
        .sb-item.active { background: #1a1e2e; color: #6b9af5; }
        .sb-item svg { width: 15px; height: 15px; flex-shrink: 0; opacity: 0.7; }
        .sb-item.active svg { opacity: 1; }

        .sb-bottom {
            margin-top: auto;
            border-top: 1px solid #1e2025;
            padding: 12px;
        }

        .user-row { display:flex;align-items:center;gap:10px;padding:8px;border-radius:8px;cursor:pointer;transition:background .12s; }
        .user-row:hover,.user-row.open { background:#161820; }
        .user-chevron { width:12px;height:12px;margin-left:auto;flex-shrink:0;color:#3d4251;transition:transform .2s; }
        .user-row.open .user-chevron { transform:rotate(180deg); }
        .user-menu { display:none;background:#1a1c22;border:1px solid #252830;border-radius:10px;padding:5px;margin-bottom:4px; }
        .user-menu.open { display:block; }
        .user-menu-item { display:flex;align-items:center;gap:8px;padding:8px 10px;border-radius:7px;font-size:12px;color:#c8cad0;text-decoration:none;transition:background .12s;width:100%;border:none;background:none;cursor:pointer;font-family:inherit; }
        .user-menu-item:hover { background:#252830; }
        .user-menu-item.danger { color:#e05656; }
        .user-menu-item.danger:hover { background:#2a1015; }

        .avatar {
            width: 30px; height: 30px;
            border-radius: 50%;
            background: #1a1e2e;
            display: flex; align-items: center; justify-content: center;
            font-size: 11px;
            font-weight: 500;
            color: #6b9af5;
            flex-shrink: 0;
        }

        .user-info p  { font-size: 12px; font-weight: 500; color: #c8cad0; }
        .user-info span { font-size: 11px; color: #3d4251; }


        /* ── 메인 콘텐츠 ── */
        .main {
            margin-left: 220px;
            flex: 1;
            display: flex;
            flex-direction: column;
            min-height: 100vh;
        }

        .topbar {
            height: 52px;
            border-bottom: 1px solid #1e2025;
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 28px;
            background: #0e0f11;
            position: sticky;
            top: 0;
            z-index: 50;
        }

        .topbar-title { font-size: 14px; font-weight: 500; color: #f2f3f5; }

        .topbar-right { display: flex; align-items: center; gap: 8px; }

        .badge {
            background: #1a1e2e;
            border: 1px solid #252d44;
            border-radius: 20px;
            padding: 4px 10px;
            font-size: 11px;
            color: #5a80d0;
            font-family: 'DM Mono', monospace;
        }

        .pulse {
            display: inline-block;
            width: 5px; height: 5px;
            background: #22c97a;
            border-radius: 50%;
            margin-right: 5px;
            vertical-align: middle;
            animation: blink 1.6s ease-in-out infinite;
        }

        @keyframes blink {
            0%, 100% { opacity: 1; }
            50%       { opacity: 0.2; }
        }

        /* ── 콘텐츠 영역 ── */
        .content { padding: 28px 28px; }

        .greeting {
            font-size: 20px;
            font-weight: 400;
            color: #f2f3f5;
            margin-bottom: 4px;
            letter-spacing: -0.01em;
        }

        .greeting em { color: #3b6ef5; font-style: normal; }

        .sub-greeting {
            font-size: 12px;
            color: #4b5161;
            margin-bottom: 28px;
        }

        /* ── 통계 카드 ── */
        .stat-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 12px;
            margin-bottom: 24px;
        }

        @media (max-width: 900px) {
            .stat-grid { grid-template-columns: repeat(2, 1fr); }
        }

        .stat-card {
            background: #131519;
            border: 1px solid #1e2025;
            border-radius: 12px;
            padding: 18px 20px;
        }

        .stat-label {
            font-size: 10px;
            color: #4b5161;
            letter-spacing: 0.07em;
            text-transform: uppercase;
            margin-bottom: 6px;
        }

        .stat-val {
            font-size: 22px;
            font-weight: 500;
            color: #f2f3f5;
            font-family: 'DM Mono', monospace;
            letter-spacing: -0.02em;
        }

        .stat-change { font-size: 11px; margin-top: 4px; }
        .up      { color: #22c97a; }
        .neutral { color: #4b5161; }
        .down    { color: #e05656; }

        /* ── 패널 그리드 ── */
        .panel-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
        }

        @media (max-width: 900px) {
            .panel-grid { grid-template-columns: 1fr; }
        }

        .panel {
            background: #131519;
            border: 1px solid #1e2025;
            border-radius: 12px;
            padding: 20px 22px;
        }

        .panel-title {
            font-size: 11px;
            font-weight: 500;
            color: #9ca3af;
            letter-spacing: 0.05em;
            text-transform: uppercase;
            margin-bottom: 14px;
        }

        .list-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 9px 0;
            border-bottom: 1px solid #1a1c22;
        }

        .list-item:last-child { border-bottom: none; }

        .li-name { font-size: 13px; color: #c8cad0; }
        .li-sub  { font-size: 11px; color: #4b5161; margin-top: 2px; }

        .chip {
            font-size: 11px;
            padding: 4px 11px;
            border-radius: 99px;
            font-family: 'Pretendard', system-ui, sans-serif;
            font-weight: 500;
            flex-shrink: 0;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            border: none;
        }
        .chip-g::before, .chip-r::before, .chip-y::before { content: ''; width: 5px; height: 5px; border-radius: 50%; flex-shrink: 0; }
        .chip-g { background: rgba(34,201,122,0.1);  color: #22c97a; }
        .chip-g::before { background: #22c97a; box-shadow: 0 0 5px #22c97a88; }
        .chip-r { background: rgba(224,86,86,0.1);   color: #e05656; }
        .chip-r::before { background: #e05656; }
        .chip-y { background: rgba(212,160,23,0.1);  color: #d4a017; }
        .chip-y::before { background: #d4a017; }
    </style>
    <link rel="stylesheet" href="style/light.css">
</head>
<body>

    <!-- ── 사이드바 ── -->
    <nav class="sidebar">
        <div class="sb-brand">
            <div class="sb-icon">
                <svg viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/></svg>
            </div>
            <span class="sb-name">ADMIN<span class="sb-dot">.</span>SYS</span>
        </div>

        <div class="sb-section">메뉴</div>

        <a href="main.jsp" class="sb-item active">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/>
                <rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/>
            </svg>
            대시보드
        </a>

        <a href="CustomerServlet?action=list" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
                <polyline points="9 22 9 12 15 12 15 22"/>
            </svg>
            고객사 정보
        </a>

        <% if ("ADMIN".equals(loginRole)) { %>
        <a href="UserServlet?action=list" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/>
                <circle cx="9" cy="7" r="4"/>
                <path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/>
            </svg>
            사용자 관리
        </a>
        <% } %>

        <div class="sb-section">계정</div>

        <a href="UserServlet?action=changePw" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
                <path d="M7 11V7a5 5 0 0110 0v4"/>
            </svg>
            비밀번호 변경
        </a>

        <div class="sb-section">시스템</div>

        <a href="settings.jsp" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="3"/>
                <path d="M19.07 4.93a10 10 0 010 14.14M4.93 4.93a10 10 0 000 14.14"/>
            </svg>
            설정
        </a>

        <div class="sb-bottom">
            <div id="userMenu" class="user-menu">
                <a href="mypage.jsp" class="user-menu-item">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px;flex-shrink:0"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                    마이페이지
                </a>
                <div style="height:1px;background:#252830;margin:4px 2px"></div>
                <a href="LogoutServlet" class="user-menu-item danger">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px;flex-shrink:0"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                    로그아웃
                </a>
            </div>
            <div class="user-row" onclick="toggleUserMenu(this)">
                <div class="avatar"><%= loginName != null ? String.valueOf(loginName.charAt(0)) : "관" %></div>
                <div class="user-info">
                    <p><%= loginName != null ? loginName : loginUser %></p>
                    <span><%= loginRole != null ? loginRole : "USER" %></span>
                </div>
                <svg class="user-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"/></svg>
            </div>
        </div>
    </nav>

    <!-- ── 메인 콘텐츠 ── -->
    <div class="main">
        <div class="topbar">
            <span class="topbar-title">대시보드</span>
            <div class="topbar-right">
                <div class="badge"><span class="pulse"></span>MySQL 연결됨</div>
                <div class="badge">Tomcat 10</div>
            </div>
        </div>

        <div class="content">
            <div class="greeting">안녕하세요, <em><%= loginName != null ? loginName : loginUser %></em>님</div>
            <div class="sub-greeting"><%= today %> · 마지막 로그인 <%= session.getAttribute("lastLogin") != null ? session.getAttribute("lastLogin") : "방금" %></div>

            <!-- 통계 카드 -->
            <div class="stat-grid">
                <div class="stat-card">
                    <div class="stat-label">전체 사용자</div>
                    <div class="stat-val" id="totalUsers">-</div>
                    <div class="stat-change up" id="userChange">로딩 중...</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">오늘 접속</div>
                    <div class="stat-val" id="todayLogin">-</div>
                    <div class="stat-change neutral">활성 세션</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">전체 게시글</div>
                    <div class="stat-val" id="totalBoard">-</div>
                    <div class="stat-change neutral" id="boardChange">로딩 중...</div>
                </div>
                <div class="stat-card">
                    <div class="stat-label">DB 응답</div>
                    <div class="stat-val" id="dbMs">-</div>
                    <div class="stat-change up">MySQL 정상</div>
                </div>
            </div>

            <!-- 패널 -->
            <div class="panel-grid">
                <!-- 최근 가입 사용자 (실제 데이터는 서블릿/DB에서 불러와야 함) -->
                <div class="panel">
                    <div class="panel-title">최근 가입 사용자</div>
                    <div id="recentUsers">
                        <div class="list-item">
                            <div>
                                <div class="li-name">데이터 로딩 중...</div>
                                <div class="li-sub">UserListServlet 연동 필요</div>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 최근 로그인 이력 -->
                <div class="panel">
                    <div class="panel-title">최근 로그인 이력</div>
                    <div id="loginLog">
                        <div class="list-item">
                            <div>
                                <div class="li-name"><%= loginUser %></div>
                                <div class="li-sub"><%= request.getRemoteAddr() %> · 방금</div>
                            </div>
                            <span class="chip chip-g">성공</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <script>
        // DB 응답 시간 측정 (ping용 fetch)
        const t0 = performance.now();
        fetch('DashboardServlet?action=stats')
            .then(r => r.json())
            .then(d => {
                const ms = Math.round(performance.now() - t0);
                document.getElementById('dbMs').textContent     = ms + 'ms';
                document.getElementById('totalUsers').textContent = d.totalUsers  ?? '-';
                document.getElementById('todayLogin').textContent = d.todayLogin  ?? '-';
                document.getElementById('totalBoard').textContent = d.totalBoard  ?? '-';
                document.getElementById('userChange').textContent = '이번 달 신규 ' + (d.newUsers ?? 0) + '명';
                document.getElementById('boardChange').textContent = '오늘 +' + (d.todayBoard ?? 0);

                if (d.recentUsers && d.recentUsers.length) {
                    document.getElementById('recentUsers').innerHTML = d.recentUsers.map(u => `
                        <div class="list-item">
                            <div>
                                <div class="li-name">\${u.name}</div>
                                <div class="li-sub">\${u.email}</div>
                            </div>
                            <span class="chip \${ u.useYn === 'Y' ? 'chip-g' : 'chip-r' }">
                                \${ u.useYn === 'Y' ? '활성' : '정지' }
                            </span>
                        </div>`).join('');
                }

                if (d.loginLogs && d.loginLogs.length) {
                    document.getElementById('loginLog').innerHTML = d.loginLogs.map(l => `
                        <div class="list-item">
                            <div>
                                <div class="li-name">\${l.userId}</div>
                                <div class="li-sub">\${l.ipAddr} · ${l.loginDt}</div>
                            </div>
                            <span class="chip \${ l.result === 'S' ? 'chip-g' : 'chip-r' }">
                                \${ l.result === 'S' ? '성공' : '실패' }
                            </span>
                        </div>`).join('');
                }
            })
            .catch(() => {
                document.getElementById('dbMs').textContent = '연결 오류';
            });
    function toggleUserMenu(row) {
        const menu = document.getElementById('userMenu');
        if (!menu) return;
        const open = menu.classList.toggle('open');
        row.classList.toggle('open', open);
    }
    document.addEventListener('click', function(e) {
        const menu = document.getElementById('userMenu');
        const row  = document.querySelector('.user-row');
        if (menu && row && !row.contains(e.target) && !menu.contains(e.target)) {
            menu.classList.remove('open');
            row.classList.remove('open');
        }
    });
    </script>
<script src="js/common.js"></script>
</body>
</html>

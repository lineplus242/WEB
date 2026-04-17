<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, javax.naming.*, javax.sql.DataSource" %>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("login.jsp"); return; }
    String loginUser = (String) session.getAttribute("loginUser");
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");

    // DB 연결 상태 확인
    String dbStatus = "unknown";
    String dbMessage = "";
    try {
        Context ctx = new InitialContext();
        DataSource ds = (DataSource) ctx.lookup("java:comp/env/jdbc/adminDB");
        try (Connection conn = ds.getConnection()) {
            dbStatus = conn.isValid(2) ? "ok" : "fail";
            dbMessage = conn.isValid(2) ? "연결 정상" : "연결 실패";
        }
    } catch (Exception e) {
        dbStatus = "fail";
        dbMessage = "연결 오류: " + e.getMessage();
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>설정 - 관리 시스템</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <script>(function(){if(localStorage.getItem('theme')==='light')document.documentElement.setAttribute('data-theme','light');})()</script>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'DM Sans', sans-serif; background: #0e0f11; color: #e8e9eb; min-height: 100vh; display: flex; }

        .sidebar { width: 220px; background: #0b0c0f; border-right: 1px solid #1e2025; display: flex; flex-direction: column; position: fixed; top: 0; left: 0; height: 100vh; z-index: 100; }
        .sb-brand { display: flex; align-items: center; gap: 10px; padding: 20px 20px 16px; border-bottom: 1px solid #1e2025; }
        .sb-icon { width: 28px; height: 28px; background: #3b6ef5; border-radius: 7px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
        .sb-icon svg { width: 15px; height: 15px; fill: #fff; }
        .sb-name { font-size: 13px; font-weight: 500; color: #e8e9eb; }
        .sb-dot { color: #3b6ef5; }
        .sb-section { padding: 16px 20px 6px; font-size: 10px; font-weight: 500; color: #3d4251; letter-spacing: 0.08em; text-transform: uppercase; }
        .sb-item { display: flex; align-items: center; gap: 10px; padding: 8px 12px; border-radius: 7px; margin: 1px 8px; font-size: 13px; color: #6b7280; text-decoration: none; transition: background 0.12s; }
        .sb-item:hover { background: #161820; color: #c8cad0; }
        .sb-item.active { background: #1a1e2e; color: #6b9af5; }
        .sb-item svg { width: 15px; height: 15px; flex-shrink: 0; opacity: 0.7; }
        .sb-item.active svg { opacity: 1; }
        .sb-bottom { margin-top: auto; border-top: 1px solid #1e2025; padding: 12px; }
        .user-row { display:flex;align-items:center;gap:10px;padding:8px;border-radius:8px;cursor:pointer;transition:background .12s; }
        .user-row:hover,.user-row.open { background:#161820; }
        .avatar { width:30px;height:30px;border-radius:50%;background:#1a1e2e;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:500;color:#6b9af5;flex-shrink:0; }
        .user-info p { font-size:12px;font-weight:500;color:#c8cad0; }
        .user-info span { font-size:11px;color:#3d4251; }
        .user-chevron { width:12px;height:12px;margin-left:auto;flex-shrink:0;color:#3d4251;transition:transform .2s; }
        .user-row.open .user-chevron { transform:rotate(180deg); }
        .user-menu { display:none;background:#1a1c22;border:1px solid #252830;border-radius:10px;padding:5px;margin-bottom:4px; }
        .user-menu.open { display:block; }
        .user-menu-item { display:flex;align-items:center;gap:8px;padding:8px 10px;border-radius:7px;font-size:12px;color:#c8cad0;text-decoration:none;transition:background .12s;width:100%;border:none;background:none;cursor:pointer;font-family:inherit; }
        .user-menu-item:hover { background:#252830; }
        .user-menu-item.danger { color:#e05656; }
        .user-menu-item.danger:hover { background:#2a1015; }

        .main { margin-left: 220px; flex: 1; display: flex; flex-direction: column; }
        .topbar { height: 52px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; justify-content: space-between; padding: 0 28px; background: #0e0f11; position: sticky; top: 0; z-index: 50; }
        .topbar-title { font-size: 14px; font-weight: 500; color: #f2f3f5; }
        .content { padding: 28px; max-width: 640px; }

        .section-label { font-size: 11px; font-weight: 500; color: #9ca3af; letter-spacing: 0.06em; text-transform: uppercase; margin-bottom: 12px; }

        /* 카드 */
        .card { background: #131519; border: 1px solid #1e2025; border-radius: 12px; margin-bottom: 20px; overflow: hidden; }
        .card-header { padding: 14px 20px; border-bottom: 1px solid #1e2025; font-size: 11px; font-weight: 500; color: #9ca3af; letter-spacing: 0.05em; text-transform: uppercase; }
        .card-body { padding: 20px; }

        /* 테마 선택 카드들 */
        .theme-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
        .theme-card { border: 2px solid #252830; border-radius: 10px; padding: 16px; cursor: pointer; transition: border-color .15s, background .15s; position: relative; }
        .theme-card:hover { border-color: #3b6ef5; }
        .theme-card.selected { border-color: #3b6ef5; background: #0e1428; }
        .theme-card .preview { border-radius: 6px; height: 80px; margin-bottom: 12px; overflow: hidden; display: flex; flex-direction: column; }
        .theme-card .preview-sidebar { width: 40px; height: 100%; flex-shrink: 0; }
        .theme-card .preview-content { flex: 1; padding: 6px; }
        .preview-row { height: 6px; border-radius: 3px; margin-bottom: 4px; }

        /* 다크 프리뷰 */
        .dark-preview { background: #0e0f11; display: flex; }
        .dark-preview .preview-sidebar { background: #0b0c0f; border-right: 1px solid #1e2025; }
        .dark-preview .preview-content { background: #0e0f11; }
        .dark-preview .preview-row { background: #1e2025; }
        .dark-preview .preview-row:first-child { background: #1a1e2e; width: 70%; }

        /* 라이트 프리뷰 */
        .light-preview { background: #f4f5f7; display: flex; }
        .light-preview .preview-sidebar { background: #ffffff; border-right: 1px solid #e2e4e9; }
        .light-preview .preview-content { background: #f4f5f7; }
        .light-preview .preview-row { background: #e2e4e9; }
        .light-preview .preview-row:first-child { background: #dce8ff; width: 70%; }

        .theme-name { font-size: 13px; font-weight: 500; color: #c8cad0; margin-bottom: 2px; }
        .theme-desc { font-size: 11px; color: #4b5161; }
        .theme-check { position: absolute; top: 10px; right: 10px; width: 18px; height: 18px; border-radius: 50%; background: #3b6ef5; display: none; align-items: center; justify-content: center; }
        .theme-card.selected .theme-check { display: flex; }
        .theme-check svg { width: 10px; height: 10px; stroke: #fff; }

        /* DB 상태 */
        .db-row { display: flex; align-items: center; gap: 12px; }
        .db-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
        .db-dot.ok   { background: #22c97a; box-shadow: 0 0 6px rgba(34,201,122,.5); }
        .db-dot.fail { background: #e05656; box-shadow: 0 0 6px rgba(224,86,86,.5); }
        .db-dot.unknown { background: #4b5161; }
        .db-label { font-size: 13px; color: #c8cad0; }
        .db-msg { font-size: 11px; color: #4b5161; margin-left: auto; }
        .db-refresh { margin-left: 8px; padding: 4px 10px; border-radius: 6px; font-size: 11px; background: #1a1c22; border: 1px solid #252830; color: #6b7280; cursor: pointer; font-family: inherit; transition: background .12s; text-decoration: none; }
        .db-refresh:hover { background: #252830; color: #c8cad0; }
    </style>
    <link rel="stylesheet" href="style/light.css">
</head>
<body>
    <nav class="sidebar">
        <div class="sb-brand">
            <div class="sb-icon"><svg viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/></svg></div>
            <span class="sb-name">ADMIN<span class="sb-dot">.</span>SYS</span>
        </div>
        <div class="sb-section">메뉴</div>
        <a href="main.jsp" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>
            대시보드
        </a>
        <a href="CustomerServlet?action=list" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><path d="M9 22V12h6v10"/></svg>
            고객사 정보
        </a>
        <% if ("ADMIN".equals(loginRole)) { %>
        <a href="UserServlet?action=list" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/></svg>
            사용자 관리
        </a>
        <% } %>
        <a href="SecurityScan?action=list" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            보안점검
        </a>
        <div class="sb-section">계정</div>
        <a href="UserServlet?action=changePw" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
            비밀번호 변경
        </a>
        <div class="sb-section">시스템</div>
        <a href="settings.jsp" class="sb-item active">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.07 4.93a10 10 0 010 14.14M4.93 4.93a10 10 0 000 14.14"/></svg>
            설정
        </a>
        <% if ("ADMIN".equals(loginRole)) { %>
        <a href="admin/image_library.jsp" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>
            이미지 라이브러리
        </a>
        <% } %>
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

    <div class="main">
        <div class="topbar">
            <span class="topbar-title">설정</span>
            <div class="theme-toggle">
                <button class="theme-toggle-btn" id="btnDark"  onclick="setTheme('dark')">다크모드</button>
                <button class="theme-toggle-btn" id="btnLight" onclick="setTheme('light')">라이트모드</button>
            </div>
        </div>
        <div class="content">

            <!-- 테마 설정 -->
            <div class="card">
                <div class="card-header">테마 설정</div>
                <div class="card-body">
                    <div class="theme-grid">
                        <div class="theme-card" id="themeCardDark" onclick="setTheme('dark')">
                            <div class="preview dark-preview">
                                <div class="preview-sidebar"></div>
                                <div class="preview-content">
                                    <div class="preview-row" style="width:60%"></div>
                                    <div class="preview-row" style="width:40%"></div>
                                    <div class="preview-row" style="width:80%"></div>
                                </div>
                            </div>
                            <div class="theme-name">다크 모드</div>
                            <div class="theme-desc">어두운 배경 · 기본값</div>
                            <div class="theme-check">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
                            </div>
                        </div>
                        <div class="theme-card" id="themeCardLight" onclick="setTheme('light')">
                            <div class="preview light-preview">
                                <div class="preview-sidebar"></div>
                                <div class="preview-content">
                                    <div class="preview-row" style="width:60%"></div>
                                    <div class="preview-row" style="width:40%"></div>
                                    <div class="preview-row" style="width:80%"></div>
                                </div>
                            </div>
                            <div class="theme-name">라이트 모드</div>
                            <div class="theme-desc">밝은 배경 · 주간 사용 권장</div>
                            <div class="theme-check">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3"><polyline points="20 6 9 17 4 12"/></svg>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <!-- 시스템 정보 -->
            <div class="card">
                <div class="card-header">시스템 정보</div>
                <div class="card-body">
                    <div class="db-row">
                        <div class="db-dot <%= dbStatus %>"></div>
                        <span class="db-label">데이터베이스 연결</span>
                        <span class="db-msg"><%= dbMessage %></span>
                        <a href="settings.jsp" class="db-refresh">새로고침</a>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <script>
    function setTheme(theme) {
        localStorage.setItem('theme', theme);
        if (theme === 'light') {
            document.documentElement.setAttribute('data-theme', 'light');
        } else {
            document.documentElement.removeAttribute('data-theme');
        }
        updateThemeCards(theme);
        document.getElementById('btnDark').classList.toggle('active', theme !== 'light');
        document.getElementById('btnLight').classList.toggle('active', theme === 'light');
    }

    function updateThemeCards(theme) {
        const dark  = document.getElementById('themeCardDark');
        const light = document.getElementById('themeCardLight');
        if (theme === 'light') {
            dark.classList.remove('selected');
            light.classList.add('selected');
        } else {
            light.classList.remove('selected');
            dark.classList.add('selected');
        }
    }

    // 페이지 로드 시 현재 테마 반영
    (function() {
        const t = localStorage.getItem('theme') || 'dark';
        updateThemeCards(t);
        document.getElementById('btnDark').classList.toggle('active', t !== 'light');
        document.getElementById('btnLight').classList.toggle('active', t === 'light');
    })();

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

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("login.jsp"); return; }
    String loginUser = (String) session.getAttribute("loginUser");
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>마이페이지 - 관리 시스템</title>
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
        .topbar { height: 52px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; padding: 0 28px; background: #0e0f11; position: sticky; top: 0; z-index: 50; }
        .topbar-title { font-size: 14px; font-weight: 500; color: #f2f3f5; }
        .content { padding: 28px; max-width: 520px; }

        .profile-header { display: flex; align-items: center; gap: 16px; margin-bottom: 24px; }
        .profile-avatar { width: 56px; height: 56px; border-radius: 50%; background: #1a1e2e; display: flex; align-items: center; justify-content: center; font-size: 20px; font-weight: 500; color: #6b9af5; flex-shrink: 0; border: 2px solid #252d44; }
        .profile-name { font-size: 18px; font-weight: 500; color: #f2f3f5; }
        .profile-role { font-size: 12px; color: #4b5161; margin-top: 3px; }

        .card { background: #131519; border: 1px solid #1e2025; border-radius: 12px; margin-bottom: 16px; overflow: hidden; }
        .card-header { padding: 14px 20px; border-bottom: 1px solid #1e2025; font-size: 11px; font-weight: 500; color: #9ca3af; letter-spacing: 0.05em; text-transform: uppercase; }
        .card-body { padding: 20px; }

        .info-row { display: flex; align-items: center; padding: 9px 0; border-bottom: 1px solid #1e2025; }
        .info-row:last-child { border-bottom: none; }
        .info-label { font-size: 12px; color: #4b5161; width: 100px; flex-shrink: 0; }
        .info-value { font-size: 13px; color: #c8cad0; }

        .card-actions { padding: 14px 20px; border-top: 1px solid #1e2025; display: flex; justify-content: flex-end; }
        .btn { padding: 8px 18px; border-radius: 8px; font-size: 13px; font-family: 'DM Sans', sans-serif; cursor: pointer; border: none; font-weight: 500; transition: background 0.15s; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; }
        .btn-secondary { background: #1a1e2e; color: #6b9af5; border: 1px solid #252d44; }
        .btn-secondary:hover { background: #202540; }
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
        <div class="sb-section">계정</div>
        <a href="UserServlet?action=changePw" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
            비밀번호 변경
        </a>
        <div class="sb-section">시스템</div>
        <a href="settings.jsp" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.07 4.93a10 10 0 010 14.14M4.93 4.93a10 10 0 000 14.14"/></svg>
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

    <div class="main">
        <div class="topbar">
            <span class="topbar-title">마이페이지</span>
            <div class="theme-toggle">
                <button class="theme-toggle-btn" id="btnDark"  onclick="setTheme('dark')">다크모드</button>
                <button class="theme-toggle-btn" id="btnLight" onclick="setTheme('light')">라이트모드</button>
            </div>
        </div>
        <div class="content">

            <div class="profile-header">
                <div class="profile-avatar"><%= loginName != null ? String.valueOf(loginName.charAt(0)) : "관" %></div>
                <div>
                    <div class="profile-name"><%= loginName != null ? loginName : loginUser %></div>
                    <div class="profile-role"><%= loginRole != null ? loginRole : "USER" %></div>
                </div>
            </div>

            <div class="card">
                <div class="card-header">계정 정보</div>
                <div class="card-body">
                    <div class="info-row">
                        <span class="info-label">아이디</span>
                        <span class="info-value"><%= loginUser %></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">이름</span>
                        <span class="info-value"><%= loginName != null ? loginName : "-" %></span>
                    </div>
                    <div class="info-row">
                        <span class="info-label">권한</span>
                        <span class="info-value"><%= loginRole != null ? loginRole : "USER" %></span>
                    </div>
                </div>
                <div class="card-actions">
                    <a href="UserServlet?action=changePw" class="btn btn-secondary">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:13px;height:13px"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
                        비밀번호 변경
                    </a>
                </div>
            </div>

        </div>
    </div>

    <script>
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
<script>
    function setTheme(t){localStorage.setItem('theme',t);if(t==='light')document.documentElement.setAttribute('data-theme','light');else document.documentElement.removeAttribute('data-theme');document.getElementById('btnDark').classList.toggle('active',t!=='light');document.getElementById('btnLight').classList.toggle('active',t==='light');}
    (function(){var t=localStorage.getItem('theme')||'dark';document.getElementById('btnDark').classList.toggle('active',t!=='light');document.getElementById('btnLight').classList.toggle('active',t==='light');})();
</script>
</body>
</html>

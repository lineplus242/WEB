<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("../login.jsp"); return; }
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");

    String errorMsg   = (String) request.getAttribute("errorMsg");
    String successMsg = (String) request.getAttribute("successMsg");
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>비밀번호 변경 - 관리 시스템</title>
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
        .content { padding: 28px; max-width: 480px; }

        .alert { padding: 12px 16px; border-radius: 8px; font-size: 13px; margin-bottom: 24px; }
        .alert-err { background: rgba(224,86,86,0.1); border: 1px solid rgba(224,86,86,0.3); color: #e05656; }
        .alert-ok  { background: rgba(34,201,122,0.1); border: 1px solid rgba(34,201,122,0.3); color: #22c97a; }

        .form-card { background: #131519; border: 1px solid #1e2025; border-radius: 12px; overflow: hidden; }
        .form-card-title { padding: 14px 20px; border-bottom: 1px solid #1e2025; font-size: 11px; font-weight: 500; color: #9ca3af; letter-spacing: 0.05em; text-transform: uppercase; }
        .form-body { padding: 24px 20px; display: flex; flex-direction: column; gap: 16px; }
        .form-group { display: flex; flex-direction: column; gap: 6px; }
        label { font-size: 11px; font-weight: 500; color: #6b7280; letter-spacing: 0.06em; text-transform: uppercase; }
        input[type=password] {
            background: #0e0f11; border: 1px solid #252830; border-radius: 8px;
            padding: 9px 12px; font-size: 13px; color: #e8e9eb;
            font-family: 'DM Sans', sans-serif; outline: none; transition: border 0.15s; width: 100%;
        }
        input:focus { border-color: #3b6ef5; }
        input::placeholder { color: #3d4251; }

        .strength-bar { height: 3px; border-radius: 2px; background: #1e2025; margin-top: 6px; overflow: hidden; }
        .strength-fill { height: 100%; width: 0; transition: width 0.3s, background 0.3s; border-radius: 2px; }
        .strength-label { font-size: 10px; color: #3d4251; margin-top: 4px; }

        .form-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 24px; }
        .btn { padding: 9px 22px; border-radius: 8px; font-size: 13px; font-family: 'DM Sans', sans-serif; cursor: pointer; border: none; font-weight: 500; transition: background 0.15s; text-decoration: none; display: inline-flex; align-items: center; }
        .btn-primary { background: #3b6ef5; color: #fff; }
        .btn-primary:hover { background: #2f5ee0; }
        .btn-secondary { background: #1a1e2e; color: #6b9af5; border: 1px solid #252d44; }
        .btn-secondary:hover { background: #202540; }
    </style>
    <link rel="stylesheet" href="../style/light.css">
</head>
<body>
    <nav class="sidebar">
        <div class="sb-brand">
            <div class="sb-icon"><svg viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/></svg></div>
            <span class="sb-name">ADMIN<span class="sb-dot">.</span>SYS</span>
        </div>
        <div class="sb-section">메뉴</div>
        <a href="../main.jsp" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>
            대시보드
        </a>
        <a href="../CustomerServlet?action=list" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><path d="M9 22V12h6v10"/></svg>
            고객사 정보
        </a>
        <% if ("ADMIN".equals(loginRole)) { %>
        <a href="../UserServlet?action=list" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/></svg>
            사용자 관리
        </a>
        <% } %>
        
        <a href="../SecurityScan?action=list" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
            보안점검
        </a>
        <div class="sb-section">계정</div>
        <a href="../UserServlet?action=changePw" class="sb-item active">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
            비밀번호 변경
        </a>
        <div class="sb-section">시스템</div>
        <a href="../settings.jsp" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.07 4.93a10 10 0 010 14.14M4.93 4.93a10 10 0 000 14.14"/></svg>
            설정
        </a>
        <% if ("ADMIN".equals(loginRole)) { %>
        <a href="../admin/image_library.jsp" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>
            이미지 라이브러리
        </a>
        <% } %>
        <div class="sb-bottom">
            <div id="userMenu" class="user-menu">
                <a href="../mypage.jsp" class="user-menu-item">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px;flex-shrink:0"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                    마이페이지
                </a>
                <div style="height:1px;background:#252830;margin:4px 2px"></div>
                <a href="../LogoutServlet" class="user-menu-item danger">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px;flex-shrink:0"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                    로그아웃
                </a>
            </div>
            <div class="user-row" onclick="toggleUserMenu(this)">
                <div class="avatar"><%= loginName != null ? String.valueOf(loginName.charAt(0)) : "관" %></div>
                <div class="user-info"><p><%= loginName != null ? loginName : "관리자" %></p><span><%= loginRole != null ? loginRole : "USER" %></span></div>
                <svg class="user-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"/></svg>
            </div>
        </div>
    </nav>

    <div class="main">
        <div class="topbar">
            <span class="topbar-title">비밀번호 변경</span>
            <div class="theme-toggle">
                <button class="theme-toggle-btn" id="btnDark"  onclick="setTheme('dark')">다크모드</button>
                <button class="theme-toggle-btn" id="btnLight" onclick="setTheme('light')">라이트모드</button>
            </div>
        </div>
        <div class="content">

            <% if (errorMsg != null) { %>
            <div class="alert alert-err"><%= errorMsg %></div>
            <% } %>
            <% if (successMsg != null) { %>
            <div class="alert alert-ok"><%= successMsg %></div>
            <% } %>

            <form action="../UserServlet" method="post" id="pwForm">
                <input type="hidden" name="action" value="changePw">

                <div class="form-card">
                    <div class="form-card-title">비밀번호 변경</div>
                    <div class="form-body">
                        <div class="form-group">
                            <label>현재 비밀번호</label>
                            <input type="password" name="currentPw" id="currentPw" required placeholder="현재 비밀번호 입력" autocomplete="current-password">
                        </div>
                        <div class="form-group">
                            <label>새 비밀번호</label>
                            <input type="password" name="newPw" id="newPw" required placeholder="6자 이상" autocomplete="new-password">
                            <div class="strength-bar"><div class="strength-fill" id="strengthFill"></div></div>
                            <span class="strength-label" id="strengthLabel"></span>
                        </div>
                        <div class="form-group">
                            <label>새 비밀번호 확인</label>
                            <input type="password" name="confirmPw" id="confirmPw" required placeholder="새 비밀번호 재입력" autocomplete="new-password">
                        </div>
                    </div>
                </div>

                <div class="form-actions">
                    <a href="../main.jsp" class="btn btn-secondary">취소</a>
                    <button type="submit" class="btn btn-primary">변경하기</button>
                </div>
            </form>
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

        const newPw = document.getElementById('newPw');
        const fill  = document.getElementById('strengthFill');
        const label = document.getElementById('strengthLabel');
        const confirmPw = document.getElementById('confirmPw');

        newPw.addEventListener('input', () => {
            const v = newPw.value;
            let score = 0;
            if (v.length >= 6)  score++;
            if (v.length >= 10) score++;
            if (/[A-Z]/.test(v) || /[0-9]/.test(v)) score++;
            if (/[^A-Za-z0-9]/.test(v)) score++;

            const levels = [
                { w: '0%',   c: '#e05656', t: '' },
                { w: '30%',  c: '#e05656', t: '약함' },
                { w: '55%',  c: '#d4a017', t: '보통' },
                { w: '80%',  c: '#3b6ef5', t: '강함' },
                { w: '100%', c: '#22c97a', t: '매우 강함' },
            ];
            fill.style.width      = levels[score].w;
            fill.style.background = levels[score].c;
            label.textContent     = levels[score].t;
            label.style.color     = levels[score].c;
        });

        document.getElementById('pwForm').addEventListener('submit', e => {
            if (newPw.value !== confirmPw.value) {
                e.preventDefault();
                confirmPw.style.borderColor = '#e05656';
                confirmPw.setCustomValidity('새 비밀번호가 일치하지 않습니다.');
                confirmPw.reportValidity();
            } else {
                confirmPw.style.borderColor = '';
                confirmPw.setCustomValidity('');
            }
        });

        confirmPw.addEventListener('input', () => {
            if (confirmPw.value === newPw.value) {
                confirmPw.style.borderColor = '#22c97a';
                confirmPw.setCustomValidity('');
            } else {
                confirmPw.style.borderColor = '#e05656';
            }
        });
    </script>
<script src="../js/common.js"></script>
<script>
    function setTheme(t){localStorage.setItem('theme',t);if(t==='light')document.documentElement.setAttribute('data-theme','light');else document.documentElement.removeAttribute('data-theme');document.getElementById('btnDark').classList.toggle('active',t!=='light');document.getElementById('btnLight').classList.toggle('active',t==='light');}
    (function(){var t=localStorage.getItem('theme')||'dark';document.getElementById('btnDark').classList.toggle('active',t!=='light');document.getElementById('btnLight').classList.toggle('active',t==='light');})();
</script>
</body>
</html>

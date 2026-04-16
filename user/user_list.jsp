<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.admin.servlet.UserServlet.UserVO, java.util.List" %>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("../login.jsp"); return; }
    String loginUser = (String) session.getAttribute("loginUser");
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");

    if (!"ADMIN".equals(loginRole)) { response.sendError(403, "권한이 없습니다."); return; }

    List<UserVO> list      = (List<UserVO>) request.getAttribute("list");
    int totalCnt           = request.getAttribute("totalCnt")   != null ? (int) request.getAttribute("totalCnt")   : 0;
    int totalPages         = request.getAttribute("totalPages") != null ? (int) request.getAttribute("totalPages") : 1;
    int curPage            = request.getAttribute("page")       != null ? (int) request.getAttribute("page")       : 1;
    String keyword         = request.getAttribute("keyword")    != null ? (String) request.getAttribute("keyword") : "";
    String errorParam      = request.getParameter("error");
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>사용자 관리 - 관리 시스템</title>
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
        .content { padding: 28px; }

        .toolbar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; gap: 12px; }
        .search-box { display: flex; gap: 8px; align-items: center; }
        .search-input { background: #131519; border: 1px solid #252830; border-radius: 8px; padding: 8px 12px; font-size: 13px; color: #e8e9eb; font-family: 'DM Sans', sans-serif; outline: none; width: 220px; }
        .search-input:focus { border-color: #3b6ef5; }
        .search-input::placeholder { color: #3d4251; }

        .btn { padding: 8px 18px; border-radius: 8px; font-size: 13px; font-family: 'DM Sans', sans-serif; cursor: pointer; border: none; font-weight: 500; transition: background 0.15s; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; }
        .btn-primary { background: #3b6ef5; color: #fff; }
        .btn-primary:hover { background: #2f5ee0; }
        .btn-secondary { background: #1a1e2e; color: #6b9af5; border: 1px solid #252d44; }
        .btn-secondary:hover { background: #202540; }
        .btn-danger { background: #2a0d0d; color: #e05656; border: 1px solid #3d1515; }
        .btn-danger:hover { background: #3d1212; }
        .btn-sm { padding: 5px 12px; font-size: 12px; }

        .info-bar { font-size: 12px; color: #4b5161; }
        .info-bar strong { color: #9ca3af; }

        .table-wrap { background: #131519; border: 1px solid #1e2025; border-radius: 12px; overflow: hidden; }
        table { width: 100%; border-collapse: collapse; }
        thead tr { background: #0f1115; }
        th { padding: 11px 16px; font-size: 10px; font-weight: 500; color: #4b5161; letter-spacing: 0.07em; text-transform: uppercase; text-align: left; border-bottom: 1px solid #1e2025; }
        td { padding: 12px 16px; font-size: 13px; color: #c8cad0; border-bottom: 1px solid #141618; vertical-align: middle; }
        tbody tr:last-child td { border-bottom: none; }
        tbody tr:hover td { background: #161820; }

        .td-mono { font-family: 'DM Mono', monospace; font-size: 12px; color: #6b9af5; }
        .td-actions { display: flex; gap: 6px; }

        .chip { font-size: 11px; padding: 4px 11px; border-radius: 99px; font-family: 'Pretendard', system-ui, sans-serif; font-weight: 500; display: inline-flex; align-items: center; border: none; }
        .chip-admin { background: rgba(167,139,250,0.1); color: #a78bfa; }
        .chip-user  { background: rgba(90,128,208,0.1);  color: #5a80d0; }
        .chip-on  { background: #0d2a1a; color: #22c97a; border: 1px solid #0f3d25; }
        .chip-off { background: #2a0d0d; color: #e05656; border: 1px solid #3d0f0f; }

        .pagination { display: flex; align-items: center; justify-content: center; gap: 4px; margin-top: 20px; }
        .pg-btn { padding: 6px 12px; border-radius: 6px; font-size: 12px; background: #131519; border: 1px solid #1e2025; color: #6b7280; text-decoration: none; transition: background 0.12s; }
        .pg-btn:hover { background: #1a1e2e; color: #c8cad0; }
        .pg-btn.active { background: #1a1e2e; color: #6b9af5; border-color: #252d44; }

        .alert { padding: 10px 16px; border-radius: 8px; font-size: 13px; margin-bottom: 16px; }
        .alert-err  { background: rgba(224,86,86,0.1); border: 1px solid rgba(224,86,86,0.3); color: #e05656; }
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
        <a href="../UserServlet?action=list" class="sb-item active">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/></svg>
            사용자 관리
        </a>
        <div class="sb-section">계정</div>
        <a href="../UserServlet?action=changePw" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
            비밀번호 변경
        </a>
        <div class="sb-section">시스템</div>
        <a href="../settings.jsp" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.07 4.93a10 10 0 010 14.14M4.93 4.93a10 10 0 000 14.14"/></svg>
            설정
        </a>
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
                <div class="user-info"><p><%= loginName %></p><span><%= loginRole %></span></div>
                <svg class="user-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"/></svg>
            </div>
        </div>
    </nav>

    <div class="main">
        <div class="topbar">
            <span class="topbar-title">사용자 관리</span>
        </div>
        <div class="content">

            <% if ("self".equals(errorParam)) { %>
            <div class="alert alert-err">본인 계정은 삭제할 수 없습니다.</div>
            <% } %>

            <div class="toolbar">
                <form method="get" action="../UserServlet" class="search-box">
                    <input type="hidden" name="action" value="list">
                    <input type="text" name="keyword" class="search-input" placeholder="아이디 · 이름 검색" value="<%= keyword %>">
                    <button type="submit" class="btn btn-secondary btn-sm">검색</button>
                </form>
                <div style="display:flex;align-items:center;gap:12px">
                    <span class="info-bar">전체 <strong><%= totalCnt %></strong>명</span>
                    <a href="../UserServlet?action=form" class="btn btn-primary btn-sm">
                        <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                        신규 등록
                    </a>
                </div>
            </div>

            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>아이디</th>
                            <th>이름</th>
                            <th>이메일</th>
                            <th>권한</th>
                            <th>상태</th>
                            <th>등록일</th>
                            <th>관리</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (list == null || list.isEmpty()) { %>
                        <tr><td colspan="7" style="text-align:center;color:#3d4251;padding:32px">등록된 사용자가 없습니다.</td></tr>
                        <% } else { for (UserVO u : list) { %>
                        <tr>
                            <td class="td-mono"><%= u.userId %></td>
                            <td><strong style="color:#e8e9eb"><%= u.userName %></strong></td>
                            <td style="font-size:12px;color:#6b7280"><%= u.email != null ? u.email : "-" %></td>
                            <td><span class="chip <%= "ADMIN".equals(u.role) ? "chip-admin" : "chip-user" %>"><%= u.role %></span></td>
                            <td><span class="chip <%= "Y".equals(u.useYn) ? "chip-on" : "chip-off" %>"><%= "Y".equals(u.useYn) ? "활성" : "비활성" %></span></td>
                            <td style="font-size:12px;color:#4b5161"><%= u.regDt != null ? u.regDt.substring(0,10) : "-" %></td>
                            <td>
                                <div class="td-actions">
                                    <a href="../UserServlet?action=form&userSeq=<%= u.userSeq %>" class="btn btn-sm btn-secondary">수정</a>
                                    <% if (!u.userId.equals(loginUser)) { %>
                                    <form action="../UserServlet" method="post" style="display:inline"
                                          onsubmit="return confirm('<%= u.userName %> 계정을 삭제하시겠습니까?')">
                                        <input type="hidden" name="action" value="delete">
                                        <input type="hidden" name="userSeq" value="<%= u.userSeq %>">
                                        <button type="submit" class="btn btn-sm btn-danger">삭제</button>
                                    </form>
                                    <% } %>
                                </div>
                            </td>
                        </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>

            <% if (totalPages > 1) { %>
            <div class="pagination">
                <% if (curPage > 1) { %><a href="../UserServlet?action=list&page=<%= curPage-1 %>&keyword=<%= keyword %>" class="pg-btn">‹</a><% } %>
                <% for (int i = 1; i <= totalPages; i++) { %>
                <a href="../UserServlet?action=list&page=<%= i %>&keyword=<%= keyword %>" class="pg-btn <%= i == curPage ? "active" : "" %>"><%= i %></a>
                <% } %>
                <% if (curPage < totalPages) { %><a href="../UserServlet?action=list&page=<%= curPage+1 %>&keyword=<%= keyword %>" class="pg-btn">›</a><% } %>
            </div>
            <% } %>

        </div>
    </div>
<script>
function toggleUserMenu(row){const m=document.getElementById('userMenu');if(!m)return;const o=m.classList.toggle('open');row.classList.toggle('open',o);}
document.addEventListener('click',function(e){const m=document.getElementById('userMenu'),r=document.querySelector('.user-row');if(m&&r&&!r.contains(e.target)&&!m.contains(e.target)){m.classList.remove('open');r.classList.remove('open');}});
</script>
<script src="../js/common.js"></script>
</body>
</html>

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.admin.servlet.CustomerServlet.CustomerVO" %>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("../login.jsp"); return; }
    String loginName = (String) session.getAttribute("loginName");
    String loginUser = (String) session.getAttribute("loginUser");
    String loginRole = (String) session.getAttribute("loginRole");

    List<CustomerVO> list  = (List<CustomerVO>) request.getAttribute("list");
    int    totalCnt   = (Integer)  nvl(request.getAttribute("totalCnt"),   0);
    int    totalPages = (Integer)  nvl(request.getAttribute("totalPages"), 1);
    int    pageNum    = (Integer)  nvl(request.getAttribute("page"),       1);
    String keyword    = nvl2((String) request.getAttribute("keyword"), "");
    String status     = nvl2((String) request.getAttribute("status"),  "");
    if (list == null) list = new java.util.ArrayList<>();
%>
<%!
    Object nvl(Object val, Object def) { return val != null ? val : def; }
    String nvl2(String s, String def)  { return (s != null && !s.isEmpty()) ? s : def; }
    String statusLabel(String s) {
        if (s == null) return "-";
        if ("ACTIVE".equals(s))   return "활성";
        if ("INACTIVE".equals(s)) return "비활성";
        if ("PENDING".equals(s))  return "대기";
        return s;
    }
    String statusChip(String s) {
        if (s == null) return "chip-y";
        if ("ACTIVE".equals(s))   return "chip-g";
        if ("INACTIVE".equals(s)) return "chip-r";
        return "chip-y";
    }
    String fmtAmt(long amt) {
        if (amt == 0) return "-";
        return String.format("%,d 원", amt);
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>고객사 관리 - 관리 시스템</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <script>(function(){if(localStorage.getItem('theme')==='light')document.documentElement.setAttribute('data-theme','light');})()</script>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'DM Sans', sans-serif; background: #0e0f11; color: #e8e9eb; min-height: 100vh; display: flex; }

        /* 사이드바 (main.jsp 와 동일) */
        .sidebar { width: 220px; background: #0b0c0f; border-right: 1px solid #1e2025; display: flex; flex-direction: column; position: fixed; top: 0; left: 0; height: 100vh; z-index: 100; }
        .sb-brand { display: flex; align-items: center; gap: 10px; padding: 20px 20px 16px; border-bottom: 1px solid #1e2025; }
        .sb-icon { width: 28px; height: 28px; background: #3b6ef5; border-radius: 7px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
        .sb-icon svg { width: 15px; height: 15px; fill: #fff; }
        .sb-name { font-size: 13px; font-weight: 500; color: #e8e9eb; letter-spacing: 0.02em; }
        .sb-dot { color: #3b6ef5; }
        .sb-section { padding: 16px 20px 6px; font-size: 10px; font-weight: 500; color: #3d4251; letter-spacing: 0.08em; text-transform: uppercase; }
        .sb-item { display: flex; align-items: center; gap: 10px; padding: 8px 12px; border-radius: 7px; margin: 1px 8px; font-size: 13px; color: #6b7280; cursor: pointer; text-decoration: none; transition: background 0.12s; }
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

        /* 메인 */
        .main { margin-left: 220px; flex: 1; display: flex; flex-direction: column; min-height: 100vh; }
        .topbar { height: 52px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; justify-content: space-between; padding: 0 28px; background: #0e0f11; position: sticky; top: 0; z-index: 50; }
        .topbar-title { font-size: 14px; font-weight: 500; color: #f2f3f5; }
        .content { padding: 28px; }

        /* 검색 영역 */
        .search-bar { display: flex; gap: 10px; margin-bottom: 20px; align-items: center; flex-wrap: wrap; }
        .search-bar input[type=text], .search-bar select {
            background: #131519; border: 1px solid #1e2025; border-radius: 8px;
            padding: 8px 14px; font-size: 13px; color: #e8e9eb;
            font-family: 'DM Sans', sans-serif; outline: none; transition: border 0.15s;
        }
        .search-bar input[type=text] { width: 240px; }
        .search-bar input[type=text]:focus, .search-bar select:focus { border-color: #3b6ef5; }
        .search-bar select option { background: #131519; }
        .btn { padding: 8px 18px; border-radius: 8px; font-size: 13px; font-family: 'DM Sans', sans-serif; cursor: pointer; border: none; transition: background 0.15s; }
        .btn-primary { background: #3b6ef5; color: #fff; }
        .btn-primary:hover { background: #2f5ee0; }
        .btn-secondary { background: #1a1e2e; color: #6b9af5; border: 1px solid #252d44; }
        .btn-secondary:hover { background: #202540; }
        .btn-sm { padding: 5px 12px; font-size: 12px; border-radius: 6px; }
        .btn-danger { background: #2a0d0d; color: #e05656; border: 1px solid #3d0f0f; }
        .btn-danger:hover { background: #3d1212; }
        .ml-auto { margin-left: auto; }

        /* 테이블 */
        .table-wrap { background: #131519; border: 1px solid #1e2025; border-radius: 12px; overflow: hidden; }
        .table-info { padding: 14px 20px; border-bottom: 1px solid #1e2025; font-size: 12px; color: #4b5161; }
        .table-info strong { color: #9ca3af; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #0f1013; padding: 11px 16px; font-size: 11px; font-weight: 500; color: #6b7280; text-align: left; letter-spacing: 0.05em; text-transform: uppercase; border-bottom: 1px solid #1e2025; white-space: nowrap; }
        td { padding: 12px 16px; font-size: 13px; color: #c8cad0; border-bottom: 1px solid #161820; vertical-align: middle; }
        tr:last-child td { border-bottom: none; }
        tr:hover td { background: #161820; }
        .td-code { font-family: 'DM Mono', monospace; font-size: 12px; color: #5a80d0; }
        .td-amt  { font-family: 'DM Mono', monospace; font-size: 12px; text-align: right; }
        .td-actions { display: flex; gap: 6px; }
        .chip { font-size: 10px; padding: 3px 9px; border-radius: 4px; font-family: 'DM Mono', monospace; font-weight: 500; white-space: nowrap; }
        .chip-g { background: #0d2a1a; color: #22c97a; border: 1px solid #0f3d25; }
        .chip-r { background: #2a0d0d; color: #e05656; border: 1px solid #3d0f0f; }
        .chip-y { background: #2a200d; color: #d4a017; border: 1px solid #3d2e0f; }
        .empty-row td { text-align: center; padding: 48px; color: #3d4251; }

        /* 페이지네이션 */
        .pagination { display: flex; justify-content: center; gap: 4px; margin-top: 20px; }
        .page-btn { background: #131519; border: 1px solid #1e2025; border-radius: 6px; padding: 6px 12px; font-size: 12px; color: #6b7280; cursor: pointer; text-decoration: none; transition: background 0.12s; }
        .page-btn:hover { background: #1a1e2e; color: #c8cad0; }
        .page-btn.active { background: #1a1e2e; color: #6b9af5; border-color: #252d44; }
        .page-btn.disabled { opacity: 0.3; pointer-events: none; }
    </style>
    <link rel="stylesheet" href="../style/light.css">
</head>
<body>
    <!-- 사이드바 -->
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
        <a href="../CustomerServlet?action=list" class="sb-item active">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><path d="M9 22V12h6v10"/></svg>
            고객사 정보
        </a>
        <% if ("ADMIN".equals(loginRole)) { %>
        <a href="../UserServlet?action=list" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/></svg>
            사용자 관리
        </a>
        <% } %>
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

    <!-- 메인 -->
    <div class="main">
        <div class="topbar">
            <span class="topbar-title">고객사 관리</span>
        </div>
        <div class="content">

            <!-- 검색 -->
            <form action="../CustomerServlet" method="get" class="search-bar">
                <input type="hidden" name="action" value="list">
                <input type="text" name="keyword" placeholder="고객사명 / 담당자 / 코드 검색" value="<%= keyword %>">
                <select name="status">
                    <option value="">전체 상태</option>
                    <option value="ACTIVE"   <%= "ACTIVE".equals(status)   ? "selected" : "" %>>활성</option>
                    <option value="INACTIVE" <%= "INACTIVE".equals(status) ? "selected" : "" %>>비활성</option>
                    <option value="PENDING"  <%= "PENDING".equals(status)  ? "selected" : "" %>>대기</option>
                </select>
                <button type="submit" class="btn btn-secondary">검색</button>
                <a href="../CustomerServlet?action=form" class="btn btn-primary ml-auto">+ 신규 등록</a>
            </form>

            <!-- 테이블 -->
            <div class="table-wrap">
                <div class="table-info">전체 <strong><%= totalCnt %></strong>건 &nbsp;·&nbsp; <span style="color:#3d4251">행을 더블클릭하면 상세 페이지로 이동합니다</span></div>
                <table>
                    <thead>
                        <tr>
                            <th>코드</th>
                            <th>고객사명</th>
                            <th>업종</th>
                            <th>담당자</th>
                            <th>연락처</th>
                            <th>서비스</th>
                            <th>상태</th>
                            <th>관리</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (list.isEmpty()) { %>
                        <tr class="empty-row"><td colspan="8">등록된 고객사가 없습니다.</td></tr>
                        <% } else { for (CustomerVO c : list) { %>
                        <tr style="cursor:pointer" ondblclick="location.href='../CustomerDetailServlet?action=detail&custSeq=<%= c.custSeq %>'">
                            <td class="td-code"><%= c.custCode %></td>
                            <td><strong style="color:#e8e9eb"><%= c.custName %></strong></td>
                            <td><%= nvl2(c.industry, "-") %></td>
                            <td><%= nvl2(c.managerName, "-") %></td>
                            <td style="font-family:'DM Mono',monospace;font-size:12px"><%= nvl2(c.managerTel, "-") %></td>
                            <td><%= nvl2(c.serviceType, "-") %></td>
                            <td><span class="chip <%= statusChip(c.status) %>"><%= statusLabel(c.status) %></span></td>
                            <td>
                                <div class="td-actions">
                                    <a href="../CustomerServlet?action=form&custSeq=<%= c.custSeq %>" class="btn btn-sm btn-secondary">수정</a>
                                    <form action="../CustomerServlet" method="post" style="display:inline" onsubmit="return confirm('<%= c.custName %> 을(를) 삭제하시겠습니까?')">
                                        <input type="hidden" name="action" value="delete">
                                        <input type="hidden" name="custSeq" value="<%= c.custSeq %>">
                                        <button type="submit" class="btn btn-sm btn-danger">삭제</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>

            <!-- 페이지네이션 -->
            <% if (totalPages > 1) { %>
            <div class="pagination">
                <a href="../CustomerServlet?action=list&page=<%= pageNum-1 %>&keyword=<%= keyword %>&status=<%= status %>"
                   class="page-btn <%= pageNum <= 1 ? "disabled" : "" %>">◀</a>
                <% for (int i = 1; i <= totalPages; i++) { %>
                <a href="../CustomerServlet?action=list&page=<%= i %>&keyword=<%= keyword %>&status=<%= status %>"
                   class="page-btn <%= i == pageNum? "active" : "" %>"><%= i %></a>
                <% } %>
                <a href="../CustomerServlet?action=list&page=<%= pageNum+1 %>&keyword=<%= keyword %>&status=<%= status %>"
                   class="page-btn <%= pageNum >= totalPages ? "disabled" : "" %>">▶</a>
            </div>
            <% } %>

        </div>
    </div>
<script>
function toggleUserMenu(row){const m=document.getElementById('userMenu');if(!m)return;const o=m.classList.toggle('open');row.classList.toggle('open',o);}
document.addEventListener('click',function(e){const m=document.getElementById('userMenu'),r=document.querySelector('.user-row');if(m&&r&&!r.contains(e.target)&&!m.contains(e.target)){m.classList.remove('open');r.classList.remove('open');}});
</script>
</body>
</html>

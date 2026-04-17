<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.admin.servlet.SecurityScanServlet.*" %>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("../login.jsp"); return; }
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");

    List<ScanVO>     tabScans    = (List<ScanVO>)     request.getAttribute("tabScans");
    ScanVO           currentScan = (ScanVO)           request.getAttribute("currentScan");
    List<ScanItemVO> items       = (List<ScanItemVO>) request.getAttribute("items");
    Integer          batchId     = (Integer)          request.getAttribute("batchId");
    String           dbError     = (String)           request.getAttribute("dbError");

    if (tabScans == null) tabScans = new java.util.ArrayList<>();
    if (items    == null) items    = new java.util.ArrayList<>();
%>
<%!
    String nvl(String s) { return s != null ? s : ""; }
    String shortDate(String dt) { return (dt != null && dt.length() >= 10) ? dt.substring(0,10) : "-"; }
    String resultClass(String r) {
        if ("양호".equals(r)) return "chip-g";
        if ("취약".equals(r)) return "chip-r";
        if ("N/A".equals(r))  return "chip-na";
        return "chip-y";
    }
    String borderClass(String r) {
        if ("양호".equals(r)) return "border-ok";
        if ("취약".equals(r)) return "border-vuln";
        return "border-manual";
    }
    String escJs(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("'","\\'").replace("\r","").replace("\n","\\n");
    }
    String escHtml(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;");
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= currentScan != null ? nvl(currentScan.serverLabel) + " - 보안점검" : "보안점검 상세" %> - 관리 시스템</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
    <script>(function(){if(localStorage.getItem('theme')==='light')document.documentElement.setAttribute('data-theme','light');})()</script>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'DM Sans', sans-serif; background: #0e0f11; color: #e8e9eb; min-height: 100vh; display: flex; }

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
        .avatar { width: 30px; height: 30px; border-radius: 50%; background: #1a1e2e; display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 500; color: #6b9af5; flex-shrink: 0; }
        .user-info p { font-size: 12px; font-weight: 500; color: #c8cad0; }
        .user-info span { font-size: 11px; color: #3d4251; }
        .user-chevron { width:12px;height:12px;margin-left:auto;flex-shrink:0;color:#3d4251;transition:transform .2s; }
        .user-row.open .user-chevron { transform:rotate(180deg); }
        .user-menu { display:none;background:#1a1c22;border:1px solid #252830;border-radius:10px;padding:5px;margin-bottom:4px; }
        .user-menu.open { display:block; }
        .user-menu-item { display:flex;align-items:center;gap:8px;padding:8px 10px;border-radius:7px;font-size:12px;color:#c8cad0;text-decoration:none;transition:background .12s;width:100%;border:none;background:none;cursor:pointer;font-family:inherit; }
        .user-menu-item:hover { background:#252830; }
        .user-menu-item.danger { color:#e05656; }
        .user-menu-item.danger:hover { background:#2a1015; }

        .main { margin-left: 220px; flex: 1; display: flex; flex-direction: column; min-height: 100vh; }
        .topbar { height: 52px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; justify-content: space-between; padding: 0 28px; background: #0e0f11; position: sticky; top: 0; z-index: 50; }
        .topbar-left { display: flex; align-items: center; gap: 10px; }
        .topbar-title { font-size: 14px; font-weight: 500; color: #f2f3f5; }
        .back-btn { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #6b7280; text-decoration: none; padding: 5px 10px; border-radius: 6px; transition: background 0.12s; }
        .back-btn:hover { background: #161820; color: #c8cad0; }
        .content { padding: 28px; }

        .theme-toggle { display:flex;gap:4px;background:#0b0c0f;border:1px solid #1e2025;border-radius:8px;padding:3px; }
        .theme-toggle-btn { padding:4px 12px;font-size:11px;font-weight:500;border:none;background:none;color:#4b5161;cursor:pointer;border-radius:5px;font-family:'DM Sans',sans-serif;transition:background .12s,color .12s; }
        .theme-toggle-btn.active { background:#1a1e2e;color:#6b9af5; }

        /* 서버 탭 */
        .server-tabs { display: flex; gap: 4px; margin-bottom: 24px; border-bottom: 1px solid #1e2025; padding-bottom: 0; overflow-x: auto; }
        .server-tab { padding: 9px 18px; font-size: 13px; color: #6b7280; text-decoration: none; border-bottom: 2px solid transparent; margin-bottom: -1px; white-space: nowrap; transition: color 0.12s, border-color 0.12s; }
        .server-tab:hover { color: #c8cad0; }
        .server-tab.active { color: #6b9af5; border-bottom-color: #3b6ef5; }

        /* 스캔 헤더 */
        .scan-header { background: #131519; border: 1px solid #1e2025; border-radius: 12px; padding: 18px 22px; margin-bottom: 22px; display: flex; align-items: flex-start; justify-content: space-between; flex-wrap: wrap; gap: 14px; }
        .scan-title { font-size: 17px; font-weight: 500; color: #f2f3f5; }
        .scan-hostname { font-size: 12px; color: #6b9af5; font-family: 'DM Mono', monospace; margin-top: 3px; }
        .scan-meta { display: flex; gap: 18px; flex-wrap: wrap; }
        .meta-item { font-size: 12px; color: #6b7280; }
        .meta-item strong { color: #9ca3af; display: block; font-size: 10px; letter-spacing: 0.05em; text-transform: uppercase; margin-bottom: 2px; }

        /* 요약 카드 */
        .stat-cards { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; margin-bottom: 24px; }
        .stat-card { background: #131519; border: 1px solid #1e2025; border-radius: 12px; padding: 16px 20px; display: flex; align-items: center; justify-content: space-between; }
        .stat-label { font-size: 11px; font-weight: 500; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 6px; }
        .stat-num { font-size: 28px; font-weight: 500; font-family: 'DM Mono', monospace; }
        .stat-pct { font-size: 11px; color: #4b5161; margin-top: 2px; }
        .stat-ok .stat-label { color: #22c97a; }
        .stat-ok .stat-num { color: #22c97a; }
        .stat-vuln .stat-label { color: #e05656; }
        .stat-vuln .stat-num { color: #e05656; }
        .stat-manual .stat-label { color: #f5a623; }
        .stat-manual .stat-num { color: #f5a623; }
        .stat-icon { opacity: 0.15; }

        /* 필터 탭 */
        .filter-bar { display: flex; gap: 2px; background: #0b0c0f; border: 1px solid #1e2025; border-radius: 8px; padding: 3px; margin-bottom: 20px; width: fit-content; }
        .filter-btn { padding: 6px 16px; font-size: 12px; font-weight: 500; border: none; background: none; color: #6b7280; cursor: pointer; border-radius: 6px; font-family: 'DM Sans', sans-serif; transition: background 0.12s, color 0.12s; }
        .filter-btn:hover { color: #c8cad0; }
        .filter-btn.active { background: #1a1e2e; color: #6b9af5; }

        /* 전체접기/펼치기 버튼 */
        .fold-bar { display: flex; justify-content: flex-end; gap: 6px; margin-bottom: 10px; }
        .fold-btn { padding: 5px 12px; font-size: 11px; font-weight: 500; border: 1px solid #252830; background: none; color: #6b7280; border-radius: 6px; cursor: pointer; font-family: 'DM Sans', sans-serif; transition: background 0.12s, color 0.12s; }
        .fold-btn:hover { background: #161820; color: #c8cad0; }

        /* 항목 카드 */
        .item-list { display: flex; flex-direction: column; gap: 8px; }
        .item-card { background: #131519; border: 1px solid #1e2025; border-radius: 10px; overflow: hidden; border-left: 3px solid transparent; transition: border-color 0.12s; }
        .border-ok    { border-left-color: #22c97a; }
        .border-vuln  { border-left-color: #e05656; }
        .border-manual { border-left-color: #f5a623; }
        .border-na    { border-left-color: #4b5161; }

        .item-top { padding: 12px 16px; display: flex; align-items: center; gap: 12px; cursor: pointer; user-select: none; }
        .item-top:hover { background: rgba(255,255,255,0.02); }
        .item-code { font-family: 'DM Mono', monospace; font-size: 11px; font-weight: 500; color: #6b9af5; background: #1a1e2e; padding: 3px 8px; border-radius: 5px; flex-shrink: 0; white-space: nowrap; }
        .item-title { flex: 1; font-size: 13px; color: #e8e9eb; font-weight: 500; line-height: 1.4; }
        .item-chevron { width: 14px; height: 14px; color: #3d4251; flex-shrink: 0; transition: transform 0.18s; }
        .item-card.open .item-chevron { transform: rotate(180deg); }

        .chip { display: inline-flex; align-items: center; gap: 4px; padding: 3px 9px; border-radius: 5px; font-size: 11px; font-weight: 500; white-space: nowrap; }
        .chip-g  { background: rgba(34,201,122,0.12); color: #22c97a; }
        .chip-r  { background: rgba(224,86,86,0.12);  color: #e05656; }
        .chip-y  { background: rgba(245,166,35,0.12); color: #f5a623; }
        .chip-na { background: rgba(75,81,97,0.2);    color: #6b7280; }

        .modified-badge { font-size: 10px; background: rgba(59,110,245,0.15); color: #6b9af5; padding: 2px 6px; border-radius: 4px; }
        .memo-icon { color: #f5a623; opacity: 0.8; }

        /* 접기/펼치기 콘텐츠 */
        .item-body { display: none; }
        .item-card.open .item-body { display: block; }

        .item-evidence { padding: 0 16px 12px; }
        .evidence-pre { background: #0b0c0f; border: 1px solid #1a1c22; border-radius: 8px; padding: 12px 14px; font-family: 'DM Mono', monospace; font-size: 11.5px; color: #9ca3af; white-space: pre-wrap; word-break: break-all; line-height: 1.6; max-height: 240px; overflow-y: auto; }
        .extra-evidence { padding: 0 16px 12px; }
        .extra-evidence-label { font-size: 10px; font-weight: 500; color: #3d4251; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 6px; }

        /* 인라인 편집 */
        .item-edit { padding: 10px 16px 14px; border-top: 1px solid #1a1c22; background: #0f1014; }
        .edit-row { display: flex; gap: 10px; align-items: flex-start; flex-wrap: wrap; }
        .edit-field-status { flex: 0 0 120px; }
        .edit-label { font-size: 10px; font-weight: 500; color: #4b5161; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 5px; }
        .edit-select { background: #0e0f11; border: 1px solid #252830; border-radius: 7px; padding: 7px 10px; font-size: 12px; color: #e8e9eb; font-family: 'DM Sans', sans-serif; width: 100%; }
        .edit-select:focus { outline: none; border-color: #3b6ef5; }
        .edit-textarea { background: #0e0f11; border: 1px solid #252830; border-radius: 7px; padding: 7px 10px; font-size: 12px; color: #c8cad0; font-family: 'DM Sans', sans-serif; width: 100%; height: 34px; min-height: 34px; max-height: 200px; resize: none; overflow-y: hidden; line-height: 1.5; }
        .edit-textarea:focus { outline: none; border-color: #3b6ef5; }
        .edit-memo { flex: 1; min-width: 180px; }
        .edit-actions { display: flex; gap: 6px; align-items: flex-end; align-self: flex-end; }
        .btn-save { padding: 7px 14px; background: #3b6ef5; color: #fff; border: none; border-radius: 7px; font-size: 12px; font-weight: 500; cursor: pointer; font-family: 'DM Sans', sans-serif; transition: background 0.12s; }
        .btn-save:hover { background: #2d5ce0; }
        .btn-cancel { padding: 7px 14px; background: #1e2025; color: #6b7280; border: none; border-radius: 7px; font-size: 12px; cursor: pointer; font-family: 'DM Sans', sans-serif; transition: background 0.12s; }
        .btn-cancel:hover { background: #252830; }

        .toast { position: fixed; bottom: 24px; right: 24px; background: #1a1e2e; border: 1px solid #252830; border-radius: 10px; padding: 12px 18px; font-size: 13px; color: #c8cad0; z-index: 9999; opacity: 0; transform: translateY(8px); transition: opacity 0.2s, transform 0.2s; pointer-events: none; }
        .toast.show { opacity: 1; transform: translateY(0); }
        .toast.ok   { border-color: #1a3a25; color: #22c97a; }
        .toast.err  { border-color: #3d0f0f; color: #e05656; }

        .error-bar { background: #2a0d0d; border: 1px solid #3d0f0f; border-radius: 8px; padding: 10px 14px; color: #e05656; font-size: 13px; margin-bottom: 16px; }

        [data-theme="light"] body { background: #f5f6f8; color: #1a1d23; }
        [data-theme="light"] .sidebar { background: #fff; border-color: #e5e7eb; }
        [data-theme="light"] .sb-item { color: #6b7280; }
        [data-theme="light"] .sb-item:hover { background: #f3f4f6; color: #374151; }
        [data-theme="light"] .sb-item.active { background: #eff2ff; color: #3b6ef5; }
        [data-theme="light"] .sb-section { color: #9ca3af; }
        [data-theme="light"] .sb-bottom { border-color: #e5e7eb; }
        [data-theme="light"] .user-row:hover { background: #f3f4f6; }
        [data-theme="light"] .user-menu { background: #fff; border-color: #e5e7eb; }
        [data-theme="light"] .user-menu-item:hover { background: #f3f4f6; }
        [data-theme="light"] .user-info p { color: #374151; }
        [data-theme="light"] .user-info span { color: #9ca3af; }
        [data-theme="light"] .topbar { background: #fff; border-color: #e5e7eb; }
        [data-theme="light"] .topbar-title { color: #111827; }
        [data-theme="light"] .theme-toggle { background: #f3f4f6; border-color: #e5e7eb; }
        [data-theme="light"] .theme-toggle-btn.active { background: #fff; color: #3b6ef5; }
        [data-theme="light"] .scan-header { background: #fff; border-color: #e5e7eb; }
        [data-theme="light"] .scan-title { color: #111827; }
        [data-theme="light"] .stat-card { background: #fff; border-color: #e5e7eb; }
        [data-theme="light"] .filter-bar { background: #f3f4f6; border-color: #e5e7eb; }
        [data-theme="light"] .filter-btn.active { background: #fff; }
        [data-theme="light"] .item-card { background: #fff; border-color: #e5e7eb; }
        [data-theme="light"] .item-top:hover { background: rgba(0,0,0,0.02); }
        [data-theme="light"] .item-title { color: #111827; }
        [data-theme="light"] .evidence-pre { background: #f9fafb; border-color: #e5e7eb; color: #4b5563; }
        [data-theme="light"] .item-edit { background: #f9fafb; border-color: #e5e7eb; }
        [data-theme="light"] .edit-select, [data-theme="light"] .edit-textarea { background: #fff; border-color: #e5e7eb; color: #111827; }
        [data-theme="light"] .fold-btn { border-color: #e5e7eb; }
        [data-theme="light"] .fold-btn:hover { background: #f3f4f6; }
        [data-theme="light"] .server-tabs { border-color: #e5e7eb; }
        [data-theme="light"] .server-tab { color: #9ca3af; }
        [data-theme="light"] .server-tab.active { color: #3b6ef5; }
    </style>
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
    <a href="../CustomerServlet?action=list" class="sb-item">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
        고객사 정보
    </a>
    <% if ("ADMIN".equals(loginRole)) { %>
    <a href="../UserServlet?action=list" class="sb-item">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/></svg>
        사용자 관리
    </a>
    <% } %>
    <a href="../SecurityScan?action=list" class="sb-item active">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
        보안점검
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
            <div class="user-info"><p><%= loginName %></p><span><%= loginRole %></span></div>
            <svg class="user-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"/></svg>
        </div>
    </div>
</nav>

<!-- 메인 -->
<div class="main">
    <div class="topbar">
        <div class="topbar-left">
            <a href="../SecurityScan?action=list" class="back-btn">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><polyline points="15 18 9 12 15 6"/></svg>
                목록으로
            </a>
            <span style="color:#1e2025">|</span>
            <span class="topbar-title">
                <%= currentScan != null ? nvl(currentScan.serverLabel) + " 보안점검 결과" : "보안점검 상세" %>
            </span>
        </div>
        <div class="theme-toggle">
            <button class="theme-toggle-btn" id="btnDark"  onclick="setTheme('dark')">다크모드</button>
            <button class="theme-toggle-btn" id="btnLight" onclick="setTheme('light')">라이트모드</button>
        </div>
    </div>

    <div class="content">
        <% if (dbError != null) { %>
        <div class="error-bar">⚠ DB 오류: <%= dbError %></div>
        <% } %>

        <!-- 서버 탭 (배치인 경우) -->
        <% if (!tabScans.isEmpty() && batchId != null) { %>
        <div class="server-tabs">
            <% for (ScanVO tab : tabScans) {
               boolean isActive = currentScan != null && tab.scanId == currentScan.scanId; %>
            <a href="../SecurityScan?action=detail&batchId=<%= batchId %>&scanId=<%= tab.scanId %>"
               class="server-tab <%= isActive ? "active" : "" %>">
                <%= nvl(tab.serverLabel).isEmpty() ? nvl(tab.hostname) : nvl(tab.serverLabel) %>
                <% if (tab.vulnCount > 0) { %><span style="color:#e05656;font-size:10px;margin-left:4px;">● <%= tab.vulnCount %></span><% } %>
            </a>
            <% } %>
        </div>
        <% } %>

        <% if (currentScan == null) { %>
        <div style="text-align:center;padding:80px 20px;color:#4b5161;">
            <p>스캔 결과를 찾을 수 없습니다.</p>
        </div>
        <% } else { %>

        <!-- 스캔 헤더 -->
        <div class="scan-header">
            <div>
                <div class="scan-title"><%= nvl(currentScan.serverLabel).isEmpty() ? nvl(currentScan.hostname) : nvl(currentScan.serverLabel) %></div>
                <div class="scan-hostname"><%= nvl(currentScan.hostname) %></div>
            </div>
            <div class="scan-meta">
                <div class="meta-item"><strong>OS</strong><%= nvl(currentScan.osType).isEmpty() ? "-" : nvl(currentScan.osType) %></div>
                <div class="meta-item"><strong>점검일</strong><%= shortDate(currentScan.scanDate) %></div>
                <div class="meta-item"><strong>파일</strong><span style="font-family:'DM Mono',monospace;font-size:11px;"><%= nvl(currentScan.fileName) %></span></div>
            </div>
        </div>

        <!-- 요약 카드 -->
        <div class="stat-cards">
            <div class="stat-card stat-ok">
                <div>
                    <div class="stat-label">양호</div>
                    <div class="stat-num" id="cnt-ok"><%= currentScan.okCount %></div>
                    <div class="stat-pct" id="pct-ok"><%= currentScan.totalCount > 0 ? String.format("%.0f", currentScan.okCount * 100.0 / currentScan.totalCount) : 0 %>% / <%= currentScan.totalCount %>건</div>
                </div>
                <svg class="stat-icon" viewBox="0 0 24 24" fill="none" stroke="#22c97a" stroke-width="1.5" width="36" height="36"><path d="M22 11.08V12a10 10 0 11-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>
            </div>
            <div class="stat-card stat-vuln">
                <div>
                    <div class="stat-label">취약</div>
                    <div class="stat-num" id="cnt-vuln"><%= currentScan.vulnCount %></div>
                    <div class="stat-pct" id="pct-vuln"><%= currentScan.totalCount > 0 ? String.format("%.0f", currentScan.vulnCount * 100.0 / currentScan.totalCount) : 0 %>% / <%= currentScan.totalCount %>건</div>
                </div>
                <svg class="stat-icon" viewBox="0 0 24 24" fill="none" stroke="#e05656" stroke-width="1.5" width="36" height="36"><circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/></svg>
            </div>
            <div class="stat-card stat-manual">
                <div>
                    <div class="stat-label">수동점검</div>
                    <div class="stat-num" id="cnt-manual"><%= currentScan.manualCount %></div>
                    <div class="stat-pct" id="pct-manual"><%= currentScan.totalCount > 0 ? String.format("%.0f", currentScan.manualCount * 100.0 / currentScan.totalCount) : 0 %>% / <%= currentScan.totalCount %>건</div>
                </div>
                <svg class="stat-icon" viewBox="0 0 24 24" fill="none" stroke="#f5a623" stroke-width="1.5" width="36" height="36"><path d="M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/></svg>
            </div>
        </div>

        <!-- 필터 탭 -->
        <div class="filter-bar">
            <button class="filter-btn active" onclick="filter('all', this)">전체 (<%= items.size() %>)</button>
            <button class="filter-btn" onclick="filter('양호', this)">양호 (<%= currentScan.okCount %>)</button>
            <button class="filter-btn" onclick="filter('취약', this)">취약 (<%= currentScan.vulnCount %>)</button>
            <button class="filter-btn" onclick="filter('수동점검', this)">수동점검 (<%= currentScan.manualCount %>)</button>
        </div>

        <!-- 전체접기/펼치기 -->
        <div class="fold-bar">
            <button class="fold-btn" onclick="foldAll()">전체 접기</button>
            <button class="fold-btn" onclick="expandAll()">전체 펼치기</button>
        </div>

        <!-- 항목 목록 -->
        <div class="item-list" id="itemList">
            <% for (ScanItemVO item : items) {
               boolean isModified = !item.result.equals(item.originalResult);
               boolean hasMemo    = !item.memo.isEmpty();
            %>
            <div class="item-card <%= borderClass(item.result) %>" data-result="<%= item.result %>" id="card_<%= item.itemId %>">
                <div class="item-top" onclick="toggleCard(this.closest('.item-card'))">
                    <span class="item-code"><%= nvl(item.iCode) %></span>
                    <span class="item-title"><%= nvl(item.iTitle) %></span>
                    <div style="display:flex;align-items:center;gap:6px;flex-shrink:0;">
                        <% if (hasMemo) { %>
                        <svg class="memo-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="13" height="13"><path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z"/></svg>
                        <% } %>
                        <% if (isModified) { %>
                        <span class="modified-badge">수정됨</span>
                        <% } %>
                        <span class="chip <%= resultClass(item.result) %>" id="chip_<%= item.itemId %>"><%= nvl(item.result) %></span>
                    </div>
                    <svg class="item-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="6 9 12 15 18 9"/></svg>
                </div>
                <div class="item-body">
                    <% if (!item.evidence.isEmpty()) { %>
                    <div class="item-evidence">
                        <pre class="evidence-pre"><%= escHtml(item.evidence) %></pre>
                    </div>
                    <% } %>
                    <% if (!item.txtEvidence.isEmpty()) { %>
                    <div class="extra-evidence">
                        <div class="extra-evidence-label">스크립트 출력 (TXT)</div>
                        <pre class="evidence-pre"><%= escHtml(item.txtEvidence) %></pre>
                    </div>
                    <% } %>
                    <% if (!item.refEvidence.isEmpty()) { %>
                    <div class="extra-evidence">
                        <div class="extra-evidence-label">참고 자료 (REF)</div>
                        <pre class="evidence-pre"><%= escHtml(item.refEvidence) %></pre>
                    </div>
                    <% } %>
                    <!-- 인라인 편집 -->
                    <div class="item-edit">
                        <div class="edit-row">
                            <div class="edit-field-status">
                                <div class="edit-label">결과 상태</div>
                                <select class="edit-select" id="sel_<%= item.itemId %>">
                                    <option value="양호"    <%= "양호".equals(item.result)    ? "selected" : "" %>>양호</option>
                                    <option value="취약"    <%= "취약".equals(item.result)    ? "selected" : "" %>>취약</option>
                                    <option value="수동점검" <%= "수동점검".equals(item.result) ? "selected" : "" %>>수동점검</option>
                                    <option value="N/A"    <%= "N/A".equals(item.result)     ? "selected" : "" %>>N/A</option>
                                </select>
                            </div>
                            <div class="edit-memo">
                                <div class="edit-label">메모</div>
                                <textarea class="edit-textarea" id="memo_<%= item.itemId %>" placeholder="담당자 메모, 조치사항 등" oninput="autoResize(this)"><%= nvl(item.memo).replace("<","&lt;").replace(">","&gt;") %></textarea>
                            </div>
                            <div class="edit-actions">
                                <button class="btn-save" onclick="saveItem(<%= item.itemId %>)">저장</button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <% } %>
        </div>
        <% } /* currentScan != null */ %>
    </div>
</div>

<div class="toast" id="toast"></div>

<script>
function filter(val, btn) {
    document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
    btn.classList.add('active');
    document.querySelectorAll('.item-card').forEach(card => {
        if (val === 'all') {
            card.style.display = '';
        } else {
            const r = card.dataset.result;
            card.style.display = (r === val || (val === '양호' && r === 'N/A')) ? '' : 'none';
            if (val === '수동점검') card.style.display = (r !== '양호' && r !== '취약' && r !== 'N/A') ? '' : 'none';
            if (val === '양호')    card.style.display = (r === '양호') ? '' : 'none';
            if (val === '취약')    card.style.display = (r === '취약') ? '' : 'none';
        }
    });
}

var counts = {
    ok:     <%= currentScan != null ? currentScan.okCount : 0 %>,
    vuln:   <%= currentScan != null ? currentScan.vulnCount : 0 %>,
    manual: <%= currentScan != null ? currentScan.manualCount : 0 %>,
    total:  <%= currentScan != null ? currentScan.totalCount : 0 %>
};
function resultKey(r) { return r === '양호' ? 'ok' : r === '취약' ? 'vuln' : r === '수동점검' ? 'manual' : null; }
function updateStatCards() {
    var t = counts.total || 1;
    document.getElementById('cnt-ok').textContent     = counts.ok;
    document.getElementById('cnt-vuln').textContent   = counts.vuln;
    document.getElementById('cnt-manual').textContent = counts.manual;
    document.getElementById('pct-ok').textContent     = Math.round(counts.ok     / t * 100) + '% / ' + counts.total + '건';
    document.getElementById('pct-vuln').textContent   = Math.round(counts.vuln   / t * 100) + '% / ' + counts.total + '건';
    document.getElementById('pct-manual').textContent = Math.round(counts.manual / t * 100) + '% / ' + counts.total + '건';
}

function saveItem(itemId) {
    const result = document.getElementById('sel_'  + itemId).value;
    const memo   = document.getElementById('memo_' + itemId).value;

    fetch('../SecurityScan?action=updateItem', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'itemId=' + itemId + '&result=' + encodeURIComponent(result) + '&memo=' + encodeURIComponent(memo)
    })
    .then(r => r.json())
    .then(data => {
        if (data.ok) {
            const card  = document.getElementById('card_' + itemId);
            const chip  = document.getElementById('chip_' + itemId);
            var oldKey = resultKey(card.dataset.result);
            var newKey = resultKey(result);
            if (oldKey) counts[oldKey]--;
            if (newKey) counts[newKey]++;
            updateStatCards();
            // 칩 업데이트
            chip.textContent = result;
            chip.className = 'chip ' + resultClass(result);
            // 보더 업데이트
            card.classList.remove('border-ok','border-vuln','border-manual','border-na');
            card.classList.add(borderClass(result));
            card.dataset.result = result;
            showToast('저장되었습니다', 'ok');
        } else {
            showToast('저장 실패: ' + (data.error || ''), 'err');
        }
    })
    .catch(() => showToast('저장 중 오류가 발생했습니다', 'err'));
}

function resultClass(r) {
    if (r === '양호')    return 'chip-g';
    if (r === '취약')    return 'chip-r';
    if (r === 'N/A')    return 'chip-na';
    return 'chip-y';
}
function borderClass(r) {
    if (r === '양호') return 'border-ok';
    if (r === '취약') return 'border-vuln';
    return 'border-manual';
}

function toggleCard(card) {
    card.classList.toggle('open');
}
function foldAll() {
    document.querySelectorAll('.item-card').forEach(c => c.classList.remove('open'));
}
function expandAll() {
    document.querySelectorAll('.item-card').forEach(c => c.classList.add('open'));
}
function autoResize(el) {
    el.style.height = '0px';
    el.style.height = Math.min(Math.max(el.scrollHeight, 34), 200) + 'px';
}

function showToast(msg, type) {
    const t = document.getElementById('toast');
    t.textContent = msg;
    t.className = 'toast show ' + (type || '');
    clearTimeout(t._tid);
    t._tid = setTimeout(() => { t.className = 'toast'; }, 2500);
}

function toggleUserMenu(el) {
    el.classList.toggle('open');
    document.getElementById('userMenu').classList.toggle('open');
}
function setTheme(t) {
    localStorage.setItem('theme', t);
    if (t === 'light') document.documentElement.setAttribute('data-theme','light');
    else document.documentElement.removeAttribute('data-theme');
    document.getElementById('btnDark').classList.toggle('active',  t !== 'light');
    document.getElementById('btnLight').classList.toggle('active', t === 'light');
}
(function(){
    const t = localStorage.getItem('theme') || 'dark';
    document.getElementById('btnDark').classList.toggle('active',  t !== 'light');
    document.getElementById('btnLight').classList.toggle('active', t === 'light');
    // 메모 내용 있는 textarea 초기 높이 조정
    document.querySelectorAll('.edit-textarea').forEach(el => {
        if (el.value.trim()) autoResize(el);
    });
})();
</script>
</body>
</html>

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.admin.servlet.SecurityScanServlet.*" %>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("../login.jsp"); return; }
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");

    List<ScanVO>  scans   = (List<ScanVO>)  request.getAttribute("scans");
    List<BatchVO> batches = (List<BatchVO>) request.getAttribute("batches");
    String dbError     = (String) request.getAttribute("dbError");
    String uploadError = (String) request.getAttribute("uploadError");
    if (scans   == null) scans   = new java.util.ArrayList<>();
    if (batches == null) batches = new java.util.ArrayList<>();
%>
<%!
    String nvl(String s) { return s != null ? s : ""; }
    String shortDate(String dt) {
        if (dt == null || dt.length() < 10) return "-";
        return dt.substring(0, 10);
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>보안점검 결과 - 관리 시스템</title>
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
        .topbar-title { font-size: 14px; font-weight: 500; color: #f2f3f5; }
        .content { padding: 28px; }

        .theme-toggle { display:flex;gap:4px;background:#0b0c0f;border:1px solid #1e2025;border-radius:8px;padding:3px; }
        .theme-toggle-btn { padding:4px 12px;font-size:11px;font-weight:500;border:none;background:none;color:#4b5161;cursor:pointer;border-radius:5px;font-family:'DM Sans',sans-serif;transition:background .12s,color .12s; }
        .theme-toggle-btn.active { background:#1a1e2e;color:#6b9af5; }

        .page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; }
        .page-title { font-size: 18px; font-weight: 500; color: #f2f3f5; }

        .btn { display: inline-flex; align-items: center; gap: 6px; padding: 8px 16px; border-radius: 8px; font-size: 13px; font-weight: 500; cursor: pointer; border: none; font-family: 'DM Sans', sans-serif; transition: background 0.12s; text-decoration: none; }
        .btn-primary { background: #3b6ef5; color: #fff; }
        .btn-primary:hover { background: #2d5ce0; }
        .btn-danger { background: transparent; color: #e05656; border: 1px solid #3d1515; }
        .btn-danger:hover { background: #2a1015; }
        .btn-sm { padding: 5px 12px; font-size: 12px; white-space: nowrap; }
        .action-cell { white-space: nowrap; }

        .section-title { font-size: 12px; font-weight: 500; color: #4b5161; text-transform: uppercase; letter-spacing: 0.06em; margin-bottom: 10px; margin-top: 28px; }
        .section-title:first-child { margin-top: 0; }

        .table-wrap { background: #131519; border: 1px solid #1e2025; border-radius: 12px; overflow: hidden; }
        table { width: 100%; border-collapse: collapse; }
        th { padding: 10px 16px; font-size: 11px; font-weight: 500; color: #4b5161; text-align: left; border-bottom: 1px solid #1e2025; text-transform: uppercase; letter-spacing: 0.04em; }
        td { padding: 12px 16px; font-size: 13px; color: #c8cad0; border-bottom: 1px solid #0e0f11; }
        tr:last-child td { border-bottom: none; }
        tr:hover td { background: #161820; }

        .chip { display: inline-flex; align-items: center; gap: 5px; padding: 3px 8px; border-radius: 5px; font-size: 11px; font-weight: 500; }
        .chip-g { background: rgba(34,201,122,0.12); color: #22c97a; }
        .chip-r { background: rgba(224,86,86,0.12); color: #e05656; }
        .chip-y { background: rgba(245,166,35,0.12); color: #f5a623; }
        .chip-blue { background: rgba(59,110,245,0.12); color: #6b9af5; }

        .count-cell { font-family: 'DM Mono', monospace; font-size: 12px; }
        .ok-num { color: #22c97a; }
        .vuln-num { color: #e05656; }
        .manual-num { color: #f5a623; }

        .empty-state { text-align: center; padding: 60px 20px; color: #3d4251; }
        .empty-state svg { opacity: 0.3; margin-bottom: 12px; }
        .empty-state p { font-size: 14px; color: #4b5161; }
        .empty-state span { font-size: 12px; }

        /* 모달 */
        .modal-backdrop { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.6); z-index: 200; align-items: center; justify-content: center; }
        .modal-backdrop.open { display: flex; }
        .modal { background: #131519; border: 1px solid #1e2025; border-radius: 14px; width: 720px; max-width: 95vw; max-height: 90vh; overflow-y: auto; }
        .modal-header { padding: 20px 24px 16px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; justify-content: space-between; }
        .modal-title { font-size: 15px; font-weight: 500; color: #f2f3f5; }
        .modal-close { background: none; border: none; color: #4b5161; cursor: pointer; padding: 4px; border-radius: 4px; }
        .modal-close:hover { color: #c8cad0; background: #1e2025; }
        .modal-body { padding: 20px 24px; }
        .modal-footer { padding: 16px 24px; border-top: 1px solid #1e2025; display: flex; justify-content: flex-end; gap: 8px; }

        .form-label { font-size: 11px; font-weight: 500; color: #6b7280; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 6px; display: block; }
        .form-input { width: 100%; background: #0e0f11; border: 1px solid #252830; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #e8e9eb; font-family: 'DM Sans', sans-serif; transition: border-color 0.12s; }
        .form-input:focus { outline: none; border-color: #3b6ef5; }
        .form-group { margin-bottom: 16px; }

        /* 업로드 모드 토글 */
        .mode-toggle { display: flex; background: #0e0f11; border: 1px solid #1e2025; border-radius: 8px; padding: 3px; margin-bottom: 20px; }
        .mode-btn { flex: 1; padding: 7px; font-size: 12px; font-weight: 500; border: none; background: none; color: #6b7280; cursor: pointer; border-radius: 6px; font-family: 'DM Sans', sans-serif; transition: background 0.12s, color 0.12s; }
        .mode-btn.active { background: #1a1e2e; color: #6b9af5; }

        /* 서버 행 */
        .server-rows { display: flex; flex-direction: column; gap: 10px; }
        .server-row { background: #0e0f11; border: 1px solid #252830; border-radius: 10px; padding: 14px; display: flex; flex-direction: column; gap: 10px; position: relative; }
        .server-row-header { display: flex; align-items: center; justify-content: space-between; }
        .server-row-num { font-size: 11px; color: #4b5161; font-weight: 500; }
        .server-row-remove { background: none; border: none; color: #4b5161; cursor: pointer; padding: 2px; border-radius: 4px; }
        .server-row-remove:hover { color: #e05656; }
        .server-row-fields { display: grid; grid-template-columns: 1fr 1fr 2fr; gap: 10px; align-items: end; }

        /* 파일 드롭존 */
        .file-zone { border: 1.5px dashed #252830; border-radius: 8px; padding: 8px 12px; cursor: pointer; transition: border-color 0.12s, background 0.12s; display: flex; align-items: center; gap: 8px; min-width: 0; }
        .file-zone:hover, .file-zone.dragover { border-color: #3b6ef5; background: rgba(59,110,245,0.05); }
        .file-zone p { font-size: 12px; color: #4b5161; white-space: nowrap; }
        .file-zone .file-name { font-size: 12px; color: #6b9af5; font-family: 'DM Mono', monospace; flex: 1; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; min-width: 0; }
        .file-input { display: none; }

        .add-server-btn { width: 100%; padding: 9px; background: none; border: 1.5px dashed #252830; border-radius: 10px; color: #4b5161; font-size: 13px; cursor: pointer; font-family: 'DM Sans', sans-serif; transition: border-color 0.12s, color 0.12s; }
        .add-server-btn:hover { border-color: #3b6ef5; color: #6b9af5; }

        .error-bar { background: #2a0d0d; border: 1px solid #3d0f0f; border-radius: 8px; padding: 10px 14px; color: #e05656; font-size: 13px; margin-bottom: 16px; }

        /* 라이트 테마 */
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
        [data-theme="light"] .user-chevron { color: #9ca3af; }
        [data-theme="light"] .main { background: #f5f6f8; }
        [data-theme="light"] .topbar { background: #fff; border-color: #e5e7eb; }
        [data-theme="light"] .topbar-title { color: #111827; }
        [data-theme="light"] .theme-toggle { background: #f3f4f6; border-color: #e5e7eb; }
        [data-theme="light"] .theme-toggle-btn { color: #9ca3af; }
        [data-theme="light"] .theme-toggle-btn.active { background: #fff; color: #3b6ef5; }
        [data-theme="light"] .table-wrap { background: #fff; border-color: #e5e7eb; }
        [data-theme="light"] th { color: #9ca3af; border-color: #e5e7eb; }
        [data-theme="light"] td { color: #374151; border-color: #f3f4f6; }
        [data-theme="light"] tr:hover td { background: #f9fafb; }
        [data-theme="light"] .page-title { color: #111827; }
        [data-theme="light"] .section-title { color: #9ca3af; }
        [data-theme="light"] .modal { background: #fff; border-color: #e5e7eb; }
        [data-theme="light"] .modal-header { border-color: #e5e7eb; }
        [data-theme="light"] .modal-title { color: #111827; }
        [data-theme="light"] .modal-footer { border-color: #e5e7eb; }
        [data-theme="light"] .form-input { background: #f9fafb; border-color: #e5e7eb; color: #111827; }
        [data-theme="light"] .mode-toggle { background: #f3f4f6; border-color: #e5e7eb; }
        [data-theme="light"] .mode-btn.active { background: #fff; }
        [data-theme="light"] .server-row { background: #f9fafb; border-color: #e5e7eb; }
        [data-theme="light"] .file-zone { border-color: #d1d5db; }
        [data-theme="light"] .add-server-btn { border-color: #d1d5db; }
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
        <span class="topbar-title">보안점검 결과</span>
        <div class="theme-toggle">
            <button class="theme-toggle-btn" id="btnDark"  onclick="setTheme('dark')">다크모드</button>
            <button class="theme-toggle-btn" id="btnLight" onclick="setTheme('light')">라이트모드</button>
        </div>
    </div>

    <div class="content">
        <% if (dbError != null) { %>
        <div class="error-bar">⚠ DB 오류: <%= dbError %></div>
        <% } %>
        <% if (uploadError != null) { %>
        <div class="error-bar">⚠ 업로드 오류: <%= uploadError %></div>
        <% } %>

        <div class="page-header">
            <div class="page-title">보안점검 결과 목록</div>
            <button class="btn btn-primary" onclick="openUploadModal()">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                결과 업로드
            </button>
        </div>

        <!-- 배치 목록 -->
        <% if (!batches.isEmpty()) { %>
        <div class="section-title">일괄 업로드 (배치)</div>
        <div class="table-wrap" style="margin-bottom: 24px;">
            <table>
                <thead>
                    <tr>
                        <th>배치명</th>
                        <th>서버 수</th>
                        <th>업로드 일시</th>
                        <th style="width:120px">관리</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (BatchVO b : batches) { %>
                    <tr>
                        <td><strong style="color:#e8e9eb"><%= nvl(b.batchName) %></strong></td>
                        <td><span class="chip chip-blue"><%= b.serverCount %>개 서버</span></td>
                        <td style="color:#6b7280;font-size:12px;"><%= shortDate(b.createdAt) %></td>
                        <td class="action-cell">
                            <div style="display:flex;gap:6px;flex-wrap:nowrap;">
                                <a href="../SecurityScan?action=detail&batchId=<%= b.batchId %>" class="btn btn-sm" style="background:#1a1e2e;color:#6b9af5;text-decoration:none;">보기</a>
                                <button class="btn btn-sm btn-danger" onclick="deleteBatch(<%= b.batchId %>, '<%= nvl(b.batchName).replace("'","&#39;") %>')">삭제</button>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
        </div>
        <% } %>

        <!-- 개별 스캔 목록 -->
        <div class="section-title">개별 업로드</div>
        <div class="table-wrap">
            <% if (scans.isEmpty()) { %>
            <div class="empty-state">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="40" height="40"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
                <p>업로드된 보안점검 결과가 없습니다</p>
                <span>tar 파일을 업로드하면 여기에 표시됩니다</span>
            </div>
            <% } else { %>
            <table>
                <thead>
                    <tr>
                        <th>서버명</th>
                        <th>호스트명</th>
                        <th>OS</th>
                        <th>점검일</th>
                        <th>양호</th>
                        <th>취약</th>
                        <th>수동점검</th>
                        <th style="width:120px">관리</th>
                    </tr>
                </thead>
                <tbody>
                    <% for (ScanVO s : scans) { %>
                    <tr>
                        <td><strong style="color:#e8e9eb"><%= nvl(s.serverLabel) %></strong></td>
                        <td style="font-family:'DM Mono',monospace;font-size:12px;color:#6b9af5"><%= nvl(s.hostname) %></td>
                        <td><span class="chip chip-blue"><%= nvl(s.osType).isEmpty() ? "-" : s.osType %></span></td>
                        <td style="color:#6b7280;font-size:12px"><%= shortDate(s.scanDate) %></td>
                        <td class="count-cell ok-num"><%= s.okCount %></td>
                        <td class="count-cell vuln-num"><%= s.vulnCount %></td>
                        <td class="count-cell manual-num"><%= s.manualCount %></td>
                        <td class="action-cell">
                            <div style="display:flex;gap:6px;flex-wrap:nowrap;">
                                <a href="../SecurityScan?action=detail&scanId=<%= s.scanId %>" class="btn btn-sm" style="background:#1a1e2e;color:#6b9af5;text-decoration:none;">보기</a>
                                <button class="btn btn-sm btn-danger" onclick="deleteScan(<%= s.scanId %>, '<%= nvl(s.serverLabel).replace("'","&#39;") %>')">삭제</button>
                            </div>
                        </td>
                    </tr>
                    <% } %>
                </tbody>
            </table>
            <% } %>
        </div>
    </div>
</div>

<!-- 업로드 모달 -->
<div class="modal-backdrop" id="uploadModal">
    <div class="modal">
        <div class="modal-header">
            <span class="modal-title">보안점검 결과 업로드</span>
            <button class="modal-close" onclick="closeUploadModal()">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="18" height="18"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
            </button>
        </div>
        <form id="uploadForm" method="post" action="../SecurityScan?action=upload" enctype="multipart/form-data">
            <div class="modal-body">
                <div class="mode-toggle">
                    <button type="button" class="mode-btn active" id="modeSingle" onclick="setMode('single')">개별 (1개 서버)</button>
                    <button type="button" class="mode-btn" id="modeMulti"  onclick="setMode('multi')">일괄 (여러 서버)</button>
                </div>

                <div id="batchNameGroup" class="form-group" style="display:none;">
                    <label class="form-label">배치명 (선택)</label>
                    <input type="text" class="form-input" name="batchName" placeholder="예) 2026-04 정기점검">
                </div>

                <div class="server-rows" id="serverRows"></div>

                <button type="button" class="add-server-btn" id="addServerBtn" onclick="addServerRow()" style="display:none;margin-top:10px;">
                    + 서버 추가
                </button>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn" style="background:#1e2025;color:#6b7280;" onclick="closeUploadModal()">취소</button>
                <button type="submit" class="btn btn-primary" id="submitBtn">업로드</button>
            </div>
        </form>
    </div>
</div>

<script>
let uploadMode = 'single';
let rowCount = 0;

function openUploadModal() {
    document.getElementById('uploadModal').classList.add('open');
    rowCount = 0;
    document.getElementById('serverRows').innerHTML = '';
    setMode('single');
    addServerRow();
}
function closeUploadModal() {
    document.getElementById('uploadModal').classList.remove('open');
}

function setMode(mode) {
    uploadMode = mode;
    document.getElementById('modeSingle').classList.toggle('active', mode === 'single');
    document.getElementById('modeMulti').classList.toggle('active',  mode === 'multi');
    document.getElementById('batchNameGroup').style.display = mode === 'multi' ? 'block' : 'none';
    document.getElementById('addServerBtn').style.display   = mode === 'multi' ? 'block' : 'none';
    const rows = document.getElementById('serverRows');
    // 라벨 표시/숨김
    rows.querySelectorAll('.server-row-header').forEach(h => {
        h.style.display = mode === 'multi' ? 'flex' : 'none';
    });
}

function addServerRow() {
    rowCount++;
    const rows = document.getElementById('serverRows');
    const div = document.createElement('div');
    div.className = 'server-row';
    div.dataset.row = rowCount;
    const headerDisplay = uploadMode === 'multi' ? 'flex' : 'none';
    const removeBtn = rowCount > 1
        ? '<button type="button" class="server-row-remove" onclick="removeRow(this)">'
          + '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>'
          + '</button>' : '';
    div.innerHTML =
        '<div class="server-row-header" style="display:' + headerDisplay + ';">'
        + '<span class="server-row-num">서버 ' + rowCount + '</span>'
        + removeBtn
        + '</div>'
        + '<div class="server-row-fields">'
        + '<div>'
        + '<label class="form-label">서버명 (별칭)</label>'
        + '<input type="text" class="form-input" name="serverLabel" placeholder="예) 웹서버-01">'
        + '</div>'
        + '<div>'
        + '<label class="form-label">IP Address</label>'
        + '<input type="text" class="form-input" name="ipAddress" placeholder="예) 192.168.1.10">'
        + '</div>'
        + '<div>'
        + '<label class="form-label">tar 파일</label>'
        + '<div class="file-zone" onclick="this.nextElementSibling.click()" id="zone_' + rowCount + '"'
        + ' ondragover="event.preventDefault();this.classList.add(\'dragover\')"'
        + ' ondragleave="this.classList.remove(\'dragover\')"'
        + ' ondrop="handleDrop(event,this,\'file_' + rowCount + '\')">'
        + '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" width="20" height="20" style="opacity:0.4;flex-shrink:0"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>'
        + '<p id="hint_' + rowCount + '">클릭하거나 파일을 드래그</p>'
        + '<div class="file-name" id="fname_' + rowCount + '"></div>'
        + '</div>'
        + '<input type="file" class="file-input" name="tarFile" id="file_' + rowCount + '" accept=".tar"'
        + ' onchange="showFileName(this,\'fname_' + rowCount + '\',\'hint_' + rowCount + '\')">'
        + '</div>'
        + '</div>';
    rows.appendChild(div);
}

function removeRow(btn) {
    btn.closest('.server-row').remove();
    // 번호 재정렬
    document.querySelectorAll('.server-row').forEach((r, i) => {
        const span = r.querySelector('.server-row-num');
        if (span) span.textContent = '서버 ' + (i + 1);
    });
}

function showFileName(input, fnameId, hintId) {
    const name = input.files[0] ? input.files[0].name : '';
    document.getElementById(fnameId).textContent = name;
    if (hintId) document.getElementById(hintId).style.display = name ? 'none' : '';
}

function handleDrop(event, zone, fileInputId) {
    event.preventDefault();
    zone.classList.remove('dragover');
    const file = event.dataTransfer.files[0];
    if (!file) return;
    const input = document.getElementById(fileInputId);
    const dt = new DataTransfer();
    dt.items.add(file);
    input.files = dt.files;
    const num = zone.id.replace('zone_', '');
    document.getElementById('fname_' + num).textContent = file.name;
    const hint = document.getElementById('hint_' + num);
    if (hint) hint.style.display = 'none';
}

function deleteBatch(id, name) {
    if (!confirm(name + ' 배치를 삭제하시겠습니까?\n하위 서버 점검 결과도 모두 삭제됩니다.')) return;
    const f = document.createElement('form');
    f.method = 'post'; f.action = '../SecurityScan?action=delete';
    const i = document.createElement('input'); i.type='hidden'; i.name='batchId'; i.value=id;
    f.appendChild(i); document.body.appendChild(f); f.submit();
}
function deleteScan(id, name) {
    if (!confirm((name||'이 스캔') + ' 결과를 삭제하시겠습니까?')) return;
    const f = document.createElement('form');
    f.method = 'post'; f.action = '../SecurityScan?action=delete';
    const i = document.createElement('input'); i.type='hidden'; i.name='scanId'; i.value=id;
    f.appendChild(i); document.body.appendChild(f); f.submit();
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
})();
</script>
</body>
</html>

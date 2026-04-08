<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.admin.servlet.CustomerDetailServlet.*" %>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("../login.jsp"); return; }
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");

    CustomerVO    cust     = (CustomerVO)    request.getAttribute("customer");
    List<ProjectVO> projects = (List<ProjectVO>) request.getAttribute("projects");
    List<AssetVO>   assets   = (List<AssetVO>)   request.getAttribute("assets");
    List<RackVO>    racks    = (List<RackVO>)    request.getAttribute("racks");
    if (projects == null) projects = new java.util.ArrayList<>();
    if (assets   == null) assets   = new java.util.ArrayList<>();
    if (racks    == null) racks    = new java.util.ArrayList<>();

    String activeTab = request.getParameter("tab") != null ? request.getParameter("tab") : "project";
    String activeSub = request.getParameter("sub")  != null ? request.getParameter("sub")  : "list";
    String dbError   = (String) request.getAttribute("dbError");
%>
<%!
    String nvl(String s) { return s != null ? s : ""; }
    String fmtAmt(long amt) { if (amt == 0) return "-"; return String.format("%,d 원", amt); }
    String statusLabel(String s) {
        if ("ACTIVE".equals(s))   return "활성";
        if ("INACTIVE".equals(s)) return "비활성";
        if ("PENDING".equals(s))  return "대기";
        if ("DONE".equals(s))     return "완료";
        return s != null ? s : "-";
    }
    String statusChip(String s) {
        if ("ACTIVE".equals(s))   return "chip-g";
        if ("DONE".equals(s))     return "chip-g";
        if ("INACTIVE".equals(s)) return "chip-r";
        return "chip-y";
    }
    String assetTypeLabel(String t) {
        if ("SERVER".equals(t))   return "서버";
        if ("NETWORK".equals(t))  return "네트워크";
        if ("SECURITY".equals(t)) return "보안";
        return "기타";
    }
    String assetTypeChip(String t) {
        if ("SERVER".equals(t))   return "chip-blue";
        if ("NETWORK".equals(t))  return "chip-purple";
        if ("SECURITY".equals(t)) return "chip-r";
        return "chip-y";
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= cust != null ? cust.custName : "고객사 상세" %> - 관리 시스템</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'DM Sans', sans-serif; background: #0e0f11; color: #e8e9eb; min-height: 100vh; display: flex; }

        /* 사이드바 */
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
        .user-row { display: flex; align-items: center; gap: 10px; padding: 8px; }
        .avatar { width: 30px; height: 30px; border-radius: 50%; background: #1a1e2e; display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 500; color: #6b9af5; flex-shrink: 0; }
        .user-info p { font-size: 12px; font-weight: 500; color: #c8cad0; }
        .user-info span { font-size: 11px; color: #3d4251; }
        .logout-btn { display: flex; align-items: center; gap: 8px; padding: 7px 10px; border-radius: 7px; font-size: 12px; color: #6b7280; text-decoration: none; transition: background 0.12s; width: 100%; }
        .logout-btn:hover { background: #1a1015; color: #e05656; }
        .logout-btn svg { width: 14px; height: 14px; }

        /* 메인 */
        .main { margin-left: 220px; flex: 1; display: flex; flex-direction: column; min-height: 100vh; }
        .topbar { height: 52px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; justify-content: space-between; padding: 0 28px; background: #0e0f11; position: sticky; top: 0; z-index: 50; }
        .topbar-left { display: flex; align-items: center; gap: 10px; }
        .topbar-title { font-size: 14px; font-weight: 500; color: #f2f3f5; }
        .back-btn { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #6b7280; text-decoration: none; padding: 5px 10px; border-radius: 6px; transition: background 0.12s; }
        .back-btn:hover { background: #161820; color: #c8cad0; }
        .content { padding: 28px; }

        /* 고객사 헤더 카드 */
        .cust-header { background: #131519; border: 1px solid #1e2025; border-radius: 12px; padding: 20px 24px; margin-bottom: 24px; display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 16px; }
        .cust-title { display: flex; align-items: center; gap: 14px; }
        .cust-avatar { width: 44px; height: 44px; background: #1a1e2e; border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 18px; font-weight: 500; color: #6b9af5; flex-shrink: 0; }
        .cust-name { font-size: 18px; font-weight: 500; color: #f2f3f5; }
        .cust-code { font-size: 12px; color: #4b5161; font-family: 'DM Mono', monospace; margin-top: 2px; }
        .cust-meta { display: flex; gap: 20px; flex-wrap: wrap; }
        .meta-item { font-size: 12px; color: #6b7280; }
        .meta-item strong { color: #9ca3af; display: block; font-size: 10px; letter-spacing: 0.05em; text-transform: uppercase; margin-bottom: 2px; }

        /* 탭 */
        .tab-bar { display: flex; gap: 4px; margin-bottom: 20px; border-bottom: 1px solid #1e2025; padding-bottom: 0; }
        .tab-btn { padding: 10px 20px; font-size: 13px; color: #6b7280; cursor: pointer; border: none; background: none; border-bottom: 2px solid transparent; margin-bottom: -1px; transition: color 0.12s, border-color 0.12s; font-family: 'DM Sans', sans-serif; }
        .tab-btn:hover { color: #c8cad0; }
        .tab-btn.active { color: #6b9af5; border-bottom-color: #3b6ef5; }
        .tab-panel { display: none; }
        .tab-panel.active { display: block; }

        /* 서브탭 */
        .sub-tab-bar { display: flex; gap: 2px; margin-bottom: 20px; background: #0e0f11; border: 1px solid #1e2025; border-radius: 8px; padding: 4px; width: fit-content; }
        .sub-tab-btn { padding: 6px 18px; font-size: 12px; font-weight: 500; color: #6b7280; cursor: pointer; border: none; background: none; border-radius: 6px; transition: background 0.12s, color 0.12s; font-family: 'DM Sans', sans-serif; }
        .sub-tab-btn:hover { color: #c8cad0; }
        .sub-tab-btn.active { background: #1a1e2e; color: #6b9af5; }
        .sub-tab-panel { display: none; }
        .sub-tab-panel.active { display: block; }

        /* 랙 실장도 플레이스홀더 */
        .rack-placeholder { display: flex; flex-direction: column; align-items: center; justify-content: center; padding: 80px 20px; background: #131519; border: 1px dashed #252830; border-radius: 12px; gap: 12px; }
        .rack-placeholder-icon { opacity: 0.4; }
        .rack-placeholder-title { font-size: 15px; font-weight: 500; color: #4b5161; }
        .rack-placeholder-desc { font-size: 12px; color: #3d4251; }

        /* 랙 카드 */
        .rack-list { display: flex; flex-wrap: wrap; gap: 24px; align-items: flex-start; }
        .rack-card { background: #131519; border: 1px solid #1e2025; border-radius: 12px; overflow: hidden; min-width: 320px; }
        .rack-card-header { display: flex; align-items: flex-start; justify-content: space-between; padding: 14px 16px; border-bottom: 1px solid #1e2025; gap: 10px; }
        .rack-card-name { font-size: 14px; font-weight: 500; color: #e8e9eb; }
        .rack-card-loc { font-size: 11px; color: #4b5161; margin-top: 2px; }

        /* 전면/후면 토글 */
        .rack-side-toggle { display: flex; background: #0e0f11; border: 1px solid #1e2025; border-radius: 6px; padding: 2px; }
        .rack-side-btn { padding: 4px 12px; font-size: 11px; font-weight: 500; border: none; background: none; color: #6b7280; cursor: pointer; border-radius: 4px; font-family: 'DM Sans', sans-serif; transition: background 0.12s, color 0.12s; }
        .rack-side-btn.active { background: #1a1e2e; color: #6b9af5; }

        /* 랙 바디 */
        .rack-body { padding: 12px 16px 16px; }
        .rack-view { display: none; }
        .rack-view.active { display: block; }
        .rack-frame { display: flex; align-items: stretch; }
        .rack-left-rail, .rack-right-rail { width: 14px; background: #1a1c22; border: 1px solid #252830; border-radius: 3px; flex-shrink: 0; }
        .rack-slots { flex: 1; border: 1px solid #252830; border-left: none; border-right: none; }

        /* 슬롯 */
        .rack-slot { display: flex; align-items: center; border-bottom: 1px solid #1e2025; min-height: 26px; cursor: pointer; transition: background 0.1s; position: relative; overflow: hidden; }
        .rack-slot:last-child { border-bottom: none; }
        .rack-slot.empty { background: #0e0f11; }
        .rack-slot.empty:hover { background: #161820; }
        .rack-slot-u { font-family: 'DM Mono', monospace; font-size: 9px; color: #3d4251; width: 24px; text-align: center; flex-shrink: 0; border-right: 1px solid #1e2025; align-self: stretch; display: flex; align-items: center; justify-content: center; }
        .rack-slot-body { flex: 1; padding: 0 8px; display: flex; align-items: center; justify-content: space-between; gap: 6px; min-width: 0; }
        .rack-slot-name { font-size: 12px; font-weight: 500; color: #e8e9eb; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
        .rack-slot-type { font-size: 10px; font-family: 'DM Mono', monospace; padding: 1px 5px; border-radius: 3px; flex-shrink: 0; }
        .rack-slot-ip { font-size: 10px; color: #4b5161; font-family: 'DM Mono', monospace; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; flex-shrink: 0; max-width: 100px; }
        .rack-slot-add { font-size: 10px; color: #252830; width: 100%; text-align: center; }
        .rack-slot.empty:hover .rack-slot-add { color: #3b6ef5; }

        /* 장비 타입 색상 */
        .type-server   { background: rgba(59,110,245,0.18); border-left: 3px solid #3b6ef5; }
        .type-network  { background: rgba(34,201,122,0.15); border-left: 3px solid #22c97a; }
        .type-security { background: rgba(212,160,23,0.15); border-left: 3px solid #d4a017; }
        .type-storage  { background: rgba(167,139,250,0.15); border-left: 3px solid #a78bfa; }
        .type-pdu      { background: rgba(249,115,22,0.15); border-left: 3px solid #f97316; }
        .type-patch    { background: rgba(100,116,139,0.15); border-left: 3px solid #64748b; }
        .type-kvm      { background: rgba(236,72,153,0.15); border-left: 3px solid #ec4899; }
        .type-blank    { background: #0a0b0d; border-left: 3px solid #1e2025; }
        .type-etc      { background: rgba(71,85,105,0.15); border-left: 3px solid #475569; }
        .chip-server   { background: rgba(59,110,245,0.2);  color: #6b9af5; }
        .chip-network  { background: rgba(34,201,122,0.2);  color: #22c97a; }
        .chip-security { background: rgba(212,160,23,0.2);  color: #d4a017; }
        .chip-storage  { background: rgba(167,139,250,0.2); color: #a78bfa; }
        .chip-pdu      { background: rgba(249,115,22,0.2);  color: #f97316; }
        .chip-patch    { background: rgba(100,116,139,0.2); color: #94a3b8; }
        .chip-kvm      { background: rgba(236,72,153,0.2);  color: #ec4899; }
        .chip-blank    { background: #1e2025; color: #3d4251; }
        .chip-etc      { background: rgba(71,85,105,0.2);   color: #94a3b8; }

        /* 버튼 */
        .btn { padding: 8px 16px; border-radius: 8px; font-size: 13px; font-family: 'DM Sans', sans-serif; cursor: pointer; border: none; transition: background 0.15s; }
        .btn-primary { background: #3b6ef5; color: #fff; }
        .btn-primary:hover { background: #2f5ee0; }
        .btn-secondary { background: #1a1e2e; color: #6b9af5; border: 1px solid #252d44; }
        .btn-secondary:hover { background: #202540; }
        .btn-sm { padding: 5px 12px; font-size: 12px; border-radius: 6px; }
        .btn-danger { background: #2a0d0d; color: #e05656; border: 1px solid #3d0f0f; }
        .btn-danger:hover { background: #3d1212; }

        /* 테이블 */
        .panel-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
        .panel-title { font-size: 13px; font-weight: 500; color: #9ca3af; }
        .table-wrap { background: #131519; border: 1px solid #1e2025; border-radius: 12px; overflow: hidden; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #0f1013; padding: 11px 16px; font-size: 11px; font-weight: 500; color: #6b7280; text-align: left; letter-spacing: 0.05em; text-transform: uppercase; border-bottom: 1px solid #1e2025; white-space: nowrap; }
        td { padding: 12px 16px; font-size: 13px; color: #c8cad0; border-bottom: 1px solid #161820; vertical-align: middle; }
        tr:last-child td { border-bottom: none; }
        tr:hover td { background: #161820; }
        .td-mono { font-family: 'DM Mono', monospace; font-size: 12px; }
        .td-actions { display: flex; gap: 6px; }
        .empty-row td { text-align: center; padding: 48px; color: #3d4251; }

        /* 칩 */
        .chip { font-size: 10px; padding: 3px 9px; border-radius: 4px; font-family: 'DM Mono', monospace; font-weight: 500; white-space: nowrap; }
        .chip-g      { background: #0d2a1a; color: #22c97a; border: 1px solid #0f3d25; }
        .chip-r      { background: #2a0d0d; color: #e05656; border: 1px solid #3d0f0f; }
        .chip-y      { background: #2a200d; color: #d4a017; border: 1px solid #3d2e0f; }
        .chip-blue   { background: #0d1a2e; color: #5a9af5; border: 1px solid #0f2544; }
        .chip-purple { background: #1a0d2e; color: #9b6af5; border: 1px solid #280f44; }

        /* 모달 */
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.7); z-index: 200; align-items: center; justify-content: center; }
        .modal-overlay.open { display: flex; }
        .modal { background: #131519; border: 1px solid #1e2025; border-radius: 14px; padding: 28px; width: 520px; max-width: 95vw; max-height: 90vh; overflow-y: auto; }
        .modal-title { font-size: 15px; font-weight: 500; color: #f2f3f5; margin-bottom: 20px; }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
        .form-grid .full { grid-column: 1 / -1; }
        .form-group label { display: block; font-size: 11px; color: #6b7280; letter-spacing: 0.05em; text-transform: uppercase; margin-bottom: 6px; }
        .form-group input, .form-group select, .form-group textarea {
            width: 100%; background: #0e0f11; border: 1px solid #1e2025; border-radius: 8px;
            padding: 8px 12px; font-size: 13px; color: #e8e9eb;
            font-family: 'DM Sans', sans-serif; outline: none; transition: border 0.15s;
        }
        .form-group input:focus, .form-group select:focus, .form-group textarea:focus { border-color: #3b6ef5; }
        .form-group select option { background: #131519; }
        .form-group textarea { resize: vertical; min-height: 72px; }
        .modal-footer { display: flex; justify-content: flex-end; gap: 8px; margin-top: 20px; }
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
    <a href="../CustomerServlet?action=list" class="sb-item active">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>
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
        <div class="user-row">
            <div class="avatar"><%= loginName != null ? String.valueOf(loginName.charAt(0)) : "관" %></div>
            <div class="user-info"><p><%= loginName %></p><span><%= loginRole %></span></div>
        </div>
        <a href="../LogoutServlet" class="logout-btn">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
            로그아웃
        </a>
    </div>
</nav>

<!-- 메인 -->
<div class="main">
    <div class="topbar">
        <div class="topbar-left">
            <a href="../CustomerServlet?action=list" class="back-btn">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><polyline points="15 18 9 12 15 6"/></svg>
                목록으로
            </a>
            <span style="color:#1e2025">|</span>
            <span class="topbar-title"><%= cust != null ? cust.custName : "고객사 상세" %></span>
        </div>
    </div>

    <div class="content">
        <% if (dbError != null) { %>
        <div style="background:#2a0d0d;border:1px solid #3d0f0f;border-radius:8px;padding:12px 16px;color:#e05656;margin-bottom:16px;font-size:13px;">⚠ DB 오류: <%= dbError %></div>
        <% } %>

        <% if (cust != null) { %>
        <!-- 고객사 헤더 -->
        <div class="cust-header">
            <div class="cust-title">
                <div class="cust-avatar"><%= String.valueOf(cust.custName.charAt(0)) %></div>
                <div>
                    <div class="cust-name"><%= cust.custName %></div>
                    <div class="cust-code"><%= nvl(cust.custCode) %> · <%= nvl(cust.industry) %></div>
                </div>
            </div>
            <div class="cust-meta">
                <div class="meta-item"><strong>담당자</strong><%= nvl(cust.managerName) %></div>
                <div class="meta-item"><strong>연락처</strong><%= nvl(cust.managerTel) %></div>
                <div class="meta-item"><strong>서비스</strong><%= nvl(cust.serviceType) %></div>
                <div class="meta-item">
                    <strong>상태</strong>
                    <span class="chip <%= statusChip(cust.status) %>"><%= statusLabel(cust.status) %></span>
                </div>
            </div>
        </div>

        <!-- 탭 -->
        <div class="tab-bar">
            <button class="tab-btn <%= "project".equals(activeTab) ? "active" : "" %>" onclick="switchTab('project')">
                📋 사업정보 (<%= projects.size() %>)
            </button>
            <button class="tab-btn <%= "asset".equals(activeTab) ? "active" : "" %>" onclick="switchTab('asset')">
                🖥 IT 자산 (<%= assets.size() %>)
            </button>
        </div>

        <!-- 사업정보 탭 -->
        <div id="tab-project" class="tab-panel <%= "project".equals(activeTab) ? "active" : "" %>">
            <div class="panel-header">
                <span class="panel-title">사업정보 목록</span>
                <button class="btn btn-primary btn-sm" onclick="openProjectModal()">+ 사업 추가</button>
            </div>
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>사업명</th>
                            <th>담당자</th>
                            <th style="text-align:right">계약금액</th>
                            <th>사업기간</th>
                            <th>상태</th>
                            <th>관리</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (projects.isEmpty()) { %>
                        <tr class="empty-row"><td colspan="6">등록된 사업정보가 없습니다.</td></tr>
                        <% } else { for (ProjectVO p : projects) { %>
                        <tr>
                            <td><strong style="color:#e8e9eb"><%= nvl(p.projName) %></strong></td>
                            <td><%= nvl(p.managerName) %></td>
                            <td class="td-mono" style="text-align:right"><%= fmtAmt(p.contractAmt) %></td>
                            <td class="td-mono" style="font-size:12px;color:#6b7280">
                                <%= nvl(p.contractStart) %><%= (p.contractStart != null && !p.contractStart.isEmpty()) ? " ~ " : "" %><%= nvl(p.contractEnd) %>
                            </td>
                            <td><span class="chip <%= statusChip(p.status) %>"><%= statusLabel(p.status) %></span></td>
                            <td>
                                <div class="td-actions">
                                    <button class="btn btn-sm btn-secondary" onclick="openProjectModal(<%= p.projSeq %>, '<%= p.projName.replace("'", "\\'") %>', '<%= p.contractAmt %>', '<%= nvl(p.contractStart) %>', '<%= nvl(p.contractEnd) %>', '<%= nvl(p.status) %>', '<%= nvl(p.managerName).replace("'", "\\'") %>', '<%= nvl(p.memo).replace("'", "\\'") %>')">수정</button>
                                    <form action="../CustomerDetailServlet" method="post" style="display:inline" onsubmit="return confirm('삭제하시겠습니까?')">
                                        <input type="hidden" name="action" value="projectDelete">
                                        <input type="hidden" name="custSeq" value="<%= cust.custSeq %>">
                                        <input type="hidden" name="projSeq" value="<%= p.projSeq %>">
                                        <button type="submit" class="btn btn-sm btn-danger">삭제</button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                        <% } } %>
                    </tbody>
                </table>
            </div>
        </div>

        <!-- IT 자산 탭 -->
        <div id="tab-asset" class="tab-panel <%= "asset".equals(activeTab) ? "active" : "" %>">

            <!-- 서브탭 -->
            <div class="sub-tab-bar">
                <button class="sub-tab-btn <%= "rack".equals(activeSub) ? "" : "active" %>" onclick="switchSubTab('asset-list', this)">장비 목록</button>
                <button class="sub-tab-btn <%= "rack".equals(activeSub) ? "active" : "" %>" onclick="switchSubTab('asset-rack', this)">랙 실장도</button>
            </div>

            <!-- 장비 목록 -->
            <div id="sub-asset-list" class="sub-tab-panel <%= "rack".equals(activeSub) ? "" : "active" %>">
                <div class="panel-header">
                    <span class="panel-title">장비 목록</span>
                    <button class="btn btn-primary btn-sm" onclick="openAssetModal()">+ 자산 추가</button>
                </div>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>유형</th>
                                <th>자산명</th>
                                <th>모델</th>
                                <th>IP 주소</th>
                                <th>OS</th>
                                <th>위치</th>
                                <th>도입일</th>
                                <th>상태</th>
                                <th>관리</th>
                            </tr>
                        </thead>
                        <tbody>
                            <% if (assets.isEmpty()) { %>
                            <tr class="empty-row"><td colspan="9">등록된 자산이 없습니다.</td></tr>
                            <% } else { for (AssetVO a : assets) { %>
                            <tr>
                                <td><span class="chip <%= assetTypeChip(a.assetType) %>"><%= assetTypeLabel(a.assetType) %></span></td>
                                <td><strong style="color:#e8e9eb"><%= nvl(a.assetName) %></strong></td>
                                <td class="td-mono" style="font-size:12px"><%= nvl(a.model) %></td>
                                <td class="td-mono" style="font-size:12px">
                                    <% if (a.ipAddr != null && !a.ipAddr.isEmpty()) {
                                        for (String ip : a.ipAddr.split(",")) { %>
                                    <div><%= ip.trim() %></div>
                                    <% } } else { %><span style="color:#3d4251">-</span><% } %>
                                </td>
                                <td style="font-size:12px;color:#6b7280"><%= nvl(a.osInfo) %></td>
                                <td style="font-size:12px"><%= nvl(a.location) %></td>
                                <td class="td-mono" style="font-size:12px;color:#6b7280"><%= nvl(a.purchaseDt) %></td>
                                <td><span class="chip <%= statusChip(a.status) %>"><%= statusLabel(a.status) %></span></td>
                                <td>
                                    <div class="td-actions">
                                        <button class="btn btn-sm btn-secondary" onclick="openAssetModal(<%= a.assetSeq %>, '<%= nvl(a.assetType) %>', '<%= a.assetName.replace("'", "\\'") %>', '<%= nvl(a.model).replace("'", "\\'") %>', '<%= nvl(a.ipAddr).replace("\n","").replace("\r","") %>', '<%= nvl(a.osInfo).replace("'", "\\'") %>', '<%= nvl(a.location).replace("'", "\\'") %>', '<%= nvl(a.status) %>', '<%= nvl(a.purchaseDt) %>', '<%= nvl(a.memo).replace("'", "\\'") %>')">수정</button>
                                        <form action="../CustomerDetailServlet" method="post" style="display:inline" onsubmit="return confirm('삭제하시겠습니까?')">
                                            <input type="hidden" name="action" value="assetDelete">
                                            <input type="hidden" name="custSeq" value="<%= cust.custSeq %>">
                                            <input type="hidden" name="assetSeq" value="<%= a.assetSeq %>">
                                            <button type="submit" class="btn btn-sm btn-danger">삭제</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            <% } } %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- 랙 실장도 -->
            <div id="sub-asset-rack" class="sub-tab-panel <%= "rack".equals(activeSub) ? "active" : "" %>">
                <div class="panel-header">
                    <span class="panel-title">랙 실장도</span>
                    <button class="btn btn-primary btn-sm" onclick="openRackModal()">+ 랙 추가</button>
                </div>

                <% if (racks.isEmpty()) { %>
                <div class="rack-placeholder">
                    <div class="rack-placeholder-icon">
                        <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#3d4251" stroke-width="1.2">
                            <rect x="2" y="2" width="20" height="20" rx="2"/>
                            <line x1="2" y1="7" x2="22" y2="7"/>
                            <line x1="2" y1="12" x2="22" y2="12"/>
                            <line x1="2" y1="17" x2="22" y2="17"/>
                        </svg>
                    </div>
                    <div class="rack-placeholder-title">등록된 랙이 없습니다</div>
                    <div class="rack-placeholder-desc">+ 랙 추가 버튼으로 서버 랙을 등록하세요.</div>
                </div>
                <% } else { %>

                <!-- 랙 카드 목록 -->
                <div class="rack-list" id="rackList">
                <% for (RackVO rack : racks) { %>
                    <div class="rack-card">
                        <!-- 랙 헤더 -->
                        <div class="rack-card-header">
                            <div>
                                <div class="rack-card-name"><%= rack.rackName %></div>
                                <% if (rack.location != null && !rack.location.isEmpty()) { %>
                                <div class="rack-card-loc"><%= rack.location %></div>
                                <% } %>
                            </div>
                            <div style="display:flex;gap:6px;align-items:center">
                                <div class="rack-side-toggle">
                                    <button class="rack-side-btn active" onclick="switchRackSide(this, 'F')">전면</button>
                                    <button class="rack-side-btn" onclick="switchRackSide(this, 'B')">후면</button>
                                </div>
                                <button class="btn btn-sm btn-secondary" onclick="openRackModal(<%= rack.rackSeq %>, '<%= rack.rackName.replace("'","\\'") %>', <%= rack.totalU %>, '<%= rack.location != null ? rack.location.replace("'","\\'") : "" %>', '<%= rack.memo != null ? rack.memo.replace("'","\\'") : "" %>')">수정</button>
                                <form action="../CustomerDetailServlet" method="post" style="display:inline" onsubmit="return confirm('랙을 삭제하면 모든 슬롯 데이터도 삭제됩니다. 계속할까요?')">
                                    <input type="hidden" name="action" value="rackDelete">
                                    <input type="hidden" name="custSeq" value="<%= cust.custSeq %>">
                                    <input type="hidden" name="rackSeq" value="<%= rack.rackSeq %>">
                                    <button type="submit" class="btn btn-sm btn-danger">삭제</button>
                                </form>
                            </div>
                        </div>

                        <!-- 랙 바디 (전면/후면) -->
                        <div class="rack-body" data-rack="<%= rack.rackSeq %>" data-totalu="<%= rack.totalU %>">
                            <!-- 전면 -->
                            <div class="rack-view rack-front active">
                                <div class="rack-frame">
                                    <div class="rack-left-rail"></div>
                                    <div class="rack-slots" id="rack-F-<%= rack.rackSeq %>">
                                        <!-- JS로 렌더링 -->
                                    </div>
                                    <div class="rack-right-rail"></div>
                                </div>
                            </div>
                            <!-- 후면 -->
                            <div class="rack-view rack-back">
                                <div class="rack-frame">
                                    <div class="rack-left-rail"></div>
                                    <div class="rack-slots" id="rack-B-<%= rack.rackSeq %>">
                                        <!-- JS로 렌더링 -->
                                    </div>
                                    <div class="rack-right-rail"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                <% } %>
                </div>
                <% } %>
            </div>

        </div>
        <% } %>
    </div>
</div>

<!-- 랙 추가/수정 모달 -->
<div class="modal-overlay" id="rackModal">
    <div class="modal">
        <div class="modal-title" id="rackModalTitle">랙 추가</div>
        <form action="../CustomerDetailServlet" method="post">
            <input type="hidden" name="action" value="rackSave">
            <input type="hidden" name="custSeq" value="<%= cust != null ? cust.custSeq : 0 %>">
            <input type="hidden" name="rackSeq" id="rackSeq" value="">
            <div class="form-grid">
                <div class="form-group">
                    <label>랙 이름 *</label>
                    <input type="text" name="rackName" id="rackName" placeholder="예: 서버랙 #1" required>
                </div>
                <div class="form-group">
                    <label>총 U 수</label>
                    <select name="totalU" id="rackTotalU">
                        <option value="14">14U</option>
                        <option value="22">22U</option>
                        <option value="27">27U</option>
                        <option value="36">36U</option>
                        <option value="42" selected>42U</option>
                        <option value="45">45U</option>
                        <option value="47">47U</option>
                    </select>
                </div>
                <div class="form-group full">
                    <label>위치</label>
                    <input type="text" name="location" id="rackLocation" placeholder="예: IDC 1F A열">
                </div>
                <div class="form-group full">
                    <label>메모</label>
                    <textarea name="memo" id="rackMemo" placeholder="비고사항"></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeModal('rackModal')">취소</button>
                <button type="submit" class="btn btn-primary">저장</button>
            </div>
        </form>
    </div>
</div>

<!-- 랙 유닛 추가/수정 모달 -->
<div class="modal-overlay" id="rackUnitModal">
    <div class="modal">
        <div class="modal-title" id="rackUnitModalTitle">장비 추가</div>
        <form action="../CustomerDetailServlet" method="post">
            <input type="hidden" name="action" value="rackUnitSave">
            <input type="hidden" name="custSeq" value="<%= cust != null ? cust.custSeq : 0 %>">
            <input type="hidden" name="rackSeq" id="unitRackSeq" value="">
            <input type="hidden" name="unitSeq" id="unitSeq" value="">
            <input type="hidden" name="side"    id="unitSide" value="F">
            <input type="hidden" name="startU"  id="unitStartU" value="">
            <div class="form-grid">
                <div class="form-group">
                    <label>장비명 *</label>
                    <input type="text" name="deviceName" id="unitDeviceName" placeholder="예: web-server-01" required>
                </div>
                <div class="form-group">
                    <label>장비 유형</label>
                    <select name="deviceType" id="unitDeviceType">
                        <option value="SERVER">SERVER</option>
                        <option value="NETWORK">NETWORK</option>
                        <option value="SECURITY">SECURITY</option>
                        <option value="STORAGE">STORAGE</option>
                        <option value="PDU">PDU</option>
                        <option value="PATCH">PATCH</option>
                        <option value="KVM">KVM</option>
                        <option value="BLANK">BLANK</option>
                        <option value="ETC">ETC</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>시작 위치</label>
                    <input type="text" id="unitStartUDisplay" readonly style="color:#4b5161">
                </div>
                <div class="form-group">
                    <label>크기 (U)</label>
                    <select name="sizeU" id="unitSizeU">
                        <% for (int u = 1; u <= 10; u++) { %>
                        <option value="<%= u %>"><%= u %>U</option>
                        <% } %>
                    </select>
                </div>
                <div class="form-group full">
                    <label>IP 주소</label>
                    <input type="text" name="ipAddr" id="unitIpAddr" placeholder="예: 192.168.1.10, 192.168.1.11">
                </div>
                <div class="form-group full">
                    <label>메모</label>
                    <textarea name="memo" id="unitMemo" placeholder="비고사항"></textarea>
                </div>
            </div>
            <div class="modal-footer" style="justify-content:space-between">
                <div id="unitDeleteBtn" style="display:none">
                    <button type="button" class="btn btn-danger" onclick="submitUnitDelete()">장비 삭제</button>
                </div>
                <div style="display:flex;gap:8px">
                    <button type="button" class="btn btn-secondary" onclick="closeModal('rackUnitModal')">취소</button>
                    <button type="submit" class="btn btn-primary">저장</button>
                </div>
            </div>
        </form>
    </div>
</div>

<!-- 랙 유닛 삭제 전용 폼 (모달 밖) -->
<form id="unitDeleteForm" action="../CustomerDetailServlet" method="post" style="display:none">
    <input type="hidden" name="action" value="rackUnitDelete">
    <input type="hidden" name="custSeq" value="<%= cust != null ? cust.custSeq : 0 %>">
    <input type="hidden" name="unitSeq" id="unitDeleteSeq" value="">
</form>

<!-- 사업정보 모달 -->
<div class="modal-overlay" id="projectModal">
    <div class="modal">
        <div class="modal-title" id="projectModalTitle">사업 추가</div>
        <form action="../CustomerDetailServlet" method="post">
            <input type="hidden" name="action" value="projectSave">
            <input type="hidden" name="custSeq" value="<%= cust != null ? cust.custSeq : 0 %>">
            <input type="hidden" name="projSeq" id="projSeq" value="">
            <div class="form-grid">
                <div class="form-group full">
                    <label>사업명 *</label>
                    <input type="text" name="projName" id="projName" placeholder="사업명을 입력하세요" required>
                </div>
                <div class="form-group">
                    <label>계약금액</label>
                    <input type="text" name="contractAmt" id="projAmt" placeholder="예: 50000000">
                </div>
                <div class="form-group">
                    <label>담당자</label>
                    <input type="text" name="managerName" id="projManager" placeholder="담당자명">
                </div>
                <div class="form-group">
                    <label>시작일</label>
                    <input type="date" name="contractStart" id="projStart">
                </div>
                <div class="form-group">
                    <label>종료일</label>
                    <input type="date" name="contractEnd" id="projEnd">
                </div>
                <div class="form-group full">
                    <label>상태</label>
                    <select name="status" id="projStatus">
                        <option value="ACTIVE">진행중</option>
                        <option value="DONE">완료</option>
                        <option value="PENDING">대기</option>
                        <option value="INACTIVE">비활성</option>
                    </select>
                </div>
                <div class="form-group full">
                    <label>메모</label>
                    <textarea name="memo" id="projMemo" placeholder="비고사항"></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeModal('projectModal')">취소</button>
                <button type="submit" class="btn btn-primary">저장</button>
            </div>
        </form>
    </div>
</div>

<!-- IT 자산 모달 -->
<div class="modal-overlay" id="assetModal">
    <div class="modal">
        <div class="modal-title" id="assetModalTitle">자산 추가</div>
        <form action="../CustomerDetailServlet" method="post">
            <input type="hidden" name="action" value="assetSave">
            <input type="hidden" name="custSeq" value="<%= cust != null ? cust.custSeq : 0 %>">
            <input type="hidden" name="assetSeq" id="assetSeq" value="">
            <div class="form-grid">
                <div class="form-group">
                    <label>장비 유형 *</label>
                    <select name="assetType" id="assetType">
                        <option value="SERVER">서버</option>
                        <option value="NETWORK">네트워크</option>
                        <option value="SECURITY">보안</option>
                        <option value="ETC">기타</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>자산명 *</label>
                    <input type="text" name="assetName" id="assetName" placeholder="자산명" required>
                </div>
                <div class="form-group">
                    <label>모델명</label>
                    <input type="text" name="model" id="assetModel" placeholder="제조사/모델">
                </div>
                <div class="form-group full">
                    <label>IP 주소 (여러 개일 경우 콤마로 구분)</label>
                    <input type="text" name="ipAddr" id="assetIp" placeholder="예: 192.168.1.10, 192.168.1.11">
                </div>
                <div class="form-group">
                    <label>OS / 펌웨어</label>
                    <input type="text" name="osInfo" id="assetOs" placeholder="예: Ubuntu 22.04">
                </div>
                <div class="form-group">
                    <label>위치</label>
                    <input type="text" name="location" id="assetLocation" placeholder="예: IDC 1F 랙 A-3">
                </div>
                <div class="form-group">
                    <label>도입일</label>
                    <input type="date" name="purchaseDt" id="assetPurchase">
                </div>
                <div class="form-group full">
                    <label>상태</label>
                    <select name="status" id="assetStatus">
                        <option value="ACTIVE">운영중</option>
                        <option value="INACTIVE">중지</option>
                        <option value="PENDING">대기</option>
                    </select>
                </div>
                <div class="form-group full">
                    <label>메모</label>
                    <textarea name="memo" id="assetMemo" placeholder="비고사항"></textarea>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" onclick="closeModal('assetModal')">취소</button>
                <button type="submit" class="btn btn-primary">저장</button>
            </div>
        </form>
    </div>
</div>

<script>
    function switchTab(tab) {
        document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.getElementById('tab-' + tab).classList.add('active');
        event.target.classList.add('active');
    }

    function switchSubTab(id, btn) {
        const panel = btn.closest('.tab-panel');
        panel.querySelectorAll('.sub-tab-panel').forEach(p => p.classList.remove('active'));
        panel.querySelectorAll('.sub-tab-btn').forEach(b => b.classList.remove('active'));
        document.getElementById('sub-' + id).classList.add('active');
        btn.classList.add('active');
    }

    // ── 랙 사이드 전환 ───────────────────────────────────
    function switchRackSide(btn, side) {
        const card = btn.closest('.rack-card');
        card.querySelectorAll('.rack-side-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        card.querySelectorAll('.rack-view').forEach(v => v.classList.remove('active'));
        card.querySelector(side === 'F' ? '.rack-front' : '.rack-back').classList.add('active');
    }

    // ── 랙 모달 ─────────────────────────────────────────
    function openRackModal(rackSeq, name, totalU, loc, memo) {
        document.getElementById('rackModalTitle').textContent = rackSeq ? '랙 수정' : '랙 추가';
        document.getElementById('rackSeq').value     = rackSeq || '';
        document.getElementById('rackName').value    = name    || '';
        document.getElementById('rackTotalU').value  = totalU  || '42';
        document.getElementById('rackLocation').value = loc    || '';
        document.getElementById('rackMemo').value    = memo    || '';
        document.getElementById('rackModal').classList.add('open');
    }

    // ── 유닛 모달 (빈 슬롯 클릭 → 추가) ─────────────────
    function openAddUnitModal(rackSeq, side, startU) {
        document.getElementById('rackUnitModalTitle').textContent = '장비 추가';
        document.getElementById('unitRackSeq').value   = rackSeq;
        document.getElementById('unitSeq').value       = '';
        document.getElementById('unitSide').value      = side;
        document.getElementById('unitStartU').value    = startU;
        document.getElementById('unitStartUDisplay').value = startU + 'U (' + (side === 'F' ? '전면' : '후면') + ')';
        document.getElementById('unitDeviceName').value = '';
        document.getElementById('unitDeviceType').value = 'SERVER';
        document.getElementById('unitSizeU').value     = '1';
        document.getElementById('unitIpAddr').value    = '';
        document.getElementById('unitMemo').value      = '';
        document.getElementById('unitDeleteBtn').style.display = 'none';
        document.getElementById('rackUnitModal').classList.add('open');
    }

    // ── 유닛 모달 (장비 슬롯 클릭 → 수정) ───────────────
    function openEditUnitModal(rackSeq, side, unitSeq, startU, sizeU, name, type, ip, memo) {
        document.getElementById('rackUnitModalTitle').textContent = '장비 수정';
        document.getElementById('unitRackSeq').value   = rackSeq;
        document.getElementById('unitSeq').value       = unitSeq;
        document.getElementById('unitSide').value      = side;
        document.getElementById('unitStartU').value    = startU;
        document.getElementById('unitStartUDisplay').value = startU + 'U (' + (side === 'F' ? '전면' : '후면') + ')';
        document.getElementById('unitDeviceName').value = name  || '';
        document.getElementById('unitDeviceType').value = type  || 'SERVER';
        document.getElementById('unitSizeU').value     = sizeU || '1';
        document.getElementById('unitIpAddr').value    = ip    || '';
        document.getElementById('unitMemo').value      = memo  || '';
        document.getElementById('unitDeleteBtn').style.display = 'block';
        document.getElementById('unitDeleteSeq').value = unitSeq;
        document.getElementById('rackUnitModal').classList.add('open');
    }

    function submitUnitDelete() {
        if (!confirm('이 장비를 삭제하시겠습니까?')) return;
        document.getElementById('unitDeleteForm').submit();
    }

    // ── 랙 슬롯 렌더링 ──────────────────────────────────
    const RACK_DATA = <%
        // 랙 데이터를 JSON으로 직렬화
        StringBuilder rackJson = new StringBuilder("[");
        for (int ri = 0; ri < racks.size(); ri++) {
            com.admin.servlet.CustomerDetailServlet.RackVO r = racks.get(ri);
            if (ri > 0) rackJson.append(",");
            rackJson.append("{\"rackSeq\":").append(r.rackSeq)
                    .append(",\"totalU\":").append(r.totalU)
                    .append(",\"units\":[");
            for (int ui = 0; ui < r.units.size(); ui++) {
                com.admin.servlet.CustomerDetailServlet.RackUnitVO u = r.units.get(ui);
                if (ui > 0) rackJson.append(",");
                String safeIp   = u.ipAddr   != null ? u.ipAddr.replace("\"","\\\"").replace("\n","").replace("\r","") : "";
                String safeMemo = u.memo      != null ? u.memo.replace("\"","\\\"").replace("\n"," ").replace("\r","") : "";
                String safeName = u.deviceName.replace("\"","\\\"");
                rackJson.append("{\"unitSeq\":").append(u.unitSeq)
                        .append(",\"side\":\"").append(u.side).append("\"")
                        .append(",\"startU\":").append(u.startU)
                        .append(",\"sizeU\":").append(u.sizeU)
                        .append(",\"deviceName\":\"").append(safeName).append("\"")
                        .append(",\"deviceType\":\"").append(u.deviceType).append("\"")
                        .append(",\"ipAddr\":\"").append(safeIp).append("\"")
                        .append(",\"memo\":\"").append(safeMemo).append("\"")
                        .append("}");
            }
            rackJson.append("]}");
        }
        rackJson.append("]");
        out.print(rackJson.toString());
    %>;

    const TYPE_CSS = {
        SERVER:'type-server',NETWORK:'type-network',SECURITY:'type-security',
        STORAGE:'type-storage',PDU:'type-pdu',PATCH:'type-patch',
        KVM:'type-kvm',BLANK:'type-blank',ETC:'type-etc'
    };
    const CHIP_CSS = {
        SERVER:'chip-server',NETWORK:'chip-network',SECURITY:'chip-security',
        STORAGE:'chip-storage',PDU:'chip-pdu',PATCH:'chip-patch',
        KVM:'chip-kvm',BLANK:'chip-blank',ETC:'chip-etc'
    };

    function renderRacks() {
        RACK_DATA.forEach(rack => {
            ['F','B'].forEach(side => {
                const container = document.getElementById('rack-' + side + '-' + rack.rackSeq);
                if (!container) return;

                // 점유 맵 구성
                const occupied = {};
                rack.units.filter(u => u.side === side).forEach(u => {
                    for (let i = u.startU; i < u.startU + u.sizeU; i++) occupied[i] = u;
                });

                let html = '';
                let skip = 0;
                const U_H = 26;
                for (let u = 1; u <= rack.totalU; u++) {
                    if (skip > 0) { skip--; continue; }
                    const dev = occupied[u];
                    if (dev) {
                        const h = dev.sizeU * U_H - 1;
                        const tc = TYPE_CSS[dev.deviceType] || 'type-etc';
                        const cc = CHIP_CSS[dev.deviceType] || 'chip-etc';
                        const ip1 = dev.ipAddr ? dev.ipAddr.split(',')[0].trim() : '';
                        const esc = s => (s||'').replace(/\\/g,'\\\\').replace(/'/g,"\\'");
                        const onclk = 'openEditUnitModal(' + rack.rackSeq + ',\'' + side + '\',' + dev.unitSeq + ',' + dev.startU + ',' + dev.sizeU + ',\'' + esc(dev.deviceName) + '\',\'' + esc(dev.deviceType) + '\',\'' + esc(dev.ipAddr) + '\',\'' + esc(dev.memo) + '\')';
                        html += '<div class="rack-slot ' + tc + '" style="height:' + h + 'px;min-height:' + h + 'px" onclick="' + onclk + '">'
                              + '<div class="rack-slot-u">' + u + 'U</div>'
                              + '<div class="rack-slot-body">'
                              + '<span class="rack-slot-name">' + dev.deviceName + '</span>'
                              + '<span class="rack-slot-type ' + cc + '">' + dev.deviceType + '</span>'
                              + (ip1 ? '<span class="rack-slot-ip">' + ip1 + '</span>' : '')
                              + '</div></div>';
                        skip = dev.sizeU - 1;
                    } else {
                        html += '<div class="rack-slot empty" style="height:' + (U_H-1) + 'px;min-height:' + (U_H-1) + 'px"'
                              + ' onclick="openAddUnitModal(' + rack.rackSeq + ',\'' + side + '\',' + u + ')">'
                              + '<div class="rack-slot-u">' + u + 'U</div>'
                              + '<div class="rack-slot-body"><span class="rack-slot-add">+ 장비 추가</span></div>'
                              + '</div>';
                    }
                }
                container.innerHTML = html;
            });
        });
    }

    renderRacks();

    function openProjectModal(projSeq, projName, amt, start, end, status, manager, memo) {
        document.getElementById('projectModalTitle').textContent = projSeq ? '사업 수정' : '사업 추가';
        document.getElementById('projSeq').value     = projSeq    || '';
        document.getElementById('projName').value    = projName   || '';
        document.getElementById('projAmt').value     = amt        || '';
        document.getElementById('projStart').value   = start      || '';
        document.getElementById('projEnd').value     = end        || '';
        document.getElementById('projStatus').value  = status     || 'ACTIVE';
        document.getElementById('projManager').value = manager    || '';
        document.getElementById('projMemo').value    = memo       || '';
        document.getElementById('projectModal').classList.add('open');
    }

    function openAssetModal(assetSeq, type, name, model, ip, os, loc, status, purchase, memo) {
        document.getElementById('assetModalTitle').textContent = assetSeq ? '자산 수정' : '자산 추가';
        document.getElementById('assetSeq').value      = assetSeq  || '';
        document.getElementById('assetType').value     = type      || 'SERVER';
        document.getElementById('assetName').value     = name      || '';
        document.getElementById('assetModel').value    = model     || '';
        document.getElementById('assetIp').value       = ip        || '';
        document.getElementById('assetOs').value       = os        || '';
        document.getElementById('assetLocation').value = loc       || '';
        document.getElementById('assetStatus').value   = status    || 'ACTIVE';
        document.getElementById('assetPurchase').value = purchase  || '';
        document.getElementById('assetMemo').value     = memo      || '';
        document.getElementById('assetModal').classList.add('open');
    }

    function closeModal(id) {
        document.getElementById(id).classList.remove('open');
    }

    // 모달 외부 클릭 시 닫기
    document.querySelectorAll('.modal-overlay').forEach(el => {
        el.addEventListener('click', function(e) {
            if (e.target === this) this.classList.remove('open');
        });
    });
</script>
</body>
</html>

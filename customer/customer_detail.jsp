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
        if ("STORAGE".equals(t))  return "스토리지";
        return "기타";
    }
    String assetTypeChip(String t) {
        if ("SERVER".equals(t))   return "chip-blue";
        if ("NETWORK".equals(t))  return "chip-purple";
        if ("SECURITY".equals(t)) return "chip-r";
        if ("STORAGE".equals(t))  return "chip-teal";
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
        .rack-card { background: #131519; border: 1px solid #1e2025; border-radius: 12px; overflow: hidden; min-width: 320px; transition: box-shadow 0.15s, opacity 0.15s; }
        .rack-card.drag-over { box-shadow: 0 0 0 2px #3b6ef5; }
        .rack-card.dragging  { opacity: 0.45; }
        .rack-card-header { display: flex; align-items: flex-start; justify-content: space-between; padding: 14px 16px; border-bottom: 1px solid #1e2025; gap: 10px; }
        .rack-drag-handle { cursor: grab; padding: 2px 2px 0; opacity: 0.5; flex-shrink: 0; margin-top: 2px; }
        .rack-drag-handle:hover { opacity: 1; }
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
        .panel-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; gap: 8px; flex-wrap: nowrap; }
        .toolbar-sep { width: 1px; height: 18px; background: #252830; flex-shrink: 0; }
        .filter-sel { padding: 5px 8px; background: #0e0f11; border: 1px solid #1e2025; border-radius: 6px; color: #b0b4bf; font-size: 12px; font-family: inherit; cursor: pointer; height: 30px; }
        #assetTable th, #assetTable td { padding: 10px 14px; font-size: 12px; vertical-align: middle; text-align: left; box-sizing: border-box; }
        .asset-child td { background: #0f1113 !important; border-left: 2px solid #1e2025; }
        .asset-child:hover td { background: #141618 !important; }
        .asset-child .cell-name { padding-left: 28px; }
        .vm-indent { color: #3d4251; margin-right: 6px; font-size: 11px; }
        .chip-role { display:inline-flex;align-items:center;gap:3px;font-size:10px;padding:2px 6px;border-radius:4px;font-family:'DM Mono',monospace;font-weight:500;flex-shrink:0; }
        .chip-hypervisor { background:#1a2e1a;color:#4caf50; }
        .chip-vm         { background:#1a1e2e;color:#6b9af5; }
        .chip-ldom       { background:#2a1e10;color:#f5a623; }
        .chip-zone       { background:#1e1a2e;color:#a78bfa; }
        .chip-container  { background:#1a2a2e;color:#22d3ee; }
        .expand-btn { display:inline-flex;align-items:center;justify-content:center;width:18px;height:18px;border:1px solid #252830;border-radius:4px;background:#0e0f11;color:#6b7280;cursor:pointer;font-size:10px;flex-shrink:0;transition:background .1s,color .1s;margin-right:6px; }
        .expand-btn:hover { background:#1a1e2e;color:#6b9af5; }
        .vm-count-badge { display:inline-flex;align-items:center;gap:3px;font-size:10px;color:#4b5161;background:#131519;border:1px solid #1e2025;border-radius:4px;padding:1px 5px;margin-left:6px; }
        #assetTable th { background: #0f1013; color: #6b7280; font-weight: 500; text-transform: uppercase; letter-spacing: .04em; white-space: nowrap; border-bottom: 1px solid #1e2025; cursor: grab; user-select: none; position: relative; }
        #assetTable th:active { cursor: grabbing; }
        #assetTable th.col-drag-over { background: #1a1e2e; box-shadow: inset 2px 0 0 #3b6ef5; }
        #assetTable th.col-dragging { opacity: 0.4; }
        #assetTable td { color: #c8cad0; border-bottom: 1px solid #161820; }
        #assetTable tr:last-child td { border-bottom: none; }
        #assetTable tr:hover td { background: #161820; }
        .panel-title { font-size: 13px; font-weight: 500; color: #9ca3af; }
        .table-wrap { background: #131519; border: 1px solid #1e2025; border-radius: 12px; overflow: hidden; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #0f1013; padding: 11px 16px; font-size: 11px; font-weight: 500; color: #6b7280; text-align: left; letter-spacing: 0.05em; text-transform: uppercase; border-bottom: 1px solid #1e2025; white-space: nowrap; vertical-align: middle; }
        td { padding: 12px 16px; font-size: 13px; color: #c8cad0; border-bottom: 1px solid #161820; vertical-align: middle; }
        th[data-col="type"], td[data-col="type"],
        th[data-col="size"], td[data-col="size"],
        th[data-col="status"], td[data-col="status"],
        th[data-col="actions"], td[data-col="actions"] { text-align: center; }
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
        .chip-teal   { background: #0d2229; color: #3dd6c8; border: 1px solid #0f3540; }

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
                    <span class="panel-title" style="flex-shrink:0">장비 목록</span>
                    <!-- 필터 + 버튼 한 줄 -->
                    <div style="display:flex;align-items:center;gap:8px;flex:1;justify-content:flex-end;min-width:0">
                        <select id="filterType" class="filter-sel" onchange="applyAssetFilter()">
                            <option value="">전체 유형</option>
                            <option value="SERVER">서버</option>
                            <option value="NETWORK">네트워크</option>
                            <option value="SECURITY">보안</option>
                            <option value="STORAGE">스토리지</option>
                            <option value="ETC">기타</option>
                        </select>
                        <select id="filterStatus" class="filter-sel" onchange="applyAssetFilter()">
                            <option value="">전체 상태</option>
                            <option value="ACTIVE">운영중</option>
                            <option value="INACTIVE">중지</option>
                            <option value="PENDING">대기</option>
                        </select>
                        <span id="assetCount" style="font-size:12px;color:#4b5161;white-space:nowrap"></span>
                        <div class="toolbar-sep"></div>
                        <button class="btn btn-sm btn-secondary" onclick="resetAssetFilter()">필터초기화</button>
                        <div style="position:relative">
                            <button class="btn btn-sm btn-secondary" onclick="toggleColPanel()" id="colToggleBtn">컬럼 설정 ▾</button>
                            <div id="colPanel" style="display:none;position:absolute;right:0;top:34px;background:#1a1c22;border:1px solid #252830;border-radius:10px;padding:14px 16px;z-index:200;min-width:220px;box-shadow:0 8px 24px rgba(0,0,0,0.5)">
                                <div style="font-size:11px;color:#4b5161;margin-bottom:10px;font-weight:500;letter-spacing:.5px">표시할 컬럼 선택</div>
                                <div id="colCheckboxes" style="display:flex;flex-direction:column;gap:7px"></div>
                                <div style="margin-top:12px;padding-top:10px;border-top:1px solid #252830">
                                    <button class="btn btn-sm btn-secondary" onclick="resetColVisibility()" style="width:100%;font-size:11px">기본값으로</button>
                                </div>
                            </div>
                        </div>
                        <button class="btn btn-primary btn-sm" onclick="openAssetModal()">+ 서버 추가</button>
                    </div>
                </div>
                <div class="table-wrap">
                    <table id="assetTable">
                        <thead>
                            <tr>
                                <th data-col="type">유형</th>
                                <th data-col="name" onclick="sortAsset('name')">서버명 <span id="sort-name" style="color:#3b6ef5;font-weight:400">↕</span></th>
                                <th data-col="maker">제조사</th>
                                <th data-col="model">모델</th>
                                <th data-col="size">크기</th>
                                <th data-col="hostname">HostName</th>
                                <th data-col="ip">IP 주소</th>
                                <th data-col="disk">Disk</th>
                                <th data-col="cpu">CPU</th>
                                <th data-col="memory">Memory</th>
                                <th data-col="location">위치</th>
                                <th data-col="os">OS</th>
                                <th data-col="purchase" onclick="sortAsset('purchase')">도입일 <span id="sort-purchase" style="color:#3d4251;font-weight:400">↕</span></th>
                                <th data-col="status">상태</th>
                                <th data-col="actions" style="cursor:default">관리</th>
                            </tr>
                        </thead>
                        <tbody id="assetTbody">
                            <% if (assets.isEmpty()) { %>
                            <tr class="empty-row"><td colspan="15">등록된 서버/장비가 없습니다.</td></tr>
                            <% } else { for (AssetVO a : assets) {
                                boolean isChild = a.parentSeq != 0;
                                boolean isHypervisor = "HYPERVISOR".equals(a.assetRole);
                                String rowClass = isChild ? "asset-child" : "asset-parent";
                                String roleChipClass = "HYPERVISOR".equals(a.assetRole) ? "chip-hypervisor"
                                    : "VM".equals(a.assetRole) ? "chip-vm"
                                    : "LDOM".equals(a.assetRole) ? "chip-ldom"
                                    : "CONTAINER".equals(a.assetRole) ? "chip-container" : "";
                                String virtLabel = "";
                                if (a.virtType != null) {
                                    switch (a.virtType) {
                                        case "VMWARE":    virtLabel = "VMware";    break;
                                        case "KVM":       virtLabel = "KVM";       break;
                                        case "HYPERV":    virtLabel = "Hyper-V";   break;
                                        case "PROXMOX":   virtLabel = "Proxmox";   break;
                                        case "XEN":       virtLabel = "Xen";       break;
                                        case "ORACLE_VM": virtLabel = "ORACLE VM"; break;
                                        case "DOCKER":    virtLabel = "Docker";    break;
                                        default:          virtLabel = "HV";        break;
                                    }
                                }
                                String roleLabel = "HYPERVISOR".equals(a.assetRole) ? (virtLabel.isEmpty() ? "HV" : virtLabel)
                                    : "VM".equals(a.assetRole) ? "VM"
                                    : "LDOM".equals(a.assetRole) ? "LDOM"
                                    : "CONTAINER".equals(a.assetRole) ? "CNTR" : "";
                            %>
                            <tr class="<%= rowClass %>"
                                data-asset-id="<%= a.assetSeq %>"
                                data-parent-id="<%= a.parentSeq %>"
                                data-type="<%= nvl(a.assetType) %>"
                                data-status="<%= nvl(a.status) %>"
                                data-name="<%= a.assetName.toLowerCase() %>"
                                data-purchase="<%= nvl(a.purchaseDt) %>"
                                <%= isChild ? "style=\"display:none\"" : "" %>>
                                <td data-col="type"><span class="chip <%= assetTypeChip(a.assetType) %>"><%= assetTypeLabel(a.assetType) %></span></td>
                                <td data-col="name" class="cell-name">
                                    <div style="display:flex;align-items:center;gap:0">
                                        <% if (!isChild && a.childCount > 0) { %>
                                        <span class="expand-btn" onclick="toggleChildren(<%= a.assetSeq %>)" id="expand-<%= a.assetSeq %>">▶</span>
                                        <% } else if (isChild) { %>
                                        <span class="vm-indent">└</span>
                                        <% } %>
                                        <strong style="color:#e8e9eb;font-size:13px"><%= nvl(a.assetName) %></strong>
                                        <% if (!roleChipClass.isEmpty()) { %>
                                        <span class="chip-role <%= roleChipClass %>" style="margin-left:6px"><%= roleLabel %></span>
                                        <% } %>
                                        <% if (!isChild && a.childCount > 0) { %>
                                        <span class="vm-count-badge"><%= a.childCount %>개</span>
                                        <% } %>
                                    </div>
                                </td>
                                <td data-col="maker"><%= nvl(a.maker) %></td>
                                <td data-col="model" class="td-mono"><%= nvl(a.model) %></td>
                                <td data-col="size" class="td-mono"><%= a.sizeU != null ? a.sizeU + "U" : "-" %></td>
                                <td data-col="hostname" class="td-mono"><%= nvl(a.hostname) %></td>
                                <td data-col="ip" class="td-mono">
                                    <% if (a.ipAddr != null && !a.ipAddr.isEmpty()) {
                                        for (String ip : a.ipAddr.split(",")) { %>
                                    <div><%= ip.trim() %></div>
                                    <% } } else { %><span style="color:#3d4251">-</span><% } %>
                                </td>
                                <td data-col="disk" style="color:#6b7280"><%= nvl(a.disk) %></td>
                                <td data-col="cpu" style="color:#6b7280"><%= nvl(a.cpu) %></td>
                                <td data-col="memory" style="color:#6b7280"><%= nvl(a.memory) %></td>
                                <td data-col="location"><%= nvl(a.location) %></td>
                                <td data-col="os" style="color:#6b7280"><%= nvl(a.osInfo) %></td>
                                <td data-col="purchase" class="td-mono" style="color:#6b7280"><%= nvl(a.purchaseDt) %></td>
                                <td data-col="status"><span class="chip <%= statusChip(a.status) %>"><%= statusLabel(a.status) %></span></td>
                                <td data-col="actions">
                                    <div class="td-actions">
                                        <button class="btn btn-sm btn-secondary" onclick="openAssetModalBySeq(<%= a.assetSeq %>)">수정</button>
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
                    <div class="rack-card" data-rack-seq="<%= rack.rackSeq %>" draggable="true">
                        <!-- 랙 헤더 -->
                        <div class="rack-card-header">
                            <div style="display:flex;align-items:flex-start;gap:8px">
                                <div class="rack-drag-handle" title="드래그하여 순서 변경">
                                    <svg width="12" height="16" viewBox="0 0 12 16" fill="#3d4251">
                                        <circle cx="4" cy="3" r="1.5"/><circle cx="8" cy="3" r="1.5"/>
                                        <circle cx="4" cy="8" r="1.5"/><circle cx="8" cy="8" r="1.5"/>
                                        <circle cx="4" cy="13" r="1.5"/><circle cx="8" cy="13" r="1.5"/>
                                    </svg>
                                </div>
                                <div>
                                    <div class="rack-card-name"><%= rack.rackName %></div>
                                    <% if (rack.location != null && !rack.location.isEmpty()) { %>
                                    <div class="rack-card-loc"><%= rack.location %></div>
                                    <% } %>
                                </div>
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
                <!-- 랙 순서 저장 폼 -->
                <form id="rackOrderForm" action="../CustomerDetailServlet" method="post" style="display:none">
                    <input type="hidden" name="action" value="rackReorder">
                    <input type="hidden" name="custSeq" value="<%= cust != null ? cust.custSeq : 0 %>">
                    <input type="hidden" name="tab" value="asset">
                    <input type="hidden" name="sub" value="rack">
                    <input type="hidden" name="order" id="rackOrderInput" value="">
                </form>
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
    <div class="modal" style="width:580px">
        <div class="modal-title" id="rackUnitModalTitle">장비 추가</div>
        <form action="../CustomerDetailServlet" method="post">
            <input type="hidden" name="action" value="rackUnitSave">
            <input type="hidden" name="custSeq" value="<%= cust != null ? cust.custSeq : 0 %>">
            <input type="hidden" name="rackSeq" id="unitRackSeq" value="">
            <input type="hidden" name="unitSeq" id="unitSeq" value="">
            <input type="hidden" name="side"    id="unitSide" value="F">
            <input type="hidden" name="startU"  id="unitStartU" value="">

            <!-- 장비목록 선택 섹션 -->
            <div style="background:#0e0f11;border:1px solid #1e2025;border-radius:8px;padding:12px;margin-bottom:16px">
                <div style="font-size:12px;color:#6b7280;margin-bottom:8px;font-weight:500">장비목록에서 선택 (선택 시 자동 입력)</div>
                <div style="display:flex;gap:8px;margin-bottom:8px">
                    <input type="text" id="assetSearch" placeholder="자산명 또는 모델명 검색..." style="flex:1;padding:6px 10px;background:#131519;border:1px solid #252830;border-radius:6px;color:#e8e9eb;font-size:12px;font-family:inherit" oninput="filterAssets()">
                </div>
                <div id="assetPickList" style="max-height:140px;overflow-y:auto;display:flex;flex-direction:column;gap:4px"></div>
            </div>

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
    <div class="modal" style="width:640px">
        <div class="modal-title" id="assetModalTitle">서버 추가</div>
        <form action="../CustomerDetailServlet" method="post">
            <input type="hidden" name="action" value="assetSave">
            <input type="hidden" name="custSeq" value="<%= cust != null ? cust.custSeq : 0 %>">
            <input type="hidden" name="assetSeq" id="assetSeq" value="">
            <div class="form-grid">
                <div class="form-group">
                    <label>유형 *</label>
                    <select name="assetType" id="assetType" onchange="onTypeChange()">
                        <option value="SERVER">서버</option>
                        <option value="NETWORK">네트워크</option>
                        <option value="SECURITY">보안</option>
                        <option value="STORAGE">스토리지</option>
                        <option value="ETC">기타</option>
                    </select>
                </div>
                <!-- 서버 전용: 역할 -->
                <div class="form-group" id="roleRow">
                    <label>역할</label>
                    <select name="assetRole" id="assetRole" onchange="onRoleChange()">
                        <option value="PHYSICAL">물리 서버 (독립)</option>
                        <option value="HYPERVISOR">하이퍼바이저 (VM 호스트)</option>
                        <option value="VM">VM (가상 머신)</option>
                        <option value="LDOM">LDOM (Oracle Logical Domain)</option>
                        <option value="CONTAINER">Container (Docker/LXC)</option>
                    </select>
                </div>
                <!-- 하이퍼바이저 선택 시: 가상화 종류 -->
                <div class="form-group" id="virtTypeRow" style="display:none">
                    <label>가상화 종류</label>
                    <select name="virtType" id="virtType">
                        <option value="VMWARE">VMware ESXi / vSphere</option>
                        <option value="KVM">KVM / QEMU</option>
                        <option value="HYPERV">Microsoft Hyper-V</option>
                        <option value="PROXMOX">Proxmox VE</option>
                        <option value="XEN">Xen</option>
                        <option value="ORACLE_VM">Oracle VM Server for SPARC (LDOM 호스트)</option>
                        <option value="DOCKER">Docker / LXC (컨테이너 호스트)</option>
                        <option value="OTHER">기타</option>
                    </select>
                </div>
                <!-- VM/LDOM/Zone/Container 선택 시: 부모 서버 -->
                <div class="form-group" id="parentSeqRow" style="display:none">
                    <label>호스트 서버 (부모)</label>
                    <select name="parentSeq" id="parentSeq" onchange="onParentChange()">
                        <option value="">선택 안 함</option>
                    </select>
                </div>
                <div class="form-group">
                    <label id="labelAssetName">서버명 *</label>
                    <input type="text" name="assetName" id="assetName" placeholder="예: web-server-01" required>
                </div>
                <div class="form-group">
                    <label>제조사</label>
                    <input type="text" name="maker" id="assetMaker" placeholder="예: Dell, HPE, Cisco">
                </div>
                <div class="form-group">
                    <label>모델</label>
                    <input type="text" name="model" id="assetModel" placeholder="예: PowerEdge R750">
                </div>
                <div class="form-group" id="sizeURow">
                    <label>랙 크기 (U)</label>
                    <select name="sizeU" id="assetSizeU">
                        <option value="">미적용</option>
                        <% for (int u = 1; u <= 14; u++) { %>
                        <option value="<%= u %>"><%= u %>U</option>
                        <% } %>
                    </select>
                </div>
                <div class="form-group">
                    <label>HostName</label>
                    <input type="text" name="hostname" id="assetHostname" placeholder="예: web01.example.com">
                </div>
                <div class="form-group full">
                    <label>IP 주소 (여러 개일 경우 콤마로 구분)</label>
                    <input type="text" name="ipAddr" id="assetIp" placeholder="예: 192.168.1.10, 192.168.1.11">
                </div>
                <!-- 서버 전용: CPU / Memory -->
                <div class="form-group" id="cpuRow">
                    <label>CPU</label>
                    <input type="text" name="cpu" id="assetCpu" placeholder="예: Intel Xeon Gold 6342 x2">
                </div>
                <div class="form-group" id="memoryRow">
                    <label>Memory</label>
                    <input type="text" name="memory" id="assetMemory" placeholder="예: 256GB DDR4">
                </div>
                <!-- 서버·스토리지: Disk -->
                <div class="form-group full" id="diskRow">
                    <label id="labelDisk">Disk</label>
                    <input type="text" name="disk" id="assetDisk" placeholder="예: SSD 960GB x4 RAID5">
                </div>
                <!-- 서버·네트워크·보안·스토리지: OS/펌웨어 -->
                <div class="form-group" id="osRow">
                    <label id="labelOs">OS / 펌웨어</label>
                    <input type="text" name="osInfo" id="assetOs" placeholder="예: Ubuntu 22.04 LTS">
                </div>
                <div class="form-group" id="locationRow">
                    <label>위치</label>
                    <input type="text" name="location" id="assetLocation" placeholder="예: IDC 1F 랙 A-3">
                </div>
                <div class="form-group">
                    <label>도입일</label>
                    <input type="date" name="purchaseDt" id="assetPurchase">
                </div>
                <div class="form-group">
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
        document.getElementById('assetSearch').value   = '';
        document.getElementById('assetPickList').innerHTML = '';
        filterAssets();
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
        document.getElementById('assetSearch').value   = '';
        document.getElementById('assetPickList').innerHTML = '';
        filterAssets();
        document.getElementById('rackUnitModal').classList.add('open');
    }

    function submitUnitDelete() {
        if (!confirm('이 장비를 삭제하시겠습니까?')) return;
        document.getElementById('unitDeleteForm').submit();
    }

    // ── 장비목록 선택 ────────────────────────────────────
    function filterAssets() {
        const q = document.getElementById('assetSearch').value.toLowerCase();
        const list = document.getElementById('assetPickList');
        list.innerHTML = '';
        const filtered = ASSET_DATA.filter(a =>
            a.assetName.toLowerCase().includes(q) || a.model.toLowerCase().includes(q)
        ).slice(0, 20);
        if (filtered.length === 0) {
            list.innerHTML = '<div style="font-size:12px;color:#3d4251;padding:6px 8px">일치하는 장비가 없습니다.</div>';
            return;
        }
        filtered.forEach(a => {
            const row = document.createElement('div');
            row.style.cssText = 'display:flex;align-items:center;justify-content:space-between;padding:6px 10px;background:#131519;border:1px solid #1e2025;border-radius:6px;cursor:pointer;gap:8px;';
            row.onmouseover = () => row.style.borderColor = '#3b6ef5';
            row.onmouseout  = () => row.style.borderColor = '#1e2025';
            const left = document.createElement('div');
            left.style.cssText = 'display:flex;flex-direction:column;gap:2px;min-width:0';
            left.innerHTML = '<span style="font-size:12px;font-weight:500;color:#e8e9eb;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' + a.assetName + '</span>'
                           + '<span style="font-size:11px;color:#4b5161">' + a.assetType + (a.model ? ' · ' + a.model : '') + '</span>';
            const right = document.createElement('div');
            right.style.cssText = 'display:flex;align-items:center;gap:8px;flex-shrink:0';
            if (a.sizeU) right.innerHTML += '<span style="font-size:11px;font-family:monospace;color:#6b9af5;background:#1a1e2e;padding:2px 6px;border-radius:4px">' + a.sizeU + 'U</span>';
            if (a.ipAddr) right.innerHTML += '<span style="font-size:11px;color:#4b5161;font-family:monospace">' + a.ipAddr.split(',')[0].trim() + '</span>';
            const btn = document.createElement('button');
            btn.type = 'button';
            btn.textContent = '선택';
            btn.style.cssText = 'padding:3px 10px;font-size:11px;background:#3b6ef5;color:#fff;border:none;border-radius:4px;cursor:pointer;font-family:inherit';
            btn.onclick = () => pickAsset(a);
            row.appendChild(left);
            row.appendChild(right);
            row.appendChild(btn);
            list.appendChild(row);
        });
    }

    function pickAsset(a) {
        document.getElementById('unitDeviceName').value = a.assetName;
        document.getElementById('unitDeviceType').value = a.assetType;
        if (a.sizeU) document.getElementById('unitSizeU').value = a.sizeU;
        if (a.ipAddr) document.getElementById('unitIpAddr').value = a.ipAddr;
        document.getElementById('assetSearch').value = '';
        document.getElementById('assetPickList').innerHTML = '';
    }

    // ── 장비목록 데이터 ─────────────────────────────────
    const ASSET_DATA = <%
        StringBuilder assetJson = new StringBuilder("[");
        for (int ai = 0; ai < assets.size(); ai++) {
            com.admin.servlet.CustomerDetailServlet.AssetVO a = assets.get(ai);
            if (ai > 0) assetJson.append(",");
            java.util.function.Function<String,String> jesc = s ->
                s != null ? s.replace("\\","\\\\").replace("\"","\\\"").replace("\n"," ").replace("\r","") : "";
            assetJson.append("{")
                .append("\"assetSeq\":").append(a.assetSeq)
                .append(",\"parentSeq\":").append(a.parentSeq)
                .append(",\"assetRole\":\"").append(jesc.apply(a.assetRole)).append("\"")
                .append(",\"virtType\":\"").append(jesc.apply(a.virtType)).append("\"")
                .append(",\"assetType\":\"").append(jesc.apply(a.assetType)).append("\"")
                .append(",\"assetName\":\"").append(jesc.apply(a.assetName)).append("\"")
                .append(",\"maker\":\"").append(jesc.apply(a.maker)).append("\"")
                .append(",\"model\":\"").append(jesc.apply(a.model)).append("\"")
                .append(",\"sizeU\":").append(a.sizeU != null ? a.sizeU : "null")
                .append(",\"hostname\":\"").append(jesc.apply(a.hostname)).append("\"")
                .append(",\"ipAddr\":\"").append(jesc.apply(a.ipAddr)).append("\"")
                .append(",\"disk\":\"").append(jesc.apply(a.disk)).append("\"")
                .append(",\"cpu\":\"").append(jesc.apply(a.cpu)).append("\"")
                .append(",\"memory\":\"").append(jesc.apply(a.memory)).append("\"")
                .append(",\"osInfo\":\"").append(jesc.apply(a.osInfo)).append("\"")
                .append(",\"location\":\"").append(jesc.apply(a.location)).append("\"")
                .append(",\"status\":\"").append(jesc.apply(a.status)).append("\"")
                .append(",\"purchaseDt\":\"").append(jesc.apply(a.purchaseDt)).append("\"")
                .append(",\"memo\":\"").append(jesc.apply(a.memo)).append("\"")
                .append("}");
        }
        assetJson.append("]");
        out.print(assetJson.toString());
    %>;

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

    // ── 장비목록 필터 & 정렬 ────────────────────────────────
    let assetSortCol = null, assetSortDir = 1;

    function applyAssetFilter() {
        const filterType   = document.getElementById('filterType');
        const filterStatus = document.getElementById('filterStatus');
        if (!filterType) return;
        const t = filterType.value;
        const s = filterStatus.value;
        let visible = 0;
        // 부모 행 먼저 처리
        const parentRows = [...document.querySelectorAll('#assetTbody tr.asset-parent')];
        parentRows.forEach(row => {
            if (row.classList.contains('empty-row')) return;
            const show = (!t || row.dataset.type === t) && (!s || row.dataset.status === s);
            row.style.display = show ? '' : 'none';
            if (show) visible++;
            // 부모가 숨겨지면 자식도 숨김 (부모가 보여도 collapsed면 자식은 숨김 유지)
            const pid = row.dataset.assetId;
            if (pid) {
                document.querySelectorAll('#assetTbody tr.asset-child[data-parent-id="' + pid + '"]').forEach(child => {
                    if (!show) child.style.display = 'none';
                    // show인 경우는 expand 상태에 따라 결정 → toggleChildren 로직이 관리
                });
            }
        });
        // 부모 없는 자식 행 처리 (orphan)
        document.querySelectorAll('#assetTbody tr.asset-child').forEach(row => {
            const pid = row.dataset.parentId;
            const parentRow = pid ? document.querySelector('#assetTbody tr.asset-parent[data-asset-id="' + pid + '"]') : null;
            if (!parentRow) {
                const show = (!t || row.dataset.type === t) && (!s || row.dataset.status === s);
                row.style.display = show ? '' : 'none';
                if (show) visible++;
            }
        });
        const cnt = document.getElementById('assetCount');
        if (cnt) cnt.textContent = (t || s) ? visible + '건' : '';
    }

    function resetAssetFilter() {
        document.getElementById('filterType').value   = '';
        document.getElementById('filterStatus').value = '';
        applyAssetFilter();
    }

    function sortAsset(col) {
        if (assetSortCol === col) assetSortDir *= -1;
        else { assetSortCol = col; assetSortDir = 1; }
        ['name','purchase'].forEach(c => {
            const el = document.getElementById('sort-' + c);
            if (!el) return;
            el.textContent = c === col ? (assetSortDir === 1 ? '↑' : '↓') : '↕';
            el.style.color  = c === col ? '#3b6ef5' : '#3d4251';
        });
        const tbody = document.getElementById('assetTbody');
        if (!tbody) return;
        // 부모 행만 정렬 (자식은 각 부모 뒤에 유지)
        const parentRows = [...tbody.querySelectorAll('tr.asset-parent:not(.empty-row)')];
        parentRows.sort((a, b) => {
            const va = (a.dataset[col] || '').toLowerCase();
            const vb = (b.dataset[col] || '').toLowerCase();
            return va < vb ? -assetSortDir : va > vb ? assetSortDir : 0;
        });
        parentRows.forEach(parent => {
            tbody.appendChild(parent);
            const pid = parent.dataset.assetId;
            if (pid) {
                tbody.querySelectorAll('tr.asset-child[data-parent-id="' + pid + '"]').forEach(child => {
                    tbody.appendChild(child);
                });
            }
        });
        // orphan children
        tbody.querySelectorAll('tr.asset-child').forEach(child => {
            const pid = child.dataset.parentId;
            if (!pid || !tbody.querySelector('tr.asset-parent[data-asset-id="' + pid + '"]')) {
                tbody.appendChild(child);
            }
        });
    }

    // ── 유형별 필드 표시/숨김 ─────────────────────────────
    function onTypeChange() {
        const type = document.getElementById('assetType').value;
        const isServer  = type === 'SERVER';
        const isStorage = type === 'STORAGE';
        const isNetwork = type === 'NETWORK';
        const isSecurity = type === 'SECURITY';
        const hasOs = isServer || isNetwork || isSecurity || isStorage;

        // 역할 (서버 전용)
        document.getElementById('roleRow').style.display = isServer ? '' : 'none';
        if (!isServer) {
            document.getElementById('virtTypeRow').style.display  = 'none';
            document.getElementById('parentSeqRow').style.display = 'none';
        }

        // CPU / Memory (서버 전용)
        document.getElementById('cpuRow').style.display    = isServer ? '' : 'none';
        document.getElementById('memoryRow').style.display = isServer ? '' : 'none';

        // Disk (서버·스토리지)
        document.getElementById('diskRow').style.display = (isServer || isStorage) ? '' : 'none';
        document.getElementById('labelDisk').textContent  = isStorage ? '스토리지 용량·구성' : 'Disk';

        // OS/펌웨어 (서버·네트워크·보안·스토리지)
        document.getElementById('osRow').style.display   = hasOs ? '' : 'none';
        document.getElementById('labelOs').textContent   = isServer ? 'OS / 펌웨어' : '펌웨어';

        // 장비명 레이블
        document.getElementById('labelAssetName').textContent = isServer ? '서버명 *' : '장비명 *';

        // 모달 타이틀
        const titleEl = document.getElementById('assetModalTitle');
        if (titleEl && !titleEl.dataset.editing) {
            const labels = { SERVER:'서버', NETWORK:'네트워크', SECURITY:'보안', STORAGE:'스토리지', ETC:'기타' };
            titleEl.textContent = (labels[type] || '장비') + ' 추가';
        }
    }

    // ── 가상화 역할 변경 ─────────────────────────────────
    function onRoleChange() {
        const role = document.getElementById('assetRole').value;
        const virtRow   = document.getElementById('virtTypeRow');
        const parentRow = document.getElementById('parentSeqRow');
        const parentSel = document.getElementById('parentSeq');
        const isGuest   = role === 'VM' || role === 'LDOM' || role === 'CONTAINER';

        virtRow.style.display   = (role === 'HYPERVISOR') ? '' : 'none';
        parentRow.style.display = isGuest ? '' : 'none';

        // 랙 크기: 게스트는 물리 슬롯 없음 → 숨김
        document.getElementById('sizeURow').style.display = isGuest ? 'none' : '';
        if (isGuest) document.getElementById('assetSizeU').value = '';

        // 역할 변경 시 자동 채워진 제조사·모델·위치 초기화 (새 부모 선택에 대비)
        if (isGuest) {
            document.getElementById('assetMaker').value    = '';
            document.getElementById('assetModel').value    = '';
            document.getElementById('assetLocation').value = '';
        }

        if (isGuest) {
            // 역할별 허용 virt_type 필터
            const X86_HV = ['VMWARE','KVM','HYPERV','PROXMOX','XEN'];
            const allowedVirt = role === 'LDOM'      ? ['ORACLE_VM']
                              : role === 'CONTAINER' ? ['DOCKER']
                              : X86_HV; // VM

            const curVal = parentSel.value;
            parentSel.innerHTML = '<option value="">선택 안 함</option>';
            ASSET_DATA
                .filter(a => a.assetRole === 'HYPERVISOR' && allowedVirt.includes(a.virtType))
                .forEach(a => {
                    const opt = document.createElement('option');
                    opt.value = a.assetSeq;
                    const tag = a.virtType === 'ORACLE_VM' ? 'ORACLE VM'
                              : a.virtType === 'DOCKER'    ? 'Docker'
                              : a.virtType || 'HV';
                    opt.textContent = a.assetName + ' [' + tag + ']';
                    if (String(a.assetSeq) === String(curVal)) opt.selected = true;
                    parentSel.appendChild(opt);
                });

            // 부모가 이미 선택돼 있으면 자동 채우기
            if (parentSel.value) onParentChange();
        }
    }

    // ── 부모 서버 선택 시 제조사·모델·위치 자동 채우기 ────────
    function onParentChange() {
        const parentSeq = document.getElementById('parentSeq').value;
        if (!parentSeq) return;
        const parent = ASSET_DATA.find(a => String(a.assetSeq) === String(parentSeq));
        if (!parent) return;
        const makerEl    = document.getElementById('assetMaker');
        const modelEl    = document.getElementById('assetModel');
        const locationEl = document.getElementById('assetLocation');
        // 비어있을 때만 채움 (이미 입력된 값은 덮어쓰지 않음)
        if (makerEl    && !makerEl.value)    makerEl.value    = parent.maker    || '';
        if (modelEl    && !modelEl.value)    modelEl.value    = parent.model    || '';
        if (locationEl && !locationEl.value) locationEl.value = parent.location || '';
    }

    // ── 자식 행 접기/펼치기 ───────────────────────────────
    function toggleChildren(parentSeq) {
        const btn = document.getElementById('expand-' + parentSeq);
        const children = document.querySelectorAll('#assetTbody tr.asset-child[data-parent-id="' + parentSeq + '"]');
        const isExpanded = btn && btn.textContent === '▼';
        children.forEach(row => {
            row.style.display = isExpanded ? 'none' : '';
        });
        if (btn) btn.textContent = isExpanded ? '▶' : '▼';
    }

    // ── 랙 드래그앤드롭 순서 변경 ───────────────────────────
    (function initRackDrag() {
        const list = document.getElementById('rackList');
        if (!list) return;
        let dragSrc = null, dragOver = null;

        list.querySelectorAll('.rack-card').forEach(card => {
            card.addEventListener('dragstart', e => {
                dragSrc = card;
                card.classList.add('dragging');
                e.dataTransfer.effectAllowed = 'move';
                e.dataTransfer.setData('text/plain', card.dataset.rackSeq);
            });
            card.addEventListener('dragend', () => {
                card.classList.remove('dragging');
                list.querySelectorAll('.rack-card').forEach(c => c.classList.remove('drag-over'));
                dragSrc = null; dragOver = null;
            });
            card.addEventListener('dragover', e => {
                e.preventDefault();
                if (card === dragSrc) return;
                if (card !== dragOver) {
                    list.querySelectorAll('.rack-card').forEach(c => c.classList.remove('drag-over'));
                    card.classList.add('drag-over');
                    dragOver = card;
                }
                // 드래그 위치(좌/우)에 따라 앞/뒤 삽입
                const rect = card.getBoundingClientRect();
                if (e.clientX < rect.left + rect.width / 2) {
                    list.insertBefore(dragSrc, card);
                } else {
                    list.insertBefore(dragSrc, card.nextSibling);
                }
            });
            card.addEventListener('drop', e => {
                e.preventDefault();
                card.classList.remove('drag-over');
                submitRackOrder();
            });
        });
    })();

    function submitRackOrder() {
        const cards = document.querySelectorAll('#rackList .rack-card');
        const order = [...cards].map(c => c.dataset.rackSeq).join(',');
        const input = document.getElementById('rackOrderInput');
        const form  = document.getElementById('rackOrderForm');
        if (!input || !form) return;
        input.value = order;
        form.submit();
    }

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

    function openAssetModal() {
        // 신규 추가: 모든 필드 초기화
        document.getElementById('assetModalTitle').textContent = '서버 추가';
        ['assetSeq','assetName','assetMaker','assetModel','assetHostname',
         'assetIp','assetDisk','assetCpu','assetMemory','assetOs','assetLocation','assetMemo'].forEach(id => {
            const el = document.getElementById(id); if (el) el.value = '';
        });
        document.getElementById('assetType').value    = 'SERVER';
        document.getElementById('assetSizeU').value   = '';
        document.getElementById('assetStatus').value  = 'ACTIVE';
        document.getElementById('assetPurchase').value = '';
        document.getElementById('assetRole').value    = 'PHYSICAL';
        document.getElementById('virtType').value     = 'VMWARE';
        document.getElementById('parentSeq').innerHTML = '<option value="">선택 안 함</option>';
        document.getElementById('virtTypeRow').style.display   = 'none';
        document.getElementById('parentSeqRow').style.display  = 'none';
        delete document.getElementById('assetModalTitle').dataset.editing;
        onTypeChange();
        document.getElementById('assetModal').classList.add('open');
    }

    function openAssetModalBySeq(seq) {
        const a = ASSET_DATA.find(x => x.assetSeq === seq);
        if (!a) return;
        document.getElementById('assetModalTitle').textContent = '수정';
        document.getElementById('assetModalTitle').dataset.editing = '1';
        document.getElementById('assetSeq').value       = a.assetSeq;
        document.getElementById('assetType').value      = a.assetType  || 'SERVER';
        document.getElementById('assetRole').value      = a.assetRole  || 'PHYSICAL';
        document.getElementById('virtType').value       = a.virtType   || 'VMWARE';
        document.getElementById('assetName').value      = a.assetName  || '';
        document.getElementById('assetMaker').value     = a.maker      || '';
        document.getElementById('assetModel').value     = a.model      || '';
        document.getElementById('assetSizeU').value     = a.sizeU      || '';
        document.getElementById('assetHostname').value  = a.hostname   || '';
        document.getElementById('assetIp').value        = a.ipAddr     || '';
        document.getElementById('assetDisk').value      = a.disk       || '';
        document.getElementById('assetCpu').value       = a.cpu        || '';
        document.getElementById('assetMemory').value    = a.memory     || '';
        document.getElementById('assetOs').value        = a.osInfo     || '';
        document.getElementById('assetLocation').value  = a.location   || '';
        document.getElementById('assetStatus').value    = a.status     || 'ACTIVE';
        document.getElementById('assetPurchase').value  = a.purchaseDt || '';
        document.getElementById('assetMemo').value      = a.memo       || '';
        // 유형에 따라 필드 표시 후 역할 처리
        onTypeChange();
        const labels = { SERVER:'서버', NETWORK:'네트워크', SECURITY:'보안', STORAGE:'스토리지', ETC:'기타' };
        document.getElementById('assetModalTitle').textContent = (labels[a.assetType] || '장비') + ' 수정';
        // parentSeq는 onRoleChange() 내에서 목록 채운 뒤 값 설정
        const parentSel = document.getElementById('parentSeq');
        parentSel.innerHTML = '<option value="">선택 안 함</option>';
        onRoleChange();
        if (a.parentSeq) parentSel.value = a.parentSeq;
        document.getElementById('assetModal').classList.add('open');
    }

    // ── 컬럼 가시성 관리 ─────────────────────────────────
    const COL_DEFS = [
        { key:'type',     label:'유형',     fixed:true },
        { key:'name',     label:'서버명',    fixed:true },
        { key:'maker',    label:'제조사' },
        { key:'model',    label:'모델' },
        { key:'size',     label:'크기 (U)' },
        { key:'hostname', label:'HostName' },
        { key:'ip',       label:'IP 주소' },
        { key:'disk',     label:'Disk' },
        { key:'cpu',      label:'CPU' },
        { key:'memory',   label:'Memory' },
        { key:'location', label:'위치' },
        { key:'os',       label:'OS' },
        { key:'purchase', label:'도입일' },
        { key:'status',   label:'상태',     fixed:true },
        { key:'actions',  label:'관리',     fixed:true },
    ];
    const COL_DEFAULT = { type:true, name:true, maker:true, model:true, size:false, hostname:false, ip:false, disk:false, cpu:true, memory:true, location:false, os:false, purchase:true, status:true, actions:true };
    const COL_LS_KEY  = 'assetColVis_v1';

    function loadColVisibility() {
        try { return Object.assign({}, COL_DEFAULT, JSON.parse(localStorage.getItem(COL_LS_KEY) || '{}')); }
        catch(e) { return Object.assign({}, COL_DEFAULT); }
    }

    function applyColVisibility(vis) {
        COL_DEFS.forEach(c => {
            const show = c.fixed || vis[c.key] !== false;
            document.querySelectorAll('[data-col="' + c.key + '"]').forEach(el => {
                el.style.display = show ? '' : 'none';
            });
        });
    }

    function buildColPanel(vis) {
        const box = document.getElementById('colCheckboxes');
        if (!box) return;
        box.innerHTML = '';
        COL_DEFS.forEach(c => {
            if (c.fixed) return;
            const label = document.createElement('label');
            label.style.cssText = 'display:flex;align-items:center;gap:8px;cursor:pointer;font-size:12px;color:#b0b4bf';
            const cb = document.createElement('input');
            cb.type    = 'checkbox';
            cb.checked = vis[c.key] !== false;
            cb.style.cssText = 'width:14px;height:14px;accent-color:#3b6ef5;cursor:pointer';
            cb.onchange = () => {
                vis[c.key] = cb.checked;
                localStorage.setItem(COL_LS_KEY, JSON.stringify(vis));
                applyColVisibility(vis);
            };
            label.appendChild(cb);
            label.appendChild(document.createTextNode(c.label));
            box.appendChild(label);
        });
    }

    function toggleColPanel() {
        const p = document.getElementById('colPanel');
        p.style.display = p.style.display === 'none' ? 'block' : 'none';
    }

    function resetColVisibility() {
        const stored = JSON.parse(localStorage.getItem(COL_LS_KEY) || '{}');
        const newStored = { _order: stored._order };   // 순서는 유지, 가시성만 초기화
        localStorage.setItem(COL_LS_KEY, JSON.stringify(newStored));
        const vis = Object.assign({}, COL_DEFAULT);
        buildColPanel(vis);
        applyColVisibility(vis);
    }

    // ── 컬럼 드래그앤드롭 순서 변경 ─────────────────────────
    let _dragColIdx = null;

    function moveTableColumn(fromIdx, toIdx) {
        const table = document.getElementById('assetTable');
        if (!table) return;
        Array.from(table.rows).forEach(row => {
            const cells = Array.from(row.cells);
            if (fromIdx >= cells.length || toIdx >= cells.length) return;
            const cell = cells[fromIdx];
            if (fromIdx < toIdx) {
                const ref = cells[toIdx];
                row.insertBefore(cell, ref.nextSibling || null);
            } else {
                row.insertBefore(cell, cells[toIdx]);
            }
        });
    }

    function saveColOrder() {
        const table = document.getElementById('assetTable');
        if (!table) return;
        const order = Array.from(table.querySelectorAll('thead th')).map(th => th.getAttribute('data-col'));
        const stored = JSON.parse(localStorage.getItem(COL_LS_KEY) || '{}');
        stored._order = order;
        localStorage.setItem(COL_LS_KEY, JSON.stringify(stored));
    }

    function restoreColOrder() {
        const stored = JSON.parse(localStorage.getItem(COL_LS_KEY) || '{}');
        if (!stored._order) return;
        stored._order.forEach((colKey, toIdx) => {
            const table = document.getElementById('assetTable');
            if (!table) return;
            const ths = Array.from(table.querySelectorAll('thead th'));
            const fromIdx = ths.findIndex(th => th.getAttribute('data-col') === colKey);
            if (fromIdx === -1 || fromIdx === toIdx) return;
            moveTableColumn(fromIdx, toIdx);
        });
    }

    let _colWasDragged = false;   // 드래그 후 click 무시용

    function initColDrag() {
        const table = document.getElementById('assetTable');
        if (!table) return;
        table.querySelectorAll('thead th').forEach(th => {
            if (th.getAttribute('data-col') === 'actions') return;
            th.draggable = true;   // ← 핵심: draggable 속성 설정

            th.addEventListener('dragstart', e => {
                _dragColIdx   = Array.from(table.querySelectorAll('thead th')).indexOf(th);
                _colWasDragged = false;
                e.dataTransfer.effectAllowed = 'move';
                e.dataTransfer.setData('text/plain', _dragColIdx);
                setTimeout(() => th.classList.add('col-dragging'), 0);
            });
            th.addEventListener('dragend', () => {
                th.classList.remove('col-dragging');
                table.querySelectorAll('thead th').forEach(t => t.classList.remove('col-drag-over'));
                setTimeout(() => { _colWasDragged = false; }, 100);
                _dragColIdx = null;
            });
            // 드롭 대상에도 dragover/drop 필요
            th.addEventListener('dragover', e => {
                e.preventDefault();
                e.dataTransfer.dropEffect = 'move';
                const curIdx = Array.from(table.querySelectorAll('thead th')).indexOf(th);
                if (_dragColIdx === null || _dragColIdx === curIdx) return;
                table.querySelectorAll('thead th').forEach(t => t.classList.remove('col-drag-over'));
                th.classList.add('col-drag-over');
            });
            th.addEventListener('drop', e => {
                e.preventDefault();
                th.classList.remove('col-drag-over');
                if (_dragColIdx === null) return;
                const toIdx = Array.from(table.querySelectorAll('thead th')).indexOf(th);
                if (_dragColIdx !== toIdx) {
                    moveTableColumn(_dragColIdx, toIdx);
                    saveColOrder();
                    _colWasDragged = true;
                }
                _dragColIdx = null;
            });
            // 드래그 직후 click(정렬) 무시
            th.addEventListener('click', e => {
                if (_colWasDragged) { e.stopImmediatePropagation(); _colWasDragged = false; }
            }, true);
        });
    }

    // 초기화
    (function() {
        const vis = loadColVisibility();
        restoreColOrder();          // 저장된 순서 먼저 복원
        buildColPanel(vis);
        applyColVisibility(vis);
        initColDrag();              // 드래그 이벤트 등록
        // 패널 외부 클릭 시 닫기
        document.addEventListener('click', e => {
            const btn   = document.getElementById('colToggleBtn');
            const panel = document.getElementById('colPanel');
            if (panel && btn && !panel.contains(e.target) && !btn.contains(e.target)) {
                panel.style.display = 'none';
            }
        });
    })();

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

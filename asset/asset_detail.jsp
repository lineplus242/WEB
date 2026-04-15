<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.admin.servlet.AssetDetailServlet.*" %>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("../login.jsp"); return; }
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");

    AssetDetailVO asset = (AssetDetailVO) request.getAttribute("asset");
    PhotoVO frontPhoto  = (PhotoVO)       request.getAttribute("frontPhoto");
    PhotoVO rearPhoto   = (PhotoVO)       request.getAttribute("rearPhoto");
    List<PortMapVO>    portMap       = (List<PortMapVO>)    request.getAttribute("portMap");
    List<SimpleAssetVO> siblingAssets = (List<SimpleAssetVO>) request.getAttribute("siblingAssets");
    if (portMap      == null) portMap      = new java.util.ArrayList<>();
    if (siblingAssets == null) siblingAssets = new java.util.ArrayList<>();

    String activeTab  = "port".equals(request.getParameter("tab")) ? "port" : "info";
    String photoTab   = "B".equals(request.getParameter("photoTab")) ? "B" : "F";
    String dbError    = (String) request.getAttribute("dbError");
    String ctxPath    = request.getContextPath();
%>
<%!
    String nvl(String s)  { return s != null ? s : ""; }
    String dash(String s) { return (s == null || s.isEmpty()) ? "-" : s; }

    String statusLabel(String s) {
        if ("ACTIVE".equals(s))   return "운영중";
        if ("INACTIVE".equals(s)) return "중지";
        if ("PENDING".equals(s))  return "대기";
        return s != null ? s : "-";
    }
    String statusChip(String s) {
        if ("ACTIVE".equals(s))   return "chip-g";
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
    String roleLabel(String r, String v) {
        if ("HYPERVISOR".equals(r)) {
            if ("VMWARE".equals(v))    return "VMware HV";
            if ("KVM".equals(v))       return "KVM HV";
            if ("HYPERV".equals(v))    return "Hyper-V HV";
            if ("PROXMOX".equals(v))   return "Proxmox HV";
            if ("ORACLE_VM".equals(v)) return "Oracle VM HV";
            return "Hypervisor";
        }
        if ("VM".equals(r))        return "VM";
        if ("LDOM".equals(r))      return "LDOM";
        if ("ZONE".equals(r))      return "Zone";
        if ("CONTAINER".equals(r)) return "Container";
        return "Physical";
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= asset != null ? nvl(asset.assetName) : "장비 상세" %> - 관리 시스템</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
    <script>(function(){if(localStorage.getItem('theme')==='light')document.documentElement.setAttribute('data-theme','light');})()</script>
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

        /* 메인 */
        .main { margin-left: 220px; flex: 1; display: flex; flex-direction: column; min-height: 100vh; }
        .topbar { height: 52px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; justify-content: space-between; padding: 0 28px; background: #0e0f11; position: sticky; top: 0; z-index: 50; }
        .topbar-left { display: flex; align-items: center; gap: 10px; }
        .topbar-title { font-size: 14px; font-weight: 500; color: #f2f3f5; }
        .topbar-sub { font-size: 12px; color: #4b5161; }
        .back-btn { display: flex; align-items: center; gap: 6px; font-size: 12px; color: #6b7280; text-decoration: none; padding: 5px 10px; border-radius: 6px; transition: background 0.12s; }
        .back-btn:hover { background: #161820; color: #c8cad0; }
        .content { padding: 28px; }

        /* 버튼 */
        .btn { padding: 8px 16px; border-radius: 8px; font-size: 13px; font-family: 'DM Sans', sans-serif; cursor: pointer; border: none; transition: background 0.15s; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; }
        .btn-primary { background: #3b6ef5; color: #fff; }
        .btn-primary:hover { background: #2f5ee0; }
        .btn-secondary { background: #1a1e2e; color: #6b9af5; border: 1px solid #252d44; }
        .btn-secondary:hover { background: #202540; }
        .btn-sm { padding: 5px 12px; font-size: 12px; border-radius: 6px; }
        .btn-danger { background: #2a0d0d; color: #e05656; border: 1px solid #3d0f0f; }
        .btn-danger:hover { background: #3d1212; }
        .btn-ghost { background: none; color: #6b7280; border: 1px solid #1e2025; }
        .btn-ghost:hover { background: #161820; color: #c8cad0; }

        /* 칩 */
        .chip { font-size: 10px; padding: 3px 9px; border-radius: 4px; font-family: 'DM Mono', monospace; font-weight: 500; white-space: nowrap; }
        .chip-g      { background: #0d2a1a; color: #22c97a; border: 1px solid #0f3d25; }
        .chip-r      { background: #2a0d0d; color: #e05656; border: 1px solid #3d0f0f; }
        .chip-y      { background: #2a200d; color: #d4a017; border: 1px solid #3d2e0f; }
        .chip-blue   { background: #0d1a2e; color: #5a9af5; border: 1px solid #0f2544; }
        .chip-purple { background: #1a0d2e; color: #9b6af5; border: 1px solid #280f44; }
        .chip-teal   { background: #0d2229; color: #3dd6c8; border: 1px solid #0f3540; }

        /* 카드 */
        .card { background: #131519; border: 1px solid #1e2025; border-radius: 12px; margin-bottom: 20px; }
        .card-header { padding: 16px 20px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; justify-content: space-between; gap: 12px; }
        .card-title { font-size: 13px; font-weight: 500; color: #9ca3af; }
        .card-body { padding: 20px; }

        /* 사진 섹션 탭 */
        .photo-tab-bar { display: flex; gap: 2px; background: #0e0f11; border: 1px solid #1e2025; border-radius: 8px; padding: 3px; width: fit-content; }
        .photo-tab-btn { padding: 6px 20px; font-size: 12px; font-weight: 500; color: #6b7280; cursor: pointer; border: none; background: none; border-radius: 6px; transition: background 0.12s, color 0.12s; font-family: 'DM Sans', sans-serif; }
        .photo-tab-btn:hover { color: #c8cad0; }
        .photo-tab-btn.active { background: #1a1e2e; color: #6b9af5; }

        /* 사진 표시 영역 */
        .photo-area { min-height: 280px; display: flex; align-items: center; justify-content: center; background: #0e0f11; border: 1px solid #1e2025; border-radius: 10px; margin: 16px 0; overflow: hidden; position: relative; }
        .photo-area img { max-width: 100%; max-height: 360px; object-fit: contain; cursor: zoom-in; border-radius: 6px; }
        .photo-placeholder { display: flex; flex-direction: column; align-items: center; gap: 10px; color: #3d4251; }
        .photo-placeholder svg { opacity: 0.4; }
        .photo-placeholder p { font-size: 13px; }
        .photo-actions { display: flex; align-items: center; gap: 8px; }

        /* 정보 카드 그리드 */
        .info-cards-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 14px; margin-bottom: 14px; }
        .info-card { background: #0e0f11; border: 1px solid #1e2025; border-radius: 10px; padding: 16px 18px; }
        .ic-section-label { font-size: 10px; font-weight: 500; color: #3d4251; letter-spacing: 0.08em; text-transform: uppercase; margin-bottom: 14px; padding-bottom: 8px; border-bottom: 1px solid #1e2025; }
        .ic-fields { display: flex; flex-direction: column; gap: 12px; }
        .ic-field { display: flex; flex-direction: column; gap: 3px; }
        .ic-label { font-size: 10px; color: #4b5161; letter-spacing: 0.04em; text-transform: uppercase; }
        .ic-value { font-size: 13px; color: #c8cad0; }
        .ic-value.strong { color: #f2f3f5; font-weight: 500; font-size: 14px; }
        .ic-value.mono { font-family: 'DM Mono', monospace; font-size: 12px; }

        /* 하단 탭 */
        .tab-bar { display: flex; gap: 4px; border-bottom: 1px solid #1e2025; padding-bottom: 0; margin-bottom: 20px; }
        .tab-btn { padding: 10px 20px; font-size: 13px; color: #6b7280; cursor: pointer; border: none; background: none; border-bottom: 2px solid transparent; margin-bottom: -1px; transition: color 0.12s, border-color 0.12s; font-family: 'DM Sans', sans-serif; }
        .tab-btn:hover { color: #c8cad0; }
        .tab-btn.active { color: #6b9af5; border-bottom-color: #3b6ef5; }
        .tab-panel { display: none; }
        .tab-panel.active { display: block; }

        /* 포트맵 테이블 */
        .table-wrap { background: #131519; border: 1px solid #1e2025; border-radius: 12px; overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; }
        th { background: #0f1013; padding: 10px 14px; font-size: 11px; font-weight: 500; color: #6b7280; text-align: left; letter-spacing: 0.05em; text-transform: uppercase; border-bottom: 1px solid #1e2025; white-space: nowrap; }
        td { padding: 11px 14px; font-size: 13px; color: #c8cad0; border-bottom: 1px solid #161820; vertical-align: middle; }
        tr:last-child td { border-bottom: none; }
        tr:hover td { background: #161820; }
        .td-mono { font-family: 'DM Mono', monospace; font-size: 12px; }
        .td-actions { display: flex; gap: 6px; }
        .empty-row td { text-align: center; padding: 48px; color: #3d4251; }
        .panel-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }

        /* 계정 정보 */
        .account-row { display: flex; align-items: center; gap: 10px; padding: 7px 0; border-bottom: 1px solid #161820; }
        .account-row:last-child { border-bottom: none; }
        .account-id { font-family: 'DM Mono', monospace; font-size: 12px; color: #6b9af5; min-width: 100px; }
        .account-pw { font-family: 'DM Mono', monospace; font-size: 12px; color: #4b5161; flex: 1; }
        .pw-toggle { font-size: 11px; color: #4b5161; cursor: pointer; padding: 2px 8px; border: 1px solid #252830; border-radius: 4px; background: none; font-family: 'DM Sans', sans-serif; transition: color .12s; }
        .pw-toggle:hover { color: #6b9af5; border-color: #3b6ef5; }

        /* 모달 */
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.7); z-index: 200; align-items: center; justify-content: center; }
        .modal-overlay.open { display: flex; }
        .modal { background: #131519; border: 1px solid #1e2025; border-radius: 14px; padding: 28px; width: 540px; max-width: 95vw; max-height: 90vh; overflow-y: auto; }
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
        .modal-footer { display: flex; justify-content: flex-end; gap: 8px; margin-top: 20px; }

        /* 이미지 확대 모달 */
        #imgModal { cursor: zoom-out; }
        #imgModal img { max-width: 90vw; max-height: 85vh; border-radius: 8px; object-fit: contain; }

        /* 도착지 장비 커스텀 드롭다운 */
        .sibling-wrap { position: relative; }
        .sibling-dropdown { display: none; position: absolute; top: calc(100% + 4px); left: 0; right: 0; background: #131519; border: 1px solid #1e2025; border-radius: 8px; max-height: 200px; overflow-y: auto; z-index: 400; box-shadow: 0 8px 24px rgba(0,0,0,0.4); }
        .sibling-option { padding: 8px 12px; font-size: 13px; color: #c8cad0; cursor: pointer; transition: background 0.1s; }
        .sibling-option:hover, .sibling-option.active { background: #1a1e2e; color: #6b9af5; }
        .sibling-option.empty { color: #4b5161; cursor: default; }
        .sibling-option.empty:hover { background: none; color: #4b5161; }
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
            <% if (asset != null) { %>
            <a href="../CustomerDetailServlet?action=detail&custSeq=<%= asset.custSeq %>&tab=asset" class="back-btn">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" width="14" height="14"><polyline points="15 18 9 12 15 6"/></svg>
                <%= nvl(asset.custName) %>
            </a>
            <span style="color:#1e2025">|</span>
            <span class="topbar-title"><%= nvl(asset.assetName) %></span>
            <% } %>
        </div>
    </div>

    <div class="content">
        <% if (dbError != null) { %>
        <div style="background:#2a0d0d;border:1px solid #3d0f0f;border-radius:8px;padding:12px 16px;color:#e05656;margin-bottom:16px;font-size:13px;">⚠ DB 오류: <%= dbError %></div>
        <% } %>

        <% if (asset != null) { %>

        <!-- ── 사진 카드 ────────────────────────────────────────── -->
        <div class="card">
            <div class="card-header">
                <div class="photo-tab-bar">
                    <button class="photo-tab-btn <%= "F".equals(photoTab) ? "active" : "" %>" onclick="switchPhotoTab('F', this)">전면부</button>
                    <button class="photo-tab-btn <%= "B".equals(photoTab) ? "active" : "" %>" onclick="switchPhotoTab('B', this)">후면부</button>
                </div>
                <div class="photo-actions" id="photoActions">
                    <!-- JS로 렌더링 -->
                </div>
            </div>
            <div class="card-body" style="padding:16px 20px">

                <!-- 전면부 -->
                <div id="photoPane-F" style="display:<%= "F".equals(photoTab) ? "block" : "none" %>">
                    <div class="photo-area" id="photoArea-F">
                        <% if (frontPhoto != null) { %>
                        <img src="<%= ctxPath %>/<%= frontPhoto.filePath %>" alt="전면부" onclick="openImgModal(this.src)">
                        <% } else { %>
                        <div class="photo-placeholder">
                            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#3d4251" stroke-width="1.2">
                                <rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/>
                                <polyline points="21 15 16 10 5 21"/>
                            </svg>
                            <p>등록된 사진이 없습니다</p>
                        </div>
                        <% } %>
                    </div>
                </div>

                <!-- 후면부 -->
                <div id="photoPane-B" style="display:<%= "B".equals(photoTab) ? "block" : "none" %>">
                    <div class="photo-area" id="photoArea-B">
                        <% if (rearPhoto != null) { %>
                        <img src="<%= ctxPath %>/<%= rearPhoto.filePath %>" alt="후면부" onclick="openImgModal(this.src)">
                        <% } else { %>
                        <div class="photo-placeholder">
                            <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#3d4251" stroke-width="1.2">
                                <rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/>
                                <polyline points="21 15 16 10 5 21"/>
                            </svg>
                            <p>등록된 사진이 없습니다</p>
                        </div>
                        <% } %>
                    </div>
                </div>

                <!-- 업로드/삭제 폼 (JS로 제어) -->
                <form id="uploadForm" action="../AssetDetailServlet" method="post" enctype="multipart/form-data" style="display:none">
                    <input type="hidden" name="action" value="photoUpload">
                    <input type="hidden" name="assetSeq" value="<%= asset.assetSeq %>">
                    <input type="hidden" name="side" id="uploadSide" value="F">
                    <input type="file" name="photoFile" id="photoFileInput" accept="image/*" style="display:none"
                           onchange="if(this.files && this.files[0]) this.form.submit()">
                </form>
                <form id="deleteForm" action="../AssetDetailServlet" method="post" style="display:none">
                    <input type="hidden" name="action" value="photoDelete">
                    <input type="hidden" name="assetSeq" value="<%= asset.assetSeq %>">
                    <input type="hidden" name="side" id="deleteSide" value="F">
                </form>
            </div>
        </div>

        <!-- ── 하단 탭 ──────────────────────────────────────────── -->
        <div class="tab-bar">
            <button class="tab-btn <%= "info".equals(activeTab) ? "active" : "" %>" onclick="switchTab('info', this)">정보</button>
            <button class="tab-btn <%= "port".equals(activeTab) ? "active" : "" %>" onclick="switchTab('port', this)">포트맵</button>
        </div>

        <!-- ── 정보 탭 ─────────────────────────────────────────── -->
        <div id="tab-info" class="tab-panel <%= "info".equals(activeTab) ? "active" : "" %>">
            <div class="card">
                <div class="card-body">

                    <!-- 3-column: 기본정보 / 사양 / 네트워크 -->
                    <div class="info-cards-grid">

                        <!-- 기본 정보 -->
                        <div class="info-card">
                            <div class="ic-section-label">기본 정보</div>
                            <div class="ic-fields">
                                <div class="ic-field">
                                    <span class="ic-label">자산명</span>
                                    <span class="ic-value strong"><%= nvl(asset.assetName) %></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">자산 유형</span>
                                    <span class="ic-value"><span class="chip <%= assetTypeChip(asset.assetType) %>"><%= assetTypeLabel(asset.assetType) %></span></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">역할</span>
                                    <span class="ic-value"><%= roleLabel(asset.assetRole, asset.virtType) %></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">제조사</span>
                                    <span class="ic-value"><%= dash(asset.maker) %></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">모델명</span>
                                    <span class="ic-value mono"><%= dash(asset.model) %></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">랙 크기</span>
                                    <span class="ic-value"><%= asset.sizeU != null ? asset.sizeU + "U" : "-" %></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">위치</span>
                                    <span class="ic-value"><%= dash(asset.location) %></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">상태</span>
                                    <span class="ic-value"><span class="chip <%= statusChip(asset.status) %>"><%= statusLabel(asset.status) %></span></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">도입일</span>
                                    <span class="ic-value mono"><%= dash(asset.purchaseDt) %></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">만료일</span>
                                    <span class="ic-value mono"><%= dash(asset.expireDt) %></span>
                                </div>
                            </div>
                        </div>

                        <!-- 사양 -->
                        <div class="info-card">
                            <div class="ic-section-label">사양</div>
                            <div class="ic-fields">
                                <div class="ic-field">
                                    <span class="ic-label">CPU</span>
                                    <span class="ic-value"><%= dash(asset.cpu) %></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">메모리</span>
                                    <span class="ic-value"><%= dash(asset.memory) %></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">Disk</span>
                                    <span class="ic-value"><%= dash(asset.disk) %></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">OS / 펌웨어</span>
                                    <span class="ic-value"><%= dash(asset.osInfo) %></span>
                                </div>
                            </div>
                        </div>

                        <!-- 네트워크 -->
                        <div class="info-card">
                            <div class="ic-section-label">네트워크</div>
                            <div class="ic-fields">
                                <div class="ic-field">
                                    <span class="ic-label">호스트명</span>
                                    <span class="ic-value mono"><%= dash(asset.hostname) %></span>
                                </div>
                                <div class="ic-field">
                                    <span class="ic-label">IP 주소</span>
                                    <span class="ic-value" id="ipDisplay">
                                        <% if (asset.ipAddr != null && !asset.ipAddr.isEmpty()) { %>
                                        <script>
                                        (function(){
                                            var raw = '<%= asset.ipAddr.replace("\\","\\\\").replace("'","\\'").replace("\r","").replace("\n","") %>';
                                            var items; try { items = JSON.parse(raw); } catch(e){ items = null; }
                                            var el = document.getElementById('ipDisplay');
                                            if (!el) return;
                                            if (items && Array.isArray(items)) {
                                                el.innerHTML = items.map(function(it){
                                                    return '<span style="display:inline-flex;align-items:center;gap:6px;margin-bottom:4px;flex-wrap:wrap">'
                                                        + '<span style="font-size:10px;padding:1px 6px;border-radius:3px;background:#1a1c22;color:#6b9af5;border:1px solid #252830">' + it.type + '</span>'
                                                        + '<span style="font-family:\'DM Mono\',monospace;font-size:12px">' + it.addr + '</span></span>';
                                                }).join('');
                                            } else {
                                                el.innerHTML = '<span style="font-family:\'DM Mono\',monospace;font-size:12px">' + raw.replace(/,/g, '<br>') + '</span>';
                                            }
                                        })();
                                        </script>
                                        <% } else { %>-<% } %>
                                    </span>
                                </div>
                            </div>
                        </div>

                    </div>

                    <!-- 계정 정보 (전체 너비) -->
                    <div class="info-card" style="margin-bottom:14px">
                        <div class="ic-section-label">계정 정보</div>
                        <div id="accountDisplay">
                            <% if (asset.accountInfo != null && !asset.accountInfo.isEmpty()) { %>
                            <script>
                            (function(){
                                var raw = '<%= asset.accountInfo.replace("\\","\\\\").replace("'","\\'").replace("\r","").replace("\n","") %>';
                                var items; try { items = JSON.parse(raw); } catch(e){ items = null; }
                                var el = document.getElementById('accountDisplay');
                                if (!items || !items.length) { el.innerHTML = '<span style="color:#3d4251">-</span>'; return; }
                                var html = '';
                                items.forEach(function(acc, i) {
                                    html += '<div class="account-row">'
                                        + '<span class="account-id">' + (acc.username || '') + '</span>'
                                        + '<span class="account-pw" id="pw-' + i + '" data-pw="' + (acc.password || '').replace(/"/g,'&quot;') + '">••••••••</span>'
                                        + '<button class="pw-toggle" onclick="togglePw(' + i + ', this)">표시</button>'
                                        + '</div>';
                                });
                                el.innerHTML = html;
                            })();
                            </script>
                            <% } else { %>
                            <span style="color:#3d4251">-</span>
                            <% } %>
                        </div>
                    </div>

                    <!-- 메모 (전체 너비, 조건부) -->
                    <% if (asset.memo != null && !asset.memo.isEmpty()) { %>
                    <div class="info-card">
                        <div class="ic-section-label">메모</div>
                        <div style="font-size:13px;color:#9ca3af;line-height:1.6;white-space:pre-wrap"><%= asset.memo %></div>
                    </div>
                    <% } %>

                </div>
            </div>
        </div>

        <!-- ── 포트맵 탭 ──────────────────────────────────────── -->
        <div id="tab-port" class="tab-panel <%= "port".equals(activeTab) ? "active" : "" %>">
            <div class="panel-header">
                <span style="font-size:13px;font-weight:500;color:#9ca3af">포트맵</span>
                <button class="btn btn-primary btn-sm" onclick="openPortModal()">+ 포트 추가</button>
            </div>
            <div class="table-wrap">
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>출발지 포트</th>
                            <th>도착지 장비</th>
                            <th>도착지 포트</th>
                            <th>케이블 종류</th>
                            <th>케이블 색상</th>
                            <th>비고</th>
                            <th style="text-align:center">관리</th>
                        </tr>
                    </thead>
                    <tbody>
                        <% if (portMap.isEmpty()) { %>
                        <tr class="empty-row"><td colspan="8">등록된 포트맵이 없습니다.</td></tr>
                        <% } else { int pIdx = 1; for (PortMapVO pm : portMap) {
                            String dstDevice = pm.dstAssetName != null ? pm.dstAssetName : (pm.dstDeviceName != null ? pm.dstDeviceName : "-");
                        %>
                        <tr>
                            <td class="td-mono" style="color:#4b5161"><%= pIdx++ %></td>
                            <td class="td-mono" style="color:#6b9af5"><%= nvl(pm.srcPort) %></td>
                            <td><%= dstDevice %></td>
                            <td class="td-mono"><%= pm.dstPort != null ? pm.dstPort : "-" %></td>
                            <td><% if (pm.cableType != null) { %><span style="font-size:11px;padding:2px 7px;border-radius:4px;background:#1a1c22;color:#9ca3af;border:1px solid #252830"><%= pm.cableType %></span><% } else { %>-<% } %></td>
                            <td>
                                <% if (pm.cableColor != null && !pm.cableColor.isEmpty()) { %>
                                <span style="display:inline-flex;align-items:center;gap:6px">
                                    <span id="colorDot-<%= pm.portSeq %>" style="width:10px;height:10px;border-radius:50%;border:1px solid #252830;display:inline-block"></span>
                                    <script>document.getElementById('colorDot-<%= pm.portSeq %>').style.background='<%= pm.cableColor.replace("'","") %>';</script>
                                    <span style="font-size:12px"><%= pm.cableColor %></span>
                                </span>
                                <% } else { %>-<% } %>
                            </td>
                            <td style="color:#6b7280"><%= pm.memo != null ? pm.memo : "" %></td>
                            <td>
                                <div class="td-actions" style="justify-content:center">
                                    <button class="btn btn-sm btn-secondary"
                                        onclick="openPortModal(<%= pm.portSeq %>, '<%= nvl(pm.srcPort).replace("'","\\'") %>', '<%= (pm.dstAssetSeq != null ? pm.dstAssetSeq : "") %>', '<%= (pm.dstDeviceName != null ? pm.dstDeviceName.replace("'","\\'") : "") %>', '<%= (pm.dstPort != null ? pm.dstPort.replace("'","\\'") : "") %>', '<%= (pm.cableType != null ? pm.cableType.replace("'","\\'") : "") %>', '<%= (pm.cableColor != null ? pm.cableColor.replace("'","\\'") : "") %>', '<%= (pm.memo != null ? pm.memo.replace("'","\\'") : "") %>')">수정</button>
                                    <form action="../AssetDetailServlet" method="post" style="display:inline" onsubmit="return confirm('삭제하시겠습니까?')">
                                        <input type="hidden" name="action" value="portDelete">
                                        <input type="hidden" name="assetSeq" value="<%= asset.assetSeq %>">
                                        <input type="hidden" name="portSeq" value="<%= pm.portSeq %>">
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

        <% } /* asset != null */ %>
    </div>
</div>

<!-- ── 포트맵 모달 ────────────────────────────────────────── -->
<div class="modal-overlay" id="portModal">
    <div class="modal">
        <div class="modal-title" id="portModalTitle">포트 추가</div>
        <form action="../AssetDetailServlet" method="post">
            <input type="hidden" name="action" value="portSave">
            <input type="hidden" name="assetSeq" value="<%= asset != null ? asset.assetSeq : 0 %>">
            <input type="hidden" name="portSeq" id="portSeq" value="">
            <input type="hidden" name="dstAssetSeq" id="dstAssetSeqHidden" value="">
            <div class="form-grid">
                <div class="form-group full">
                    <label>출발지 포트 *</label>
                    <input type="text" name="srcPort" id="srcPort" placeholder="예: eth0, Gi0/1, FC-HBA0" required>
                </div>
                <div class="form-group full">
                    <label>도착지 장비</label>
                    <div class="sibling-wrap">
                        <input type="text" name="dstDeviceName" id="dstDeviceName"
                               placeholder="장비명 직접 입력 또는 목록에서 선택"
                               autocomplete="off"
                               oninput="filterSiblings(this.value)"
                               onfocus="filterSiblings(this.value)">
                        <div id="siblingDropdown" class="sibling-dropdown"></div>
                    </div>
                </div>
                <div class="form-group">
                    <label>도착지 포트</label>
                    <input type="text" name="dstPort" id="dstPort" placeholder="예: Gi0/1, Port 2">
                </div>
                <div class="form-group">
                    <label>케이블 종류</label>
                    <select name="cableType" id="cableType">
                        <option value="">선택 안 함</option>
                        <option value="CAT5e">CAT5e</option>
                        <option value="CAT6">CAT6</option>
                        <option value="CAT6A">CAT6A</option>
                        <option value="CAT7">CAT7</option>
                        <option value="SFP">SFP</option>
                        <option value="SFP+">SFP+</option>
                        <option value="SFP28">SFP28 (25G)</option>
                        <option value="QSFP">QSFP (40G)</option>
                        <option value="FC 4G">FC 4G</option>
                        <option value="FC 8G">FC 8G</option>
                        <option value="FC 16G">FC 16G</option>
                        <option value="FC 32G">FC 32G</option>
                        <option value="기타">기타</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>케이블 색상</label>
                    <input type="text" name="cableColor" id="cableColor" placeholder="예: 파랑, 빨강, #3b6ef5">
                </div>
                <div class="form-group">
                    <label>비고</label>
                    <input type="text" name="memo" id="portMemo" placeholder="예: 이중화 포트">
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-ghost btn-sm" onclick="closeModal('portModal')">취소</button>
                <button type="submit" class="btn btn-primary btn-sm">저장</button>
            </div>
        </form>
    </div>
</div>

<!-- ── 이미지 확대 모달 ──────────────────────────────────── -->
<div class="modal-overlay" id="imgModal" onclick="closeModal('imgModal')">
    <img id="imgModalImg" src="" alt="">
</div>

<script>
    // ── 사진 탭 ──────────────────────────────────────────
    const PHOTO_STATE = {
        F: <%= frontPhoto != null ? "true" : "false" %>,
        B: <%= rearPhoto  != null ? "true" : "false" %>
    };
    let currentPhotoTab = '<%= photoTab %>';

    function switchPhotoTab(side, btn) {
        document.querySelectorAll('.photo-tab-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById('photoPane-F').style.display = side === 'F' ? 'block' : 'none';
        document.getElementById('photoPane-B').style.display = side === 'B' ? 'block' : 'none';
        currentPhotoTab = side;
        renderPhotoActions();
    }

    function renderPhotoActions() {
        const hasPhoto = PHOTO_STATE[currentPhotoTab];
        const actEl = document.getElementById('photoActions');
        let html = '<button class="btn btn-secondary btn-sm" onclick="openPhotoPicker(\'' + currentPhotoTab + '\')">'
                 + (hasPhoto ? '사진 교체' : '+ 사진 업로드')
                 + '</button>';
        if (hasPhoto) {
            html += '<button class="btn btn-danger btn-sm" onclick="submitDelete(\'' + currentPhotoTab + '\')">삭제</button>';
        }
        actEl.innerHTML = html;
    }

    function openPhotoPicker(side) {
        document.getElementById('uploadSide').value = side;
        document.getElementById('photoFileInput').value = '';  // 같은 파일 재선택 가능
        document.getElementById('photoFileInput').click();
    }

    function submitDelete(side) {
        if (!confirm('사진을 삭제하시겠습니까?')) return;
        document.getElementById('deleteSide').value = side;
        document.getElementById('deleteForm').submit();
    }

    // ── 하단 탭 ─────────────────────────────────────────
    function switchTab(name, btn) {
        document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
        document.querySelectorAll('.tab-panel').forEach(p => p.classList.remove('active'));
        btn.classList.add('active');
        document.getElementById('tab-' + name).classList.add('active');
    }

    // ── 포트맵 모달 ──────────────────────────────────────
    const SIBLING_LIST = [
        <% for (int si = 0; si < siblingAssets.size(); si++) {
            SimpleAssetVO sa = siblingAssets.get(si); %>
        { seq: <%= sa.assetSeq %>, name: '<%= sa.assetName.replace("'", "\\'") %>' }<%= si < siblingAssets.size()-1 ? "," : "" %>
        <% } %>
    ];

    function filterSiblings(val) {
        const dd = document.getElementById('siblingDropdown');
        const q = val.trim().toLowerCase();
        const matches = q === '' ? SIBLING_LIST : SIBLING_LIST.filter(s => s.name.toLowerCase().includes(q));
        if (matches.length === 0) {
            dd.innerHTML = '<div class="sibling-option empty">일치하는 장비 없음</div>';
        } else {
            dd.innerHTML = matches.map(s =>
                '<div class="sibling-option" onmousedown="selectSibling(\'' + s.name.replace(/'/g, "\\'") + '\',' + s.seq + ')">' + s.name + '</div>'
            ).join('');
        }
        dd.style.display = 'block';
    }

    function selectSibling(name, seq) {
        document.getElementById('dstDeviceName').value = name;
        document.getElementById('dstAssetSeqHidden').value = seq;
        document.getElementById('siblingDropdown').style.display = 'none';
    }

    function closeSiblingDropdown() {
        document.getElementById('siblingDropdown').style.display = 'none';
    }

    document.addEventListener('click', function(e) {
        const wrap = document.querySelector('.sibling-wrap');
        if (wrap && !wrap.contains(e.target)) closeSiblingDropdown();
    });

    // input에서 직접 입력 시 seq 초기화 (목록 선택 아닌 경우)
    document.getElementById('dstDeviceName').addEventListener('input', function() {
        const matched = SIBLING_LIST.find(s => s.name === this.value);
        document.getElementById('dstAssetSeqHidden').value = matched ? matched.seq : '';
    });

    function openPortModal(portSeq, srcPort, dstSeq, dstDevice, dstPort, cableType, cableColor, memo) {
        document.getElementById('portModalTitle').textContent = portSeq ? '포트 수정' : '포트 추가';
        document.getElementById('portSeq').value           = portSeq    || '';
        document.getElementById('srcPort').value           = srcPort    || '';
        document.getElementById('dstAssetSeqHidden').value = dstSeq    || '';
        document.getElementById('dstDeviceName').value     = dstDevice  || '';
        document.getElementById('dstPort').value           = dstPort    || '';
        document.getElementById('cableType').value         = cableType  || '';
        document.getElementById('cableColor').value        = cableColor || '';
        document.getElementById('portMemo').value          = memo       || '';
        closeSiblingDropdown();
        document.getElementById('portModal').classList.add('open');
    }

    // ── 비밀번호 토글 ────────────────────────────────────
    function togglePw(idx, btn) {
        const el = document.getElementById('pw-' + idx);
        if (!el) return;
        const showing = btn.textContent === '숨김';
        el.textContent = showing ? '••••••••' : el.dataset.pw;
        btn.textContent = showing ? '표시' : '숨김';
    }

    // ── 이미지 확대 ──────────────────────────────────────
    function openImgModal(src) {
        document.getElementById('imgModalImg').src = src;
        document.getElementById('imgModal').classList.add('open');
    }

    // ── 공통 ─────────────────────────────────────────────
    function closeModal(id) { document.getElementById(id).classList.remove('open'); }

    function toggleUserMenu(row) {
        const m = document.getElementById('userMenu');
        if (!m) return;
        const o = m.classList.toggle('open');
        row.classList.toggle('open', o);
    }
    document.addEventListener('click', function(e) {
        const m = document.getElementById('userMenu'), r = document.querySelector('.user-row');
        if (m && r && !r.contains(e.target) && !m.contains(e.target)) {
            m.classList.remove('open'); r.classList.remove('open');
        }
    });

    // 모달 외부 클릭 닫기 (imgModal 제외 - imgModal은 자체 처리)
    document.querySelectorAll('.modal-overlay').forEach(el => {
        if (el.id === 'imgModal') return;
        el.addEventListener('click', function(e) { if (e.target === this) this.classList.remove('open'); });
    });

    // 초기 사진 액션 버튼 렌더링
    renderPhotoActions();
</script>
</body>
</html>

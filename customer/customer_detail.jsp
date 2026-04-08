<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.util.List, com.admin.servlet.CustomerDetailServlet.*" %>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("../login.jsp"); return; }
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");

    CustomerVO    cust     = (CustomerVO)    request.getAttribute("customer");
    List<ProjectVO> projects = (List<ProjectVO>) request.getAttribute("projects");
    List<AssetVO>   assets   = (List<AssetVO>)   request.getAttribute("assets");
    if (projects == null) projects = new java.util.ArrayList<>();
    if (assets   == null) assets   = new java.util.ArrayList<>();

    String activeTab = request.getParameter("tab") != null ? request.getParameter("tab") : "project";
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
            <div class="panel-header">
                <span class="panel-title">IT 자산 목록</span>
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
        <% } %>
    </div>
</div>

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

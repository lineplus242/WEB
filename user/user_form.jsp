<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.admin.servlet.UserServlet.UserVO" %>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("../login.jsp"); return; }
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");

    if (!"ADMIN".equals(loginRole)) { response.sendError(403, "권한이 없습니다."); return; }

    UserVO u = (UserVO) request.getAttribute("user");
    boolean isEdit = (u != null);
    boolean isAdminAccount = Boolean.TRUE.equals(request.getAttribute("isAdminAccount"));
    String errorMsg = (String) request.getAttribute("errorMsg");
%>
<%! String v(String s) { return s != null ? s.replace("\"","&quot;") : ""; } %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isEdit ? "사용자 수정" : "사용자 등록" %> - 관리 시스템</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
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
        .user-row { display: flex; align-items: center; gap: 10px; padding: 8px; }
        .avatar { width: 30px; height: 30px; border-radius: 50%; background: #1a1e2e; display: flex; align-items: center; justify-content: center; font-size: 11px; font-weight: 500; color: #6b9af5; flex-shrink: 0; }
        .user-info p { font-size: 12px; font-weight: 500; color: #c8cad0; }
        .user-info span { font-size: 11px; color: #3d4251; }
        .logout-btn { display: flex; align-items: center; gap: 8px; padding: 7px 10px; border-radius: 7px; font-size: 12px; color: #6b7280; text-decoration: none; transition: background 0.12s; width: 100%; }
        .logout-btn:hover { background: #1a1015; color: #e05656; }
        .logout-btn svg { width: 14px; height: 14px; }

        .main { margin-left: 220px; flex: 1; display: flex; flex-direction: column; }
        .topbar { height: 52px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; gap: 12px; padding: 0 28px; background: #0e0f11; position: sticky; top: 0; z-index: 50; }
        .topbar a { font-size: 13px; color: #4b5161; text-decoration: none; }
        .topbar a:hover { color: #6b9af5; }
        .topbar-sep { color: #2a2d36; }
        .topbar-cur { font-size: 13px; font-weight: 500; color: #f2f3f5; }
        .content { padding: 28px; max-width: 600px; }

        .error-box { background: rgba(224,86,86,0.1); border: 1px solid rgba(224,86,86,0.3); border-radius: 8px; padding: 12px 16px; font-size: 13px; color: #e05656; margin-bottom: 24px; }

        .form-card { background: #131519; border: 1px solid #1e2025; border-radius: 12px; margin-bottom: 16px; overflow: hidden; }
        .form-card-title { padding: 14px 20px; border-bottom: 1px solid #1e2025; font-size: 11px; font-weight: 500; color: #9ca3af; letter-spacing: 0.05em; text-transform: uppercase; }
        .form-body { padding: 20px; }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .form-group { display: flex; flex-direction: column; gap: 6px; }
        .form-group.full { grid-column: span 2; }
        label { font-size: 11px; font-weight: 500; color: #6b7280; letter-spacing: 0.06em; text-transform: uppercase; }
        label .req { color: #3b6ef5; margin-left: 2px; }
        input[type=text], input[type=password], input[type=email], select {
            background: #0e0f11; border: 1px solid #252830; border-radius: 8px;
            padding: 9px 12px; font-size: 13px; color: #e8e9eb;
            font-family: 'DM Sans', sans-serif; outline: none; transition: border 0.15s; width: 100%;
        }
        input:focus, select:focus { border-color: #3b6ef5; }
        input::placeholder { color: #3d4251; }
        input:-webkit-autofill,
        input:-webkit-autofill:hover,
        input:-webkit-autofill:focus {
            -webkit-box-shadow: 0 0 0px 1000px #0e0f11 inset;
            -webkit-text-fill-color: #e8e9eb;
            transition: background-color 5000s ease-in-out 0s;
        }
        input:read-only { color: #4b5161; cursor: default; }
        select option { background: #131519; }
        .hint { font-size: 11px; color: #3d4251; margin-top: 3px; }

        .form-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 24px; }
        .btn { padding: 9px 22px; border-radius: 8px; font-size: 13px; font-family: 'DM Sans', sans-serif; cursor: pointer; border: none; font-weight: 500; transition: background 0.15s; text-decoration: none; display: inline-flex; align-items: center; }
        .btn-primary { background: #3b6ef5; color: #fff; }
        .btn-primary:hover { background: #2f5ee0; }
        .btn-secondary { background: #1a1e2e; color: #6b9af5; border: 1px solid #252d44; }
        .btn-secondary:hover { background: #202540; }
    </style>
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

    <div class="main">
        <div class="topbar">
            <a href="../UserServlet?action=list">사용자 관리</a>
            <span class="topbar-sep">/</span>
            <span class="topbar-cur"><%= isEdit ? "계정 수정" : "신규 등록" %></span>
        </div>
        <div class="content">

            <% if (errorMsg != null) { %>
            <div class="error-box"><%= errorMsg %></div>
            <% } %>

            <form action="../UserServlet" method="post">
                <input type="hidden" name="action" value="<%= isEdit ? "update" : "save" %>">
                <% if (isEdit) { %><input type="hidden" name="userSeq" value="<%= u.userSeq %>"><% } %>

                <div class="form-card">
                    <div class="form-card-title">계정 정보</div>
                    <div class="form-body">
                        <div class="form-grid">
                            <div class="form-group">
                                <label>아이디 <span class="req">*</span></label>
                                <% if (isEdit) { %>
                                <input type="text" value="<%= v(u.userId) %>" readonly>
                                <% } else { %>
                                <input type="text" name="userId" required placeholder="영문/숫자" autocomplete="off">
                                <% } %>
                            </div>
                            <div class="form-group">
                                <label>이름 <% if (!isAdminAccount) { %><span class="req">*</span><% } %></label>
                                <input type="text" name="userName" <%= !isAdminAccount ? "required" : "readonly" %>
                                       placeholder="홍길동" value="<%= isEdit ? v(u.userName) : "" %>">
                            </div>
                            <div class="form-group">
                                <label>이메일</label>
                                <input type="email" name="email" placeholder="example@company.com"
                                       value="<%= isEdit && u.email != null ? v(u.email) : "" %>">
                            </div>
                            <div class="form-group">
                                <label><%= isEdit ? "비밀번호 재설정" : "비밀번호 *" %></label>
                                <input type="password" name="password"
                                       <%= isEdit ? "" : "required" %>
                                       placeholder="<%= isEdit ? (isAdminAccount ? "비밀번호 변경" : "변경 시에만 입력") : "6자 이상" %>" autocomplete="new-password">
                                <% if (isEdit && !isAdminAccount) { %><span class="hint">입력하지 않으면 기존 비밀번호 유지</span><% } %>
                                <% if (isAdminAccount) { %><span class="hint" style="color:#d4a017">admin 계정은 비밀번호만 변경할 수 있습니다.</span><% } %>
                            </div>
                            <div class="form-group">
                                <label>권한</label>
                                <% if (isAdminAccount) { %>
                                <input type="text" value="ADMIN" readonly>
                                <% } else { %>
                                <select name="role">
                                    <option value="USER"  <%= !isEdit || "USER".equals(u.role)  ? "selected" : "" %>>USER</option>
                                    <option value="ADMIN" <%= isEdit && "ADMIN".equals(u.role)  ? "selected" : "" %>>ADMIN</option>
                                </select>
                                <% } %>
                            </div>
                            <div class="form-group">
                                <label>상태</label>
                                <% if (isAdminAccount) { %>
                                <input type="text" value="활성 (변경 불가)" readonly>
                                <% } else { %>
                                <select name="useYn">
                                    <option value="Y" <%= !isEdit || "Y".equals(u.useYn) ? "selected" : "" %>>활성</option>
                                    <option value="N" <%= isEdit && "N".equals(u.useYn) ? "selected" : "" %>>비활성</option>
                                </select>
                                <% } %>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="form-actions">
                    <a href="../UserServlet?action=list" class="btn btn-secondary">취소</a>
                    <button type="submit" class="btn btn-primary"><%= isEdit ? "수정 저장" : "등록하기" %></button>
                </div>
            </form>
        </div>
    </div>
</body>
</html>

<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.admin.servlet.CustomerServlet.CustomerVO" %>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("../login.jsp"); return; }
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");

    CustomerVO c = (CustomerVO) request.getAttribute("customer");
    boolean isEdit = (c != null);
    String errorMsg = (String) request.getAttribute("errorMsg");
%>
<%! String v(String s) { return s != null ? s.replace("\"","&quot;") : ""; } %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><%= isEdit ? "고객사 수정" : "고객사 등록" %> - 관리 시스템</title>
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
        .sb-name { font-size: 13px; font-weight: 500; color: #e8e9eb; }
        .sb-dot  { color: #3b6ef5; }
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

        /* 메인 */
        .main { margin-left: 220px; flex: 1; display: flex; flex-direction: column; }
        .topbar { height: 52px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; gap: 12px; padding: 0 28px; background: #0e0f11; position: sticky; top: 0; z-index: 50; }
        .topbar a { font-size: 13px; color: #4b5161; text-decoration: none; }
        .topbar a:hover { color: #6b9af5; }
        .topbar-sep { color: #2a2d36; }
        .topbar-cur { font-size: 13px; font-weight: 500; color: #f2f3f5; }
        .content { padding: 28px; max-width: 860px; }

        /* 에러 */
        .error-box { background: rgba(224,86,86,0.1); border: 1px solid rgba(224,86,86,0.3); border-radius: 8px; padding: 12px 16px; font-size: 13px; color: #e05656; margin-bottom: 24px; }

        /* 폼 섹션 */
        .form-card { background: #131519; border: 1px solid #1e2025; border-radius: 12px; margin-bottom: 16px; overflow: hidden; }
        .form-card-title { padding: 14px 20px; border-bottom: 1px solid #1e2025; font-size: 11px; font-weight: 500; color: #9ca3af; letter-spacing: 0.05em; text-transform: uppercase; }
        .form-body { padding: 20px; }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .form-grid.col3 { grid-template-columns: 1fr 1fr 1fr; }
        .form-grid.col1 { grid-template-columns: 1fr; }
        .form-group { display: flex; flex-direction: column; gap: 6px; }
        .form-group.span2 { grid-column: span 2; }
        .form-group.span3 { grid-column: span 3; }
        label { font-size: 11px; font-weight: 500; color: #6b7280; letter-spacing: 0.06em; text-transform: uppercase; }
        label .req { color: #3b6ef5; margin-left: 2px; }
        input[type=text], input[type=email], input[type=tel], input[type=date], input[type=number],
        select, textarea {
            background: #0e0f11; border: 1px solid #252830; border-radius: 8px;
            padding: 9px 12px; font-size: 13px; color: #e8e9eb;
            font-family: 'DM Sans', sans-serif; outline: none; transition: border 0.15s; width: 100%;
        }
        input:focus, select:focus, textarea:focus { border-color: #3b6ef5; }
        input::placeholder, textarea::placeholder { color: #3d4251; }
        select option { background: #131519; }
        textarea { resize: vertical; min-height: 80px; }

        /* 하단 버튼 */
        .form-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 24px; }
        .btn { padding: 9px 22px; border-radius: 8px; font-size: 13px; font-family: 'DM Sans', sans-serif; cursor: pointer; border: none; font-weight: 500; transition: background 0.15s; text-decoration: none; display: inline-flex; align-items: center; }
        .btn-primary   { background: #3b6ef5; color: #fff; }
        .btn-primary:hover { background: #2f5ee0; }
        .btn-secondary { background: #1a1e2e; color: #6b9af5; border: 1px solid #252d44; }
        .btn-secondary:hover { background: #202540; }
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
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><path d="M9 22V12h6v10"/></svg>
            고객사 관리
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
            <a href="../CustomerServlet?action=list">고객사 관리</a>
            <span class="topbar-sep">/</span>
            <span class="topbar-cur"><%= isEdit ? "수정" : "신규 등록" %></span>
        </div>
        <div class="content">

            <% if (errorMsg != null) { %>
            <div class="error-box"><%= errorMsg %></div>
            <% } %>

            <form action="../CustomerServlet" method="post">
                <input type="hidden" name="action" value="<%= isEdit ? "update" : "save" %>">
                <% if (isEdit) { %><input type="hidden" name="custSeq" value="<%= c.custSeq %>"><% } %>

                <!-- 기본 정보 -->
                <div class="form-card">
                    <div class="form-card-title">기본 정보</div>
                    <div class="form-body">
                        <div class="form-grid">
                            <div class="form-group">
                                <label>고객사명 <span class="req">*</span></label>
                                <input type="text" name="custName" required placeholder="(주)회사명"
                                       value="<%= isEdit ? v(c.custName) : "" %>">
                            </div>
                            <div class="form-group">
                                <label>사업자번호</label>
                                <input type="text" name="bizNo" placeholder="000-00-00000"
                                       value="<%= isEdit ? v(c.bizNo) : "" %>">
                            </div>
                            <div class="form-group">
                                <label>대표자명</label>
                                <input type="text" name="ceoName" placeholder="홍길동"
                                       value="<%= isEdit ? v(c.ceoName) : "" %>">
                            </div>
                            <div class="form-group">
                                <label>업종</label>
                                <input type="text" name="industry" placeholder="IT/소프트웨어"
                                       value="<%= isEdit ? v(c.industry) : "" %>">
                            </div>
                            <div class="form-group">
                                <label>대표 전화</label>
                                <input type="tel" name="phone" placeholder="02-0000-0000"
                                       value="<%= isEdit ? v(c.phone) : "" %>">
                            </div>
                            <div class="form-group">
                                <label>대표 이메일</label>
                                <input type="email" name="email" placeholder="contact@company.com"
                                       value="<%= isEdit ? v(c.email) : "" %>">
                            </div>
                            <div class="form-group span2">
                                <label>주소</label>
                                <input type="text" name="address" placeholder="서울특별시 강남구 ..."
                                       value="<%= isEdit ? v(c.address) : "" %>">
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 담당자 정보 -->
                <div class="form-card">
                    <div class="form-card-title">담당자 정보</div>
                    <div class="form-body">
                        <div class="form-grid col3">
                            <div class="form-group">
                                <label>담당자명</label>
                                <input type="text" name="managerName" placeholder="홍길동"
                                       value="<%= isEdit ? v(c.managerName) : "" %>">
                            </div>
                            <div class="form-group">
                                <label>담당자 연락처</label>
                                <input type="tel" name="managerTel" placeholder="010-0000-0000"
                                       value="<%= isEdit ? v(c.managerTel) : "" %>">
                            </div>
                            <div class="form-group">
                                <label>담당자 이메일</label>
                                <input type="email" name="managerEmail" placeholder="manager@company.com"
                                       value="<%= isEdit ? v(c.managerEmail) : "" %>">
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 계약/서비스 정보 -->
                <div class="form-card">
                    <div class="form-card-title">계약 / 서비스 정보</div>
                    <div class="form-body">
                        <div class="form-grid">
                            <div class="form-group">
                                <label>서비스 유형</label>
                                <select name="serviceType">
                                    <option value="">선택</option>
                                    <% String[] svcTypes = {"신규개발","유지보수","컨설팅","기술지원","기타"}; %>
                                    <% for (String t : svcTypes) { %>
                                    <option value="<%= t %>" <%= isEdit && t.equals(c.serviceType) ? "selected" : "" %>><%= t %></option>
                                    <% } %>
                                </select>
                            </div>
                            <div class="form-group">
                                <label>상태</label>
                                <select name="status">
                                    <option value="ACTIVE"   <%= !isEdit || "ACTIVE".equals(c.status)   ? "selected" : "" %>>활성</option>
                                    <option value="INACTIVE" <%= isEdit && "INACTIVE".equals(c.status)   ? "selected" : "" %>>비활성</option>
                                    <option value="PENDING"  <%= isEdit && "PENDING".equals(c.status)    ? "selected" : "" %>>대기</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 메모 -->
                <div class="form-card">
                    <div class="form-card-title">메모 / 비고</div>
                    <div class="form-body">
                        <textarea name="memo" placeholder="특이사항, 요청사항 등을 입력하세요..."><%= isEdit && c.memo != null ? c.memo : "" %></textarea>
                    </div>
                </div>

                <!-- 하단 버튼 -->
                <div class="form-actions">
                    <a href="../CustomerServlet?action=list" class="btn btn-secondary">취소</a>
                    <button type="submit" class="btn btn-primary"><%= isEdit ? "수정 저장" : "등록하기" %></button>
                </div>
            </form>
        </div>
    </div>
</body>
</html>

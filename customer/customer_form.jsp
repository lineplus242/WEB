<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.admin.servlet.CustomerServlet.CustomerVO, com.admin.servlet.CustomerServlet.ManagerVO, java.util.List" %>
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
    <script>(function(){if(localStorage.getItem('theme')==='light')document.documentElement.setAttribute('data-theme','light');})()</script>
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

        /* 담당자 다중 행 */
        .manager-list { display: flex; flex-direction: column; gap: 10px; }
        .manager-row { display: grid; grid-template-columns: 1fr 1fr 1fr auto; gap: 10px; align-items: end; }
        .manager-row .form-group { margin: 0; }
        .btn-icon { width: 34px; height: 34px; border-radius: 7px; border: none; cursor: pointer; display: flex; align-items: center; justify-content: center; flex-shrink: 0; font-size: 16px; font-weight: 500; transition: background .12s; }
        .btn-add-mgr  { background: #1a1e2e; color: #6b9af5; border: 1px solid #252d44; }
        .btn-add-mgr:hover  { background: #202540; }
        .btn-del-mgr  { background: #1a0d0d; color: #e05656; border: 1px solid #2a0d0d; }
        .btn-del-mgr:hover  { background: #2a1010; }
        .mgr-add-bar { margin-top: 8px; }

        /* 하단 버튼 */
        .form-actions { display: flex; gap: 10px; justify-content: flex-end; margin-top: 24px; }
        .btn { padding: 9px 22px; border-radius: 8px; font-size: 13px; font-family: 'DM Sans', sans-serif; cursor: pointer; border: none; font-weight: 500; transition: background 0.15s; text-decoration: none; display: inline-flex; align-items: center; }
        .btn-primary   { background: #3b6ef5; color: #fff; }
        .btn-primary:hover { background: #2f5ee0; }
        .btn-secondary { background: #1a1e2e; color: #6b9af5; border: 1px solid #252d44; }
        .btn-secondary:hover { background: #202540; }
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
                                <label>대표 전화</label>
                                <input type="tel" name="phone" placeholder="02-0000-0000"
                                       value="<%= isEdit ? v(c.phone) : "" %>">
                            </div>
                            <div class="form-group span2">
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

                <!-- 담당자 정보 (다중) -->
                <div class="form-card">
                    <div class="form-card-title" style="display:flex;align-items:center;justify-content:space-between">
                        <span>담당자 정보</span>
                        <button type="button" class="btn-icon btn-add-mgr" onclick="addManagerRow()" title="담당자 추가">+</button>
                    </div>
                    <div class="form-body">
                        <div class="manager-list" id="managerList">
                            <%
                            List<ManagerVO> mgrs = isEdit ? c.managers : null;
                            if (mgrs != null && !mgrs.isEmpty()) {
                                for (ManagerVO m : mgrs) {
                            %>
                            <div class="manager-row">
                                <div class="form-group">
                                    <% if (mgrs.indexOf(m) == 0) { %><label>담당자명</label><% } %>
                                    <input type="text" name="managerName" placeholder="홍길동" value="<%= m.name != null ? v(m.name) : "" %>">
                                </div>
                                <div class="form-group">
                                    <% if (mgrs.indexOf(m) == 0) { %><label>연락처</label><% } %>
                                    <input type="tel" name="managerTel" placeholder="010-0000-0000" value="<%= m.tel != null ? v(m.tel) : "" %>">
                                </div>
                                <div class="form-group">
                                    <% if (mgrs.indexOf(m) == 0) { %><label>이메일</label><% } %>
                                    <input type="email" name="managerEmail" placeholder="manager@company.com" value="<%= m.email != null ? v(m.email) : "" %>">
                                </div>
                                <button type="button" class="btn-icon btn-del-mgr" onclick="removeManagerRow(this)" title="삭제" style="margin-top:<%= mgrs.indexOf(m) == 0 ? "20px" : "0" %>">−</button>
                            </div>
                            <% } } else { %>
                            <div class="manager-row">
                                <div class="form-group">
                                    <label>담당자명</label>
                                    <input type="text" name="managerName" placeholder="홍길동">
                                </div>
                                <div class="form-group">
                                    <label>연락처</label>
                                    <input type="tel" name="managerTel" placeholder="010-0000-0000">
                                </div>
                                <div class="form-group">
                                    <label>이메일</label>
                                    <input type="email" name="managerEmail" placeholder="manager@company.com">
                                </div>
                                <button type="button" class="btn-icon btn-del-mgr" onclick="removeManagerRow(this)" title="삭제" style="margin-top:20px">−</button>
                            </div>
                            <% } %>
                        </div>
                    </div>
                </div>

                <!-- 상태 -->
                <div class="form-card">
                    <div class="form-card-title">계약 정보</div>
                    <div class="form-body">
                        <div class="form-grid">
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
<script>
function addManagerRow() {
    const list = document.getElementById('managerList');
    const row = document.createElement('div');
    row.className = 'manager-row';
    row.innerHTML = `
        <div class="form-group"><input type="text" name="managerName" placeholder="홍길동"></div>
        <div class="form-group"><input type="tel" name="managerTel" placeholder="010-0000-0000"></div>
        <div class="form-group"><input type="email" name="managerEmail" placeholder="manager@company.com"></div>
        <button type="button" class="btn-icon btn-del-mgr" onclick="removeManagerRow(this)" title="삭제">−</button>
    `;
    list.appendChild(row);
}
function removeManagerRow(btn) {
    const list = document.getElementById('managerList');
    if (list.children.length <= 1) return; // 최소 1행 유지
    btn.closest('.manager-row').remove();
}
function toggleUserMenu(row){const m=document.getElementById('userMenu');if(!m)return;const o=m.classList.toggle('open');row.classList.toggle('open',o);}
document.addEventListener('click',function(e){const m=document.getElementById('userMenu'),r=document.querySelector('.user-row');if(m&&r&&!r.contains(e.target)&&!m.contains(e.target)){m.classList.remove('open');r.classList.remove('open');}});
</script>
<script src="../js/common.js"></script>
</body>
</html>

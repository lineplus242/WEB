<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // 이미 로그인된 경우 메인으로 리다이렉트
    if (session.getAttribute("loginUser") != null) {
        response.sendRedirect("main.jsp");
        return;
    }
    String errorMsg = (String) request.getAttribute("errorMsg");
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>로그인 - 관리 시스템</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'DM Sans', sans-serif;
            background: #0e0f11;
            color: #e8e9eb;
            min-height: 100vh;
            display: flex;
        }

        /* ── 왼쪽 로그인 영역 ── */
        .left {
            flex: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: 60px 70px;
            border-right: 1px solid #1e2025;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 64px;
        }

        .brand-icon {
            width: 32px;
            height: 32px;
            background: #3b6ef5;
            border-radius: 8px;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .brand-icon svg { width: 18px; height: 18px; fill: #fff; }

        .brand-name {
            font-size: 15px;
            font-weight: 500;
            color: #e8e9eb;
            letter-spacing: 0.02em;
        }

        .brand-dot { color: #3b6ef5; }

        h1 {
            font-size: 26px;
            font-weight: 400;
            color: #f2f3f5;
            margin-bottom: 6px;
            letter-spacing: -0.02em;
        }

        .sub {
            font-size: 13px;
            color: #6b7280;
            margin-bottom: 40px;
        }

        .field { margin-bottom: 20px; }

        label {
            display: block;
            font-size: 12px;
            font-weight: 500;
            color: #9ca3af;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            margin-bottom: 7px;
        }

        .input-wrap { position: relative; }

        .input-wrap input {
            width: 100%;
            background: #161820;
            border: 1px solid #252830;
            border-radius: 8px;
            padding: 11px 14px 11px 40px;
            font-size: 14px;
            color: #e8e9eb;
            font-family: 'DM Sans', sans-serif;
            outline: none;
            transition: border 0.15s;
        }

        .input-wrap input:focus {
            border-color: #3b6ef5;
        }

        .input-wrap input::placeholder { color: #3d4251; }

        .ico {
            position: absolute;
            left: 13px;
            top: 50%;
            transform: translateY(-50%);
            opacity: 0.4;
            display: flex;
            align-items: center;
        }

        .options {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin: 4px 0 28px;
        }

        .check-label {
            display: flex;
            align-items: center;
            gap: 7px;
            font-size: 13px;
            color: #6b7280;
            cursor: pointer;
        }

        .check-label input[type="checkbox"] {
            accent-color: #3b6ef5;
            width: 14px;
            height: 14px;
        }

        .forgot {
            font-size: 13px;
            color: #3b6ef5;
            text-decoration: none;
        }

        .forgot:hover { text-decoration: underline; }

        .btn {
            width: 100%;
            background: #3b6ef5;
            border: none;
            border-radius: 8px;
            padding: 12px;
            font-size: 14px;
            font-weight: 500;
            color: #fff;
            cursor: pointer;
            font-family: 'DM Sans', sans-serif;
            letter-spacing: 0.02em;
            transition: background 0.15s;
        }

        .btn:hover { background: #2f5ee0; }
        .btn:active { background: #2550c8; }

        .error-msg {
            background: rgba(224, 86, 86, 0.1);
            border: 1px solid rgba(224, 86, 86, 0.3);
            border-radius: 8px;
            padding: 10px 14px;
            font-size: 13px;
            color: #e05656;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        .footer {
            margin-top: 40px;
            font-size: 12px;
            color: #3d4251;
        }

        /* ── 오른쪽 정보 패널 ── */
        .right {
            width: 340px;
            background: #0b0c0f;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: 48px 36px;
            gap: 20px;
        }

        .status-tag {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: #1a1e2a;
            border: 1px solid #252d44;
            border-radius: 20px;
            padding: 5px 12px;
            font-size: 11px;
            color: #5a80d0;
            font-family: 'DM Mono', monospace;
        }

        .pulse {
            display: inline-block;
            width: 6px;
            height: 6px;
            background: #22c97a;
            border-radius: 50%;
            animation: blink 1.6s ease-in-out infinite;
        }

        @keyframes blink {
            0%, 100% { opacity: 1; }
            50%       { opacity: 0.2; }
        }

        .stat-card {
            background: #131519;
            border: 1px solid #1e2025;
            border-radius: 12px;
            padding: 20px 24px;
            width: 100%;
        }

        .stat-label {
            font-size: 11px;
            color: #4b5161;
            letter-spacing: 0.06em;
            text-transform: uppercase;
            margin-bottom: 8px;
        }

        .stat-val {
            font-size: 22px;
            font-weight: 500;
            color: #f2f3f5;
            font-family: 'DM Mono', monospace;
            letter-spacing: -0.02em;
        }

        .stat-change {
            font-size: 11px;
            color: #22c97a;
            margin-top: 4px;
        }

        .right-title {
            font-size: 13px;
            color: #3d4251;
            text-align: center;
            line-height: 1.7;
            margin-top: 12px;
        }

        /* 반응형 */
        @media (max-width: 768px) {
            .right { display: none; }
            .left { padding: 40px 32px; }
        }
    </style>
</head>
<body>

    <!-- ── 왼쪽: 로그인 폼 ── -->
    <div class="left">
        <div class="brand">
            <div class="brand-icon">
                <svg viewBox="0 0 24 24">
                    <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/>
                </svg>
            </div>
            <span class="brand-name">ADMIN<span class="brand-dot">.</span>SYS</span>
        </div>

        <h1>다시 오신 것을 환영합니다</h1>
        <p class="sub">관리자 계정으로 로그인하세요</p>

        <!-- 에러 메시지 -->
        <% if (errorMsg != null) { %>
        <div class="error-msg">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="12"/><line x1="12" y1="16" x2="12.01" y2="16"/>
            </svg>
            <%= errorMsg %>
        </div>
        <% } %>

        <form action="LoginServlet" method="post">
            <div class="field">
                <label for="userId">아이디</label>
                <div class="input-wrap">
                    <span class="ico">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" stroke-width="2">
                            <circle cx="12" cy="8" r="4"/>
                            <path d="M4 20c0-4 3.6-7 8-7s8 3 8 7"/>
                        </svg>
                    </span>
                    <input type="text" id="userId" name="userId"
                           placeholder="사용자 아이디 입력"
                           value="<%= request.getParameter("userId") != null ? request.getParameter("userId") : "" %>"
                           required autocomplete="username">
                </div>
            </div>

            <div class="field">
                <label for="password">비밀번호</label>
                <div class="input-wrap">
                    <span class="ico">
                        <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#9ca3af" stroke-width="2">
                            <rect x="3" y="11" width="18" height="11" rx="2"/>
                            <path d="M7 11V7a5 5 0 0110 0v4"/>
                        </svg>
                    </span>
                    <input type="password" id="password" name="password"
                           placeholder="비밀번호 입력"
                           required autocomplete="current-password">
                </div>
            </div>

            <div class="options">
                <label class="check-label">
                    <input type="checkbox" name="rememberMe" value="Y"> 로그인 상태 유지
                </label>
                <a class="forgot" href="findPassword.jsp">비밀번호 찾기</a>
            </div>

            <button type="submit" class="btn">로그인</button>
        </form>

        <div class="footer">© 2026 Admin System.</div>
    </div>

    <!-- ── 오른쪽: 시스템 정보 ── -->
    <div class="right">
        <div class="status-tag">
            <span class="pulse"></span>시스템 정상 운영 중
        </div>

        <div class="stat-card">
            <div class="stat-label">오늘 접속자</div>
            <div class="stat-val">1,284</div>
            <div class="stat-change">↑ 12% vs 어제</div>
        </div>

        <div class="stat-card">
            <div class="stat-label">활성 세션</div>
            <div class="stat-val">47</div>
            <div class="stat-change">실시간 갱신</div>
        </div>

        <div class="stat-card">
            <div class="stat-label">DB 응답시간</div>
            <div class="stat-val">3.2ms</div>
            <div class="stat-change">MySQL 정상</div>
        </div>

        <p class="right-title">내부 관리 시스템</p>
    </div>

</body>
</html>

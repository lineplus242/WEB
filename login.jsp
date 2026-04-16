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
    <title>로그인 — 관리 시스템</title>
    <meta name="description" content="Bumil Information 내부 관리 시스템 로그인">
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard/dist/web/static/pretendard.min.css">
    <script src="https://code.iconify.design/iconify-icon/2.3.0/iconify-icon.min.js"></script>
    <script>
        tailwind.config = {
            theme: {
                extend: {
                    fontFamily: {
                        sans: ['Pretendard', '-apple-system', 'BlinkMacSystemFont', 'system-ui', 'sans-serif'],
                    },
                    colors: {
                        accent: '#3b6ef5',
                    },
                    animation: {
                        'float': 'float 7s ease-in-out infinite',
                        'float-delay': 'float 9s ease-in-out 2s infinite',
                        'blink': 'blink 1.8s ease-in-out infinite',
                        'fadeInUp': 'fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) forwards',
                        'fadeInUp-delay': 'fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.1s forwards',
                        'fadeInUp-delay2': 'fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.2s forwards',
                        'fadeInUp-delay3': 'fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.3s forwards',
                        'fadeInUp-delay4': 'fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.4s forwards',
                    },
                    keyframes: {
                        float: {
                            '0%,100%': { transform: 'translateY(0px)' },
                            '50%': { transform: 'translateY(-18px)' },
                        },
                        blink: {
                            '0%,100%': { opacity: '1' },
                            '50%': { opacity: '0.2' },
                        },
                        fadeInUp: {
                            from: { opacity: '0', transform: 'translateY(1.5rem)', filter: 'blur(4px)' },
                            to:   { opacity: '1', transform: 'translateY(0)',      filter: 'blur(0)' },
                        },
                    },
                },
            },
        }
    </script>
    <style>
        * { box-sizing: border-box; }

        html { scroll-behavior: smooth; }

        body {
            font-family: 'Pretendard', -apple-system, system-ui, sans-serif;
            background: #09090b;
            color: #e4e4e7;
            min-height: 100dvh;
            overflow: hidden;
            word-break: keep-all;
        }

        /* ── 노이즈 오버레이 ── */
        body::before {
            content: '';
            position: fixed;
            inset: 0;
            z-index: 60;
            pointer-events: none;
            opacity: 0.03;
            background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
        }

        /* ── 메시 그라디언트 배경 ── */
        .mesh-bg {
            position: fixed;
            inset: 0;
            z-index: 0;
            pointer-events: none;
            overflow: hidden;
        }

        .orb {
            position: absolute;
            border-radius: 50%;
            filter: blur(80px);
            opacity: 0.12;
        }

        .orb-1 {
            width: 500px; height: 500px;
            background: radial-gradient(circle, #3b6ef5 0%, transparent 70%);
            top: -150px; left: -100px;
            animation: float 7s ease-in-out infinite;
        }

        .orb-2 {
            width: 400px; height: 400px;
            background: radial-gradient(circle, #1d4ed8 0%, transparent 70%);
            bottom: -100px; right: 200px;
            animation: float 9s ease-in-out 2s infinite;
        }

        .orb-3 {
            width: 300px; height: 300px;
            background: radial-gradient(circle, #3b82f6 0%, transparent 70%);
            top: 40%; right: -80px;
            animation: float 11s ease-in-out 1s infinite;
        }

        @keyframes float {
            0%,100% { transform: translateY(0px); }
            50%      { transform: translateY(-18px); }
        }

        /* ── 레이아웃 ── */
        .layout {
            position: relative;
            z-index: 10;
            display: flex;
            min-height: 100dvh;
        }

        /* ── 왼쪽 패널 ── */
        .left-panel {
            flex: 1;
            display: flex;
            flex-direction: column;
            justify-content: center;
            padding: 56px 64px;
            border-right: 1px solid rgba(255,255,255,0.05);
        }

        /* ── 브랜드 ── */
        .brand {
            display: flex;
            align-items: center;
            gap: 10px;
            margin-bottom: 56px;
            opacity: 0;
            animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) forwards;
        }

        @keyframes fadeInUp {
            from { opacity: 0; transform: translateY(1.5rem); filter: blur(4px); }
            to   { opacity: 1; transform: translateY(0);      filter: blur(0); }
        }

        .brand-icon {
            width: 34px; height: 34px;
            background: linear-gradient(135deg, #3b6ef5 0%, #2550c8 100%);
            border-radius: 9px;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 0 20px rgba(59,110,245,0.35);
        }

        .brand-name {
            font-size: 14px;
            font-weight: 600;
            color: #f4f4f5;
            letter-spacing: 0.05em;
            text-transform: uppercase;
        }

        .brand-dot { color: #3b6ef5; }

        /* ── 폼 영역 ── */
        .form-wrap {
            max-width: 360px;
        }

        .heading-area {
            margin-bottom: 36px;
            opacity: 0;
            animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.08s forwards;
        }

        .eyebrow {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: rgba(59,110,245,0.12);
            border: 1px solid rgba(59,110,245,0.2);
            border-radius: 99px;
            padding: 4px 10px;
            font-size: 11px;
            font-weight: 500;
            color: #7da3f8;
            letter-spacing: 0.08em;
            text-transform: uppercase;
            margin-bottom: 14px;
        }

        h1 {
            font-size: 24px;
            font-weight: 600;
            color: #f4f4f5;
            letter-spacing: -0.025em;
            line-height: 1.3;
            margin-bottom: 6px;
            word-break: keep-all;
        }

        .sub {
            font-size: 13px;
            color: #52525b;
            line-height: 1.6;
            word-break: keep-all;
        }

        /* ── 에러 메시지 ── */
        .error-box {
            display: flex;
            align-items: center;
            gap: 8px;
            background: rgba(239,68,68,0.08);
            border: 1px solid rgba(239,68,68,0.2);
            border-radius: 10px;
            padding: 10px 14px;
            font-size: 13px;
            color: #f87171;
            margin-bottom: 20px;
            word-break: keep-all;
        }

        /* ── 필드 ── */
        .field {
            margin-bottom: 16px;
            opacity: 0;
        }

        .field:nth-child(1) { animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.16s forwards; }
        .field:nth-child(2) { animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.24s forwards; }

        label {
            display: block;
            font-size: 11.5px;
            font-weight: 500;
            color: #71717a;
            letter-spacing: 0.07em;
            text-transform: uppercase;
            margin-bottom: 7px;
        }

        .input-wrap { position: relative; }

        .input-wrap input {
            width: 100%;
            background: rgba(255,255,255,0.04);
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 10px;
            padding: 11px 14px 11px 40px;
            font-size: 14px;
            color: #e4e4e7;
            font-family: 'Pretendard', system-ui, sans-serif;
            outline: none;
            transition: all 0.4s cubic-bezier(0.16,1,0.3,1);
            box-shadow: inset 0 1px 0 rgba(255,255,255,0.04);
        }

        .input-wrap input:focus {
            border-color: rgba(59,110,245,0.5);
            background: rgba(59,110,245,0.06);
            box-shadow: 0 0 0 3px rgba(59,110,245,0.12), inset 0 1px 0 rgba(255,255,255,0.06);
        }

        .input-wrap input::placeholder { color: #3f3f46; }

        .input-ico {
            position: absolute;
            left: 13px;
            top: 50%;
            transform: translateY(-50%);
            color: #52525b;
            display: flex;
            align-items: center;
            pointer-events: none;
            transition: color 0.3s ease;
        }

        .input-wrap:focus-within .input-ico { color: #3b6ef5; }

        /* ── 옵션 행 ── */
        .options {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin: 8px 0 24px;
            opacity: 0;
            animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.32s forwards;
        }

        .check-label {
            display: flex;
            align-items: center;
            gap: 7px;
            font-size: 13px;
            color: #71717a;
            cursor: pointer;
            user-select: none;
            transition: color 0.3s ease;
        }

        .check-label:hover { color: #a1a1aa; }

        .check-label input[type="checkbox"] {
            accent-color: #3b6ef5;
            width: 14px;
            height: 14px;
            cursor: pointer;
        }

        .forgot {
            font-size: 13px;
            color: #3b6ef5;
            text-decoration: none;
            transition: all 0.3s cubic-bezier(0.16,1,0.3,1);
        }

        .forgot:hover { color: #7da3f8; }

        /* ── 버튼 ── */
        .btn-wrap {
            opacity: 0;
            animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.4s forwards;
        }

        .btn {
            width: 100%;
            background: linear-gradient(135deg, #3b6ef5 0%, #2550c8 100%);
            border: none;
            border-radius: 10px;
            padding: 13px 24px;
            font-size: 14px;
            font-weight: 600;
            color: #fff;
            cursor: pointer;
            font-family: 'Pretendard', system-ui, sans-serif;
            letter-spacing: 0.01em;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 8px;
            transition: all 0.4s cubic-bezier(0.16,1,0.3,1);
            box-shadow: 0 4px 20px rgba(59,110,245,0.28), inset 0 1px 0 rgba(255,255,255,0.12);
            position: relative;
            overflow: hidden;
        }

        .btn::before {
            content: '';
            position: absolute;
            inset: 0;
            background: linear-gradient(135deg, rgba(255,255,255,0.1) 0%, transparent 60%);
            opacity: 0;
            transition: opacity 0.4s ease;
        }

        .btn:hover {
            transform: scale(1.015) translateY(-1px);
            box-shadow: 0 8px 30px rgba(59,110,245,0.4), inset 0 1px 0 rgba(255,255,255,0.15);
        }

        .btn:hover::before { opacity: 1; }

        .btn:active {
            transform: scale(0.98) translateY(0);
            box-shadow: 0 2px 10px rgba(59,110,245,0.2);
        }

        .btn-arrow {
            width: 22px; height: 22px;
            background: rgba(0,0,0,0.15);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            transition: transform 0.4s cubic-bezier(0.16,1,0.3,1);
        }

        .btn:hover .btn-arrow { transform: translateX(2px); }

        /* ── 하단 카피 ── */
        .footer-copy {
            margin-top: 36px;
            font-size: 11.5px;
            color: #3f3f46;
            opacity: 0;
            animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.5s forwards;
        }

        /* ── 오른쪽 패널 ── */
        .right-panel {
            width: 320px;
            background: rgba(255,255,255,0.01);
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            padding: 48px 32px;
            gap: 16px;
        }

        /* ── 상태 태그 ── */
        .status-tag {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            background: rgba(34,197,94,0.08);
            border: 1px solid rgba(34,197,94,0.18);
            border-radius: 99px;
            padding: 5px 13px;
            font-size: 11.5px;
            font-weight: 500;
            color: #4ade80;
            letter-spacing: 0.03em;
            opacity: 0;
            animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.1s forwards;
        }

        .pulse-dot {
            width: 6px; height: 6px;
            background: #22c55e;
            border-radius: 50%;
            box-shadow: 0 0 8px rgba(34,197,94,0.6);
            animation: blink 1.8s ease-in-out infinite;
        }

        @keyframes blink {
            0%,100% { opacity: 1; }
            50%      { opacity: 0.2; }
        }

        /* ── 스탯 카드 (Double-Bezel) ── */
        .stat-outer {
            width: 100%;
            background: rgba(255,255,255,0.03);
            border: 1px solid rgba(255,255,255,0.06);
            border-radius: 18px;
            padding: 5px;
            opacity: 0;
            transition: transform 0.4s cubic-bezier(0.16,1,0.3,1), box-shadow 0.4s cubic-bezier(0.16,1,0.3,1);
        }

        .stat-outer:nth-child(2) { animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.2s forwards; }
        .stat-outer:nth-child(3) { animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.3s forwards; }
        .stat-outer:nth-child(4) { animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.4s forwards; }

        .stat-outer:hover {
            transform: translateY(-2px);
            box-shadow: 0 12px 40px rgba(0,0,0,0.3);
        }

        .stat-inner {
            background: rgba(255,255,255,0.03);
            border-radius: 14px;
            padding: 18px 20px;
            box-shadow: inset 0 1px 0 rgba(255,255,255,0.06);
        }

        .stat-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 10px;
        }

        .stat-label {
            font-size: 11px;
            font-weight: 500;
            color: #52525b;
            letter-spacing: 0.07em;
            text-transform: uppercase;
        }

        .stat-icon {
            color: #3b6ef5;
            opacity: 0.7;
        }

        .stat-val {
            font-size: 26px;
            font-weight: 700;
            color: #f4f4f5;
            letter-spacing: -0.03em;
            font-variant-numeric: tabular-nums;
            line-height: 1;
            margin-bottom: 6px;
        }

        .stat-change {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            font-size: 11px;
            font-weight: 500;
            color: #4ade80;
        }

        .stat-change.neutral { color: #71717a; }

        .right-label {
            font-size: 11.5px;
            color: #3f3f46;
            text-align: center;
            line-height: 1.7;
            margin-top: 8px;
            word-break: keep-all;
            opacity: 0;
            animation: fadeInUp 0.7s cubic-bezier(0.16,1,0.3,1) 0.5s forwards;
        }

        /* ── 반응형 ── */
        @media (max-width: 768px) {
            .right-panel { display: none; }
            .left-panel { padding: 40px 28px; border-right: none; }
            body { overflow-y: auto; }
        }
    </style>
</head>
<body>

    <!-- 메시 그라디언트 배경 -->
    <div class="mesh-bg">
        <div class="orb orb-1"></div>
        <div class="orb orb-2"></div>
        <div class="orb orb-3"></div>
    </div>

    <div class="layout">

        <!-- ── 왼쪽: 로그인 폼 ── -->
        <div class="left-panel">

            <!-- 브랜드 -->
            <div class="brand">
                <div class="brand-icon">
                    <iconify-icon icon="solar:buildings-2-bold" style="font-size:17px;color:#fff;"></iconify-icon>
                </div>
                <span class="brand-name">ADMIN<span class="brand-dot">.</span>SYS</span>
            </div>

            <div class="form-wrap">

                <!-- 헤딩 -->
                <div class="heading-area">
                    <div class="eyebrow">
                        <iconify-icon icon="solar:shield-check-linear" style="font-size:11px;"></iconify-icon>
                        보안 로그인
                    </div>
                    <h1>다시 오신 것을<br>환영합니다</h1>
                    <p class="sub">관리자 계정으로 로그인하세요</p>
                </div>

                <!-- 에러 메시지 -->
                <% if (errorMsg != null) { %>
                <div class="error-box">
                    <iconify-icon icon="solar:danger-circle-linear" style="font-size:15px;flex-shrink:0;"></iconify-icon>
                    <%= errorMsg %>
                </div>
                <% } %>

                <form action="LoginServlet" method="post">

                    <!-- 아이디 -->
                    <div class="field">
                        <label for="userId">아이디</label>
                        <div class="input-wrap">
                            <span class="input-ico">
                                <iconify-icon icon="solar:user-linear" style="font-size:16px;"></iconify-icon>
                            </span>
                            <input type="text" id="userId" name="userId"
                                   placeholder="사용자 아이디 입력"
                                   value="<%= request.getParameter("userId") != null ? request.getParameter("userId") : "" %>"
                                   required autocomplete="username">
                        </div>
                    </div>

                    <!-- 비밀번호 -->
                    <div class="field">
                        <label for="password">비밀번호</label>
                        <div class="input-wrap">
                            <span class="input-ico">
                                <iconify-icon icon="solar:lock-password-linear" style="font-size:16px;"></iconify-icon>
                            </span>
                            <input type="password" id="password" name="password"
                                   placeholder="비밀번호 입력"
                                   required autocomplete="current-password">
                        </div>
                    </div>

                    <!-- 옵션 -->
                    <div class="options">
                        <label class="check-label">
                            <input type="checkbox" name="rememberMe" value="Y"> 로그인 상태 유지
                        </label>
                        <a class="forgot" href="findPassword.jsp">비밀번호 찾기</a>
                    </div>

                    <!-- 로그인 버튼 -->
                    <div class="btn-wrap">
                        <button type="submit" class="btn">
                            로그인
                            <span class="btn-arrow">
                                <iconify-icon icon="solar:arrow-right-linear" style="font-size:13px;"></iconify-icon>
                            </span>
                        </button>
                    </div>

                </form>

                <div class="footer-copy">© 2026 Bumil Information Admin System.</div>

            </div>
        </div>

        <!-- ── 오른쪽: 시스템 정보 ── -->
        <div class="right-panel">

            <div class="status-tag">
                <span class="pulse-dot"></span>
                시스템 정상 운영 중
            </div>

            <!-- 오늘 접속자 -->
            <div class="stat-outer">
                <div class="stat-inner">
                    <div class="stat-header">
                        <span class="stat-label">오늘 접속자</span>
                        <span class="stat-icon">
                            <iconify-icon icon="solar:users-group-rounded-linear" style="font-size:16px;"></iconify-icon>
                        </span>
                    </div>
                    <div class="stat-val">1,284</div>
                    <div class="stat-change">
                        <iconify-icon icon="solar:alt-arrow-up-linear" style="font-size:11px;"></iconify-icon>
                        어제 대비 +12%
                    </div>
                </div>
            </div>

            <!-- 활성 세션 -->
            <div class="stat-outer">
                <div class="stat-inner">
                    <div class="stat-header">
                        <span class="stat-label">활성 세션</span>
                        <span class="stat-icon">
                            <iconify-icon icon="solar:bolt-linear" style="font-size:16px;"></iconify-icon>
                        </span>
                    </div>
                    <div class="stat-val">47</div>
                    <div class="stat-change neutral">
                        <iconify-icon icon="solar:refresh-linear" style="font-size:11px;"></iconify-icon>
                        실시간 갱신
                    </div>
                </div>
            </div>

            <!-- DB 응답시간 -->
            <div class="stat-outer">
                <div class="stat-inner">
                    <div class="stat-header">
                        <span class="stat-label">DB 응답시간</span>
                        <span class="stat-icon">
                            <iconify-icon icon="solar:database-linear" style="font-size:16px;"></iconify-icon>
                        </span>
                    </div>
                    <div class="stat-val">3.2<span style="font-size:14px;font-weight:500;color:#71717a;margin-left:2px;">ms</span></div>
                    <div class="stat-change">
                        <iconify-icon icon="solar:check-circle-linear" style="font-size:11px;"></iconify-icon>
                        MariaDB 정상
                    </div>
                </div>
            </div>

            <p class="right-label">내부 관리 시스템<br>접근 권한이 있는 계정만 이용 가능합니다</p>

        </div>

    </div>

<script src="js/common.js"></script>
</body>
</html>

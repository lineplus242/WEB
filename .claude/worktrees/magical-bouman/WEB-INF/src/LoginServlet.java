package com.admin.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * 로그인 처리 서블릿
 * - POST /LoginServlet  →  아이디/비밀번호 검증 후 세션 생성
 */
@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    // ── DB 설정 (실제 환경에 맞게 수정) ──────────────────────
    private static final String DB_URL      = "jdbc:mariadb://localhost:3306/admin_db?characterEncoding=UTF-8&serverTimezone=Asia/Seoul";
    private static final String DB_USER     = "root";
    private static final String DB_PASSWORD = "wkd11!#Eod";
    // ────────────────────────────────────────────────────────

    @Override
    public void init() throws ServletException {
        try {
            Class.forName("org.mariadb.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ServletException("MySQL JDBC 드라이버 로드 실패", e);
        }
    }

    /** GET 요청 → 로그인 페이지로 리다이렉트 */
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.sendRedirect("login.jsp");
    }

    /** POST 요청 → 로그인 처리 */
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String userId   = req.getParameter("userId");
        String password = req.getParameter("password");
        String remember = req.getParameter("rememberMe"); // "Y" or null

        // 입력값 기본 검증
        if (isEmpty(userId) || isEmpty(password)) {
            forwardWithError(req, resp, "아이디와 비밀번호를 모두 입력해 주세요.");
            return;
        }

        // DB 인증
        UserInfo user = authenticate(userId, password);

        if (user == null) {
            forwardWithError(req, resp, "아이디 또는 비밀번호가 올바르지 않습니다.");
            return;
        }

        if ("N".equals(user.useYn)) {
            forwardWithError(req, resp, "사용이 정지된 계정입니다. 관리자에게 문의하세요.");
            return;
        }

        // 세션 생성
        HttpSession session = req.getSession(true);
        session.setAttribute("loginUser", user.userId);
        session.setAttribute("loginName", user.userName);
        session.setAttribute("loginRole", user.role);

        // "로그인 상태 유지" 체크 시 세션 유지 시간 연장 (8시간)
        if ("Y".equals(remember)) {
            session.setMaxInactiveInterval(60 * 60 * 8);
        } else {
            session.setMaxInactiveInterval(60 * 30); // 기본 30분
        }

        resp.sendRedirect("main.jsp");
    }

    // ── 내부 메서드 ────────────────────────────────────────

    /**
     * DB에서 사용자 인증
     * 비밀번호는 SHA-256 해시값 비교 (MySQL HEX(SHA2(password,256)) 방식)
     */
    private UserInfo authenticate(String userId, String password) {
        String sql = "SELECT user_id, user_name, role, use_yn "
                   + "FROM tb_user "
                   + "WHERE user_id = ? "
                   + "  AND password = HEX(SHA2(?, 256)) "
                   + "  AND del_yn = 'N'";

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASSWORD);
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, userId);
            ps.setString(2, password);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    UserInfo u = new UserInfo();
                    u.userId   = rs.getString("user_id");
                    u.userName = rs.getString("user_name");
                    u.role     = rs.getString("role");
                    u.useYn    = rs.getString("use_yn");
                    return u;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    private void forwardWithError(HttpServletRequest req, HttpServletResponse resp, String msg)
            throws ServletException, IOException {
        req.setAttribute("errorMsg", msg);
        req.getRequestDispatcher("login.jsp").forward(req, resp);
    }

    private boolean isEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }

    /** 사용자 정보 VO */
    private static class UserInfo {
        String userId;
        String userName;
        String role;
        String useYn;
    }
}

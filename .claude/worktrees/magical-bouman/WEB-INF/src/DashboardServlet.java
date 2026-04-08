package com.admin.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * GET /DashboardServlet?action=stats
 * → JSON 응답 (main.jsp 에서 fetch로 호출)
 */
@WebServlet("/DashboardServlet")
public class DashboardServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mysql://localhost:3306/admin_db?useSSL=false&characterEncoding=UTF-8&serverTimezone=Asia/Seoul";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "your_password";

    @Override
    public void init() throws ServletException {
        try { Class.forName("com.mysql.cj.jdbc.Driver"); }
        catch (ClassNotFoundException e) { throw new ServletException(e); }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("application/json; charset=UTF-8");
        PrintWriter out = resp.getWriter();

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {

            // ── 전체 사용자 수
            long totalUsers = queryLong(conn,
                "SELECT COUNT(*) FROM tb_user WHERE del_yn='N'");

            // ── 이번 달 신규 가입
            long newUsers = queryLong(conn,
                "SELECT COUNT(*) FROM tb_user WHERE del_yn='N' AND DATE_FORMAT(reg_dt,'%Y-%m') = DATE_FORMAT(NOW(),'%Y-%m')");

            // ── 오늘 로그인 성공 횟수
            long todayLogin = queryLong(conn,
                "SELECT COUNT(*) FROM tb_login_log WHERE result='S' AND DATE(login_dt)=CURDATE()");

            // ── 전체 고객사 수
            long totalCustomer = queryLong(conn,
                "SELECT COUNT(*) FROM tb_customer WHERE del_yn='N'");

            // ── 이번 달 신규 고객사
            long newCustomer = queryLong(conn,
                "SELECT COUNT(*) FROM tb_customer WHERE del_yn='N' AND DATE_FORMAT(reg_dt,'%Y-%m')=DATE_FORMAT(NOW(),'%Y-%m')");

            // ── 최근 가입 사용자 5명
            StringBuilder recentUsers = new StringBuilder("[");
            String sqlU = "SELECT user_name, email, use_yn FROM tb_user WHERE del_yn='N' ORDER BY reg_dt DESC LIMIT 5";
            try (PreparedStatement ps = conn.prepareStatement(sqlU);
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) recentUsers.append(",");
                    recentUsers.append("{")
                        .append("\"name\":\"").append(esc(rs.getString("user_name"))).append("\",")
                        .append("\"email\":\"").append(esc(rs.getString("email"))).append("\",")
                        .append("\"useYn\":\"").append(esc(rs.getString("use_yn"))).append("\"")
                        .append("}");
                    first = false;
                }
            }
            recentUsers.append("]");

            // ── 최근 로그인 이력 5건
            StringBuilder loginLogs = new StringBuilder("[");
            String sqlL = "SELECT user_id, ip_addr, result, DATE_FORMAT(login_dt,'%H:%i') AS login_dt "
                        + "FROM tb_login_log ORDER BY log_seq DESC LIMIT 5";
            try (PreparedStatement ps = conn.prepareStatement(sqlL);
                 ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) loginLogs.append(",");
                    loginLogs.append("{")
                        .append("\"userId\":\"").append(esc(rs.getString("user_id"))).append("\",")
                        .append("\"ipAddr\":\"").append(esc(rs.getString("ip_addr"))).append("\",")
                        .append("\"result\":\"").append(esc(rs.getString("result"))).append("\",")
                        .append("\"loginDt\":\"").append(esc(rs.getString("login_dt"))).append("\"")
                        .append("}");
                    first = false;
                }
            }
            loginLogs.append("]");

            // ── JSON 출력
            out.print("{");
            out.print("\"totalUsers\":"   + totalUsers   + ",");
            out.print("\"newUsers\":"     + newUsers     + ",");
            out.print("\"todayLogin\":"   + todayLogin   + ",");
            out.print("\"totalCustomer\":"+ totalCustomer + ",");
            out.print("\"newCustomer\":"  + newCustomer  + ",");
            out.print("\"recentUsers\":"  + recentUsers  + ",");
            out.print("\"loginLogs\":"    + loginLogs);
            out.print("}");

        } catch (Exception e) {
            resp.setStatus(500);
            out.print("{\"error\":\"" + esc(e.getMessage()) + "\"}");
        }
    }

    private long queryLong(Connection conn, String sql) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getLong(1) : 0L;
        }
    }

    /** JSON 문자열 이스케이프 */
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r");
    }
}

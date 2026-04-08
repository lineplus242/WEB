package com.admin.servlet;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * 사용자 관리 서블릿
 *
 *  GET  /UserServlet?action=list        → user_list.jsp  (admin only)
 *  GET  /UserServlet?action=form        → user_form.jsp  (admin only, 신규)
 *  GET  /UserServlet?action=form&userSeq=N → user_form.jsp (admin only, 수정)
 *  POST /UserServlet?action=save        → 신규 등록      (admin only)
 *  POST /UserServlet?action=update      → 정보 수정      (admin only)
 *  POST /UserServlet?action=delete      → 소프트 삭제    (admin only)
 *  GET  /UserServlet?action=changePw    → change_password.jsp (본인)
 *  POST /UserServlet?action=changePw    → 비밀번호 변경 처리  (본인)
 */
@WebServlet("/UserServlet")
public class UserServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mariadb://localhost:3306/admin_db?characterEncoding=UTF-8&serverTimezone=Asia/Seoul";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "wkd11!#Eod";

    @Override
    public void init() throws ServletException {
        try { Class.forName("org.mariadb.jdbc.Driver"); }
        catch (ClassNotFoundException e) { throw new ServletException(e); }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        if (!checkLogin(req, resp)) return;

        String action = nvl(req.getParameter("action"), "list");

        switch (action) {
            case "list"     -> doList(req, resp);
            case "form"     -> doForm(req, resp);
            case "changePw" -> { req.getRequestDispatcher("/user/change_password.jsp").forward(req, resp); }
            default         -> resp.sendRedirect("UserServlet?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        if (!checkLogin(req, resp)) return;

        String action = nvl(req.getParameter("action"), "");

        switch (action) {
            case "save"     -> doSave(req, resp);
            case "update"   -> doUpdate(req, resp);
            case "delete"   -> doDelete(req, resp);
            case "changePw" -> doChangePw(req, resp);
            default         -> resp.sendRedirect("UserServlet?action=list");
        }
    }

    // ── 목록 조회 (admin only) ──────────────────────────────
    private void doList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!isAdmin(req)) { resp.sendError(403, "권한이 없습니다."); return; }

        String keyword = nvl(req.getParameter("keyword"), "");
        String pageStr = nvl(req.getParameter("page"), "1");
        int page     = Integer.parseInt(pageStr);
        int pageSize = 15;
        int offset   = (page - 1) * pageSize;

        List<UserVO> list = new ArrayList<>();
        int totalCnt = 0;

        String whereKw = keyword.isEmpty() ? "" : " AND (user_id LIKE ? OR user_name LIKE ?)";

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {

            String cntSql = "SELECT COUNT(*) FROM tb_user WHERE del_yn='N'" + whereKw;
            try (PreparedStatement ps = conn.prepareStatement(cntSql)) {
                if (!keyword.isEmpty()) { String k = "%" + keyword + "%"; ps.setString(1, k); ps.setString(2, k); }
                ResultSet rs = ps.executeQuery();
                if (rs.next()) totalCnt = rs.getInt(1);
            }

            String listSql = "SELECT user_seq, user_id, user_name, role, use_yn, reg_dt "
                           + "FROM tb_user WHERE del_yn='N'" + whereKw
                           + " ORDER BY user_seq DESC LIMIT ? OFFSET ?";
            try (PreparedStatement ps = conn.prepareStatement(listSql)) {
                int idx = 1;
                if (!keyword.isEmpty()) { String k = "%" + keyword + "%"; ps.setString(idx++, k); ps.setString(idx++, k); }
                ps.setInt(idx++, pageSize);
                ps.setInt(idx,   offset);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    UserVO u = new UserVO();
                    u.userSeq  = rs.getInt("user_seq");
                    u.userId   = rs.getString("user_id");
                    u.userName = rs.getString("user_name");
                    u.role     = rs.getString("role");
                    u.useYn    = rs.getString("use_yn");
                    u.regDt    = rs.getString("reg_dt");
                    list.add(u);
                }
            }
        } catch (Exception e) {
            req.setAttribute("dbError", e.getMessage());
        }

        int totalPages = (int) Math.ceil((double) totalCnt / pageSize);
        req.setAttribute("list",       list);
        req.setAttribute("totalCnt",   totalCnt);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("page",       page);
        req.setAttribute("keyword",    keyword);
        req.getRequestDispatcher("/user/user_list.jsp").forward(req, resp);
    }

    // ── 등록/수정 폼 (admin only) ──────────────────────────
    private void doForm(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!isAdmin(req)) { resp.sendError(403, "권한이 없습니다."); return; }

        String seqStr = req.getParameter("userSeq");
        if (seqStr != null && !seqStr.isEmpty()) {
            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
                String sql = "SELECT user_seq, user_id, user_name, role, use_yn FROM tb_user WHERE user_seq=? AND del_yn='N'";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, Integer.parseInt(seqStr));
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) {
                        UserVO u = new UserVO();
                        u.userSeq  = rs.getInt("user_seq");
                        u.userId   = rs.getString("user_id");
                        u.userName = rs.getString("user_name");
                        u.role     = rs.getString("role");
                        u.useYn    = rs.getString("use_yn");
                        req.setAttribute("user", u);
                        req.setAttribute("isAdminAccount", "admin".equals(u.userId));
                    }
                }
            } catch (Exception e) {
                req.setAttribute("dbError", e.getMessage());
            }
        }
        req.getRequestDispatcher("/user/user_form.jsp").forward(req, resp);
    }

    // ── 신규 등록 (admin only) ─────────────────────────────
    private void doSave(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!isAdmin(req)) { resp.sendError(403, "권한이 없습니다."); return; }

        String userId   = nvl(req.getParameter("userId"), "");
        String userName = nvl(req.getParameter("userName"), "");
        String password = nvl(req.getParameter("password"), "");
        String role     = nvl(req.getParameter("role"), "USER");
        String useYn    = nvl(req.getParameter("useYn"), "Y");
        String loginUser = (String) req.getSession().getAttribute("loginUser");

        if (userId.isEmpty() || password.isEmpty() || userName.isEmpty()) {
            req.setAttribute("errorMsg", "아이디, 이름, 비밀번호는 필수 입력입니다.");
            doForm(req, resp);
            return;
        }

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            // 중복 ID 체크
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM tb_user WHERE user_id=? AND del_yn='N'")) {
                ps.setString(1, userId);
                ResultSet rs = ps.executeQuery();
                if (rs.next() && rs.getInt(1) > 0) {
                    req.setAttribute("errorMsg", "이미 사용 중인 아이디입니다.");
                    doForm(req, resp);
                    return;
                }
            }

            String sql = "INSERT INTO tb_user (user_id, user_name, password, role, use_yn, del_yn) "
                       + "VALUES (?, ?, HEX(SHA2(?,256)), ?, ?, 'N')";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, userId);
                ps.setString(2, userName);
                ps.setString(3, password);
                ps.setString(4, role);
                ps.setString(5, useYn);
                ps.executeUpdate();
            }
        } catch (Exception e) {
            req.setAttribute("errorMsg", "저장 실패: " + e.getMessage());
            doForm(req, resp);
            return;
        }
        resp.sendRedirect("UserServlet?action=list");
    }

    // ── 수정 저장 (admin only) ─────────────────────────────
    private void doUpdate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!isAdmin(req)) { resp.sendError(403, "권한이 없습니다."); return; }

        String seqStr   = req.getParameter("userSeq");
        String userName = nvl(req.getParameter("userName"), "");
        String role     = nvl(req.getParameter("role"), "USER");
        String useYn    = nvl(req.getParameter("useYn"), "Y");
        String newPw    = req.getParameter("password");

        // 대상 계정의 user_id 조회
        String targetUserId = "";
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            try (PreparedStatement ps = conn.prepareStatement("SELECT user_id FROM tb_user WHERE user_seq=?")) {
                ps.setInt(1, Integer.parseInt(seqStr));
                ResultSet rs = ps.executeQuery();
                if (rs.next()) targetUserId = rs.getString("user_id");
            }
        } catch (Exception e) { /* 무시 */ }

        boolean isAdminAccount = "admin".equals(targetUserId);

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            if (isAdminAccount) {
                // admin 계정: 비밀번호만 변경 가능
                if (newPw != null && !newPw.trim().isEmpty()) {
                    String sql = "UPDATE tb_user SET password=HEX(SHA2(?,256)) WHERE user_seq=? AND del_yn='N'";
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setString(1, newPw);
                        ps.setInt(2, Integer.parseInt(seqStr));
                        ps.executeUpdate();
                    }
                }
            } else if (newPw != null && !newPw.trim().isEmpty()) {
                // 비밀번호 포함 업데이트
                String sql = "UPDATE tb_user SET user_name=?, role=?, use_yn=?, password=HEX(SHA2(?,256)) WHERE user_seq=? AND del_yn='N'";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, userName);
                    ps.setString(2, role);
                    ps.setString(3, useYn);
                    ps.setString(4, newPw);
                    ps.setInt(5, Integer.parseInt(seqStr));
                    ps.executeUpdate();
                }
            } else {
                // 비밀번호 제외 업데이트
                String sql = "UPDATE tb_user SET user_name=?, role=?, use_yn=? WHERE user_seq=? AND del_yn='N'";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, userName);
                    ps.setString(2, role);
                    ps.setString(3, useYn);
                    ps.setInt(4, Integer.parseInt(seqStr));
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) {
            req.setAttribute("errorMsg", "수정 실패: " + e.getMessage());
            doForm(req, resp);
            return;
        }
        resp.sendRedirect("UserServlet?action=list");
    }

    // ── 삭제 (admin only) ─────────────────────────────────
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!isAdmin(req)) { resp.sendError(403, "권한이 없습니다."); return; }

        String loginUser = (String) req.getSession().getAttribute("loginUser");
        String seqStr    = req.getParameter("userSeq");

        // 본인 계정 삭제 방지
        String targetId = "";
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            try (PreparedStatement ps = conn.prepareStatement("SELECT user_id FROM tb_user WHERE user_seq=?")) {
                ps.setInt(1, Integer.parseInt(seqStr));
                ResultSet rs = ps.executeQuery();
                if (rs.next()) targetId = rs.getString("user_id");
            }
            if (loginUser.equals(targetId)) {
                resp.sendRedirect("UserServlet?action=list&error=self");
                return;
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE tb_user SET del_yn='Y' WHERE user_seq=?")) {
                ps.setInt(1, Integer.parseInt(seqStr));
                ps.executeUpdate();
            }
        } catch (Exception e) {
            // 실패해도 목록으로
        }
        resp.sendRedirect("UserServlet?action=list");
    }

    // ── 비밀번호 변경 (본인) ───────────────────────────────
    private void doChangePw(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String loginUser = (String) req.getSession().getAttribute("loginUser");
        String curPw     = nvl(req.getParameter("currentPw"), "");
        String newPw     = nvl(req.getParameter("newPw"), "");
        String confirmPw = nvl(req.getParameter("confirmPw"), "");

        if (curPw.isEmpty() || newPw.isEmpty() || confirmPw.isEmpty()) {
            req.setAttribute("errorMsg", "모든 항목을 입력해 주세요.");
            req.getRequestDispatcher("/user/change_password.jsp").forward(req, resp);
            return;
        }

        if (!newPw.equals(confirmPw)) {
            req.setAttribute("errorMsg", "새 비밀번호가 일치하지 않습니다.");
            req.getRequestDispatcher("/user/change_password.jsp").forward(req, resp);
            return;
        }

        if (newPw.length() < 6) {
            req.setAttribute("errorMsg", "비밀번호는 6자 이상이어야 합니다.");
            req.getRequestDispatcher("/user/change_password.jsp").forward(req, resp);
            return;
        }

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            // 현재 비밀번호 확인
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(*) FROM tb_user WHERE user_id=? AND password=HEX(SHA2(?,256)) AND del_yn='N'")) {
                ps.setString(1, loginUser);
                ps.setString(2, curPw);
                ResultSet rs = ps.executeQuery();
                if (!rs.next() || rs.getInt(1) == 0) {
                    req.setAttribute("errorMsg", "현재 비밀번호가 올바르지 않습니다.");
                    req.getRequestDispatcher("/user/change_password.jsp").forward(req, resp);
                    return;
                }
            }
            // 비밀번호 변경
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE tb_user SET password=HEX(SHA2(?,256)) WHERE user_id=? AND del_yn='N'")) {
                ps.setString(1, newPw);
                ps.setString(2, loginUser);
                ps.executeUpdate();
            }
        } catch (Exception e) {
            req.setAttribute("errorMsg", "변경 실패: " + e.getMessage());
            req.getRequestDispatcher("/user/change_password.jsp").forward(req, resp);
            return;
        }

        req.setAttribute("successMsg", "비밀번호가 성공적으로 변경되었습니다.");
        req.getRequestDispatcher("/user/change_password.jsp").forward(req, resp);
    }

    // ── 공통 유틸 ──────────────────────────────────────────
    private boolean checkLogin(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (req.getSession().getAttribute("loginUser") == null) {
            resp.sendRedirect(req.getContextPath() + "/login.jsp");
            return false;
        }
        return true;
    }

    private boolean isAdmin(HttpServletRequest req) {
        String role = (String) req.getSession().getAttribute("loginRole");
        return "ADMIN".equals(role);
    }

    private String nvl(String s, String def) { return (s == null || s.trim().isEmpty()) ? def : s.trim(); }

    // ── Value Object ──────────────────────────────────────
    public static class UserVO {
        public int    userSeq;
        public String userId, userName, role, useYn, regDt;
    }
}

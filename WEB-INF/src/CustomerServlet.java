package com.admin.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * 고객사 관리 서블릿
 *
 *  GET  /CustomerServlet?action=list   → customer_list.jsp 포워드
 *  GET  /CustomerServlet?action=form   → customer_form.jsp 포워드 (신규)
 *  GET  /CustomerServlet?action=form&custSeq=N → customer_form.jsp 포워드 (수정)
 *  POST /CustomerServlet?action=save   → 신규 저장 후 목록 리다이렉트
 *  POST /CustomerServlet?action=update → 수정 저장 후 목록 리다이렉트
 *  POST /CustomerServlet?action=delete → 삭제 후 목록 리다이렉트
 */
@WebServlet("/CustomerServlet")
public class CustomerServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mariadb://localhost:3306/admin_db?characterEncoding=UTF-8&serverTimezone=Asia/Seoul";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "wkd11!#Eod";

    @Override
    public void init() throws ServletException {
        try { Class.forName("org.mariadb.jdbc.Driver"); }
        catch (ClassNotFoundException e) { throw new ServletException(e); }
    }

    // ── GET ──────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String action = nvl(req.getParameter("action"), "list");

        if ("list".equals(action)) {
            doList(req, resp);
        } else if ("form".equals(action)) {
            doForm(req, resp);
        } else {
            resp.sendRedirect("CustomerServlet?action=list");
        }
    }

    // ── POST ─────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String action = nvl(req.getParameter("action"), "");

        switch (action) {
            case "save"   -> doSave(req, resp);
            case "update" -> doUpdate(req, resp);
            case "delete" -> doDelete(req, resp);
            default       -> resp.sendRedirect("CustomerServlet?action=list");
        }
    }

    // ─────────────────────────────────────────────────────
    // 목록 조회
    // ─────────────────────────────────────────────────────
    private void doList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String keyword = nvl(req.getParameter("keyword"), "");
        String status  = nvl(req.getParameter("status"),  "");
        String pageStr = nvl(req.getParameter("page"),    "1");
        int page     = Integer.parseInt(pageStr);
        int pageSize = 10;
        int offset   = (page - 1) * pageSize;

        List<CustomerVO> list  = new ArrayList<>();
        int totalCnt = 0;

        StringBuilder where = new StringBuilder("WHERE c.del_yn='N'");
        if (!keyword.isEmpty()) where.append(" AND (c.cust_name LIKE ? OR c.manager_name LIKE ? OR c.cust_code LIKE ?)");
        if (!status.isEmpty())  where.append(" AND c.status = ?");

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {

            // 전체 건수
            String cntSql = "SELECT COUNT(*) FROM tb_customer c " + where;
            try (PreparedStatement ps = conn.prepareStatement(cntSql)) {
                int idx = 1;
                if (!keyword.isEmpty()) { String k = "%" + keyword + "%"; ps.setString(idx++, k); ps.setString(idx++, k); ps.setString(idx++, k); }
                if (!status.isEmpty())  ps.setString(idx, status);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) totalCnt = rs.getInt(1);
            }

            // 목록
            String listSql = "SELECT c.cust_seq, c.cust_code, c.cust_name, c.status "
                           + "FROM tb_customer c " + where
                           + " ORDER BY c.cust_seq DESC LIMIT ? OFFSET ?";
            try (PreparedStatement ps = conn.prepareStatement(listSql)) {
                int idx = 1;
                if (!keyword.isEmpty()) { String k = "%" + keyword + "%"; ps.setString(idx++, k); ps.setString(idx++, k); ps.setString(idx++, k); }
                if (!status.isEmpty())  ps.setString(idx++, status);
                ps.setInt(idx++, pageSize);
                ps.setInt(idx,   offset);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    CustomerVO v = new CustomerVO();
                    v.custSeq  = rs.getInt("cust_seq");
                    v.custCode = rs.getString("cust_code");
                    v.custName = rs.getString("cust_name");
                    v.status   = rs.getString("status");
                    list.add(v);
                }
            }
            // 목록용 첫 번째 담당자 이름/연락처 로드
            if (!list.isEmpty()) {
                StringBuilder inSql = new StringBuilder("SELECT cust_seq, manager_name, manager_tel FROM tb_customer_manager WHERE cust_seq IN (");
                for (int i = 0; i < list.size(); i++) { inSql.append(i==0?"?":",?"); }
                inSql.append(") ORDER BY cust_seq, sort_order, manager_seq");
                try (PreparedStatement ps = conn.prepareStatement(inSql.toString())) {
                    for (int i = 0; i < list.size(); i++) ps.setInt(i+1, list.get(i).custSeq);
                    ResultSet rs = ps.executeQuery();
                    java.util.Map<Integer, CustomerVO> map = new java.util.LinkedHashMap<>();
                    for (CustomerVO v : list) map.put(v.custSeq, v);
                    while (rs.next()) {
                        int seq = rs.getInt("cust_seq");
                        CustomerVO v = map.get(seq);
                        if (v != null && v.managers.isEmpty()) {
                            ManagerVO m = new ManagerVO();
                            m.name = rs.getString("manager_name");
                            m.tel  = rs.getString("manager_tel");
                            v.managers.add(m);
                        }
                    }
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
        req.setAttribute("status",     status);

        req.getRequestDispatcher("/customer/customer_list.jsp").forward(req, resp);
    }

    // ─────────────────────────────────────────────────────
    // 등록/수정 폼
    // ─────────────────────────────────────────────────────
    private void doForm(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String seqStr = req.getParameter("custSeq");

        if (seqStr != null && !seqStr.isEmpty()) {
            // 수정: DB에서 기존 데이터 로드
            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
                String sql = "SELECT * FROM tb_customer WHERE cust_seq=? AND del_yn='N'";
                CustomerVO v = null;
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, Integer.parseInt(seqStr));
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) {
                        v = new CustomerVO();
                        v.custSeq       = rs.getInt("cust_seq");
                        v.custCode      = rs.getString("cust_code");
                        v.custName      = rs.getString("cust_name");
                        v.bizNo         = rs.getString("biz_no");
                        v.ceoName       = rs.getString("ceo_name");
                        v.address       = rs.getString("address");
                        v.phone  = rs.getString("phone");
                        v.email  = rs.getString("email");
                        v.status = rs.getString("status");
                        v.memo          = rs.getString("memo");
                    }
                }
                if (v != null) {
                    // 담당자 목록 로드
                    String mgrSql = "SELECT manager_name, manager_tel, manager_email FROM tb_customer_manager WHERE cust_seq=? ORDER BY sort_order, manager_seq";
                    try (PreparedStatement ps = conn.prepareStatement(mgrSql)) {
                        ps.setInt(1, v.custSeq);
                        ResultSet rs = ps.executeQuery();
                        while (rs.next()) {
                            ManagerVO m = new ManagerVO();
                            m.name  = rs.getString("manager_name");
                            m.tel   = rs.getString("manager_tel");
                            m.email = rs.getString("manager_email");
                            v.managers.add(m);
                        }
                    }
                    req.setAttribute("customer", v);
                }
            } catch (Exception e) {
                req.setAttribute("dbError", e.getMessage());
            }
        }

        req.getRequestDispatcher("/customer/customer_form.jsp").forward(req, resp);
    }

    // ─────────────────────────────────────────────────────
    // 신규 저장
    // ─────────────────────────────────────────────────────
    private void doSave(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String loginUser = (String) req.getSession().getAttribute("loginUser");

        String sql = "INSERT INTO tb_customer "
                   + "(cust_code, cust_name, biz_no, ceo_name, address, phone, email, "
                   + " status, memo, reg_user) "
                   + "VALUES (?,?,?,?,?,?,?,?,?,?)";

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            conn.setAutoCommit(false);
            int newCustSeq;
            try {
                // 고객사 코드 자동 생성 CUST-NNNN
                long nextSeq = queryLong(conn, "SELECT IFNULL(MAX(cust_seq),0)+1 FROM tb_customer");
                String custCode = String.format("CUST-%04d", nextSeq);

                try (PreparedStatement ps = conn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, custCode);
                    ps.setString(2, req.getParameter("custName"));
                    ps.setString(3, req.getParameter("bizNo"));
                    ps.setString(4, req.getParameter("ceoName"));
                    ps.setString(5, req.getParameter("address"));
                    ps.setString(6, req.getParameter("phone"));
                    ps.setString(7, req.getParameter("email"));
                    ps.setString(8, nvl(req.getParameter("status"), "ACTIVE"));
                    ps.setString(9, req.getParameter("memo"));
                    ps.setString(10, loginUser);
                    ps.executeUpdate();
                    ResultSet gk = ps.getGeneratedKeys();
                    newCustSeq = gk.next() ? gk.getInt(1) : 0;
                }

                // 담당자 저장
                saveManagers(conn, newCustSeq, req);
                conn.commit();
            } catch (Exception e) {
                conn.rollback();
                throw e;
            }
        } catch (Exception e) {
            req.setAttribute("errorMsg", "저장 실패: " + e.getMessage());
            doForm(req, resp);
            return;
        }
        resp.sendRedirect("CustomerServlet?action=list");
    }

    // ─────────────────────────────────────────────────────
    // 수정 저장
    // ─────────────────────────────────────────────────────
    private void doUpdate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String loginUser = (String) req.getSession().getAttribute("loginUser");

        String sql = "UPDATE tb_customer SET "
                   + "cust_name=?, biz_no=?, ceo_name=?, address=?, phone=?, email=?, "
                   + "status=?, memo=?, upd_user=? "
                   + "WHERE cust_seq=? AND del_yn='N'";

        int custSeq = Integer.parseInt(req.getParameter("custSeq"));

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, req.getParameter("custName"));
                    ps.setString(2, req.getParameter("bizNo"));
                    ps.setString(3, req.getParameter("ceoName"));
                    ps.setString(4, req.getParameter("address"));
                    ps.setString(5, req.getParameter("phone"));
                    ps.setString(6, req.getParameter("email"));
                    ps.setString(7, nvl(req.getParameter("status"), "ACTIVE"));
                    ps.setString(8, req.getParameter("memo"));
                    ps.setString(9, loginUser);
                    ps.setInt(10,   custSeq);
                    ps.executeUpdate();
                }
                // 담당자 교체 (기존 삭제 후 재삽입)
                try (PreparedStatement ps = conn.prepareStatement("DELETE FROM tb_customer_manager WHERE cust_seq=?")) {
                    ps.setInt(1, custSeq); ps.executeUpdate();
                }
                saveManagers(conn, custSeq, req);
                conn.commit();
            } catch (Exception e) {
                conn.rollback();
                throw e;
            }
        } catch (Exception e) {
            req.setAttribute("errorMsg", "수정 실패: " + e.getMessage());
            doForm(req, resp);
            return;
        }
        resp.sendRedirect("CustomerServlet?action=list");
    }

    // ─────────────────────────────────────────────────────
    // 삭제 (소프트 딜리트)
    // ─────────────────────────────────────────────────────
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String loginUser = (String) req.getSession().getAttribute("loginUser");
        String seqStr    = req.getParameter("custSeq");

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                 "UPDATE tb_customer SET del_yn='Y', upd_user=? WHERE cust_seq=?")) {

            ps.setString(1, loginUser);
            ps.setInt(2, Integer.parseInt(seqStr));
            ps.executeUpdate();

        } catch (Exception e) {
            // 실패해도 목록으로 이동
        }
        resp.sendRedirect("CustomerServlet?action=list");
    }

    // ── 담당자 일괄 저장 ──────────────────────────────────
    private void saveManagers(Connection conn, int custSeq, HttpServletRequest req) throws Exception {
        String[] names  = req.getParameterValues("managerName");
        String[] tels   = req.getParameterValues("managerTel");
        String[] emails = req.getParameterValues("managerEmail");
        if (names == null) return;
        String mgrSql = "INSERT INTO tb_customer_manager (cust_seq, manager_name, manager_tel, manager_email, sort_order) VALUES (?,?,?,?,?)";
        try (PreparedStatement ps = conn.prepareStatement(mgrSql)) {
            for (int i = 0; i < names.length; i++) {
                String name = names[i] == null ? "" : names[i].trim();
                if (name.isEmpty()) continue;
                ps.setInt(1, custSeq);
                ps.setString(2, name);
                ps.setString(3, (tels   != null && i < tels.length)   ? tels[i]   : null);
                ps.setString(4, (emails != null && i < emails.length)  ? emails[i] : null);
                ps.setInt(5, i);
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    // ── 유틸 ──────────────────────────────────────────────
    private long queryLong(Connection conn, String sql) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getLong(1) : 0L;
        }
    }

    private String nvl(String s, String def) { return (s == null || s.isEmpty()) ? def : s; }
    private String emptyToNull(String s)      { return (s == null || s.isEmpty()) ? null : s; }
    private long   parseLong(String s)        { try { return Long.parseLong(s.replaceAll("[^0-9]","")); } catch(Exception e){ return 0L; } }

    // ── Value Objects ─────────────────────────────────────
    public static class CustomerVO {
        public int    custSeq;
        public String custCode, custName, bizNo, ceoName, address;
        public String phone, email;
        public String status, memo;
        public List<ManagerVO> managers = new ArrayList<>();
    }

    public static class ManagerVO {
        public String name, tel, email;
    }
}

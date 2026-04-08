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

    private static final String DB_URL  = "jdbc:mysql://localhost:3306/admin_db?useSSL=false&characterEncoding=UTF-8&serverTimezone=Asia/Seoul";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "your_password";

    @Override
    public void init() throws ServletException {
        try { Class.forName("com.mysql.cj.jdbc.Driver"); }
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
            String listSql = "SELECT c.cust_seq, c.cust_code, c.cust_name, c.industry, "
                           + "c.manager_name, c.manager_tel, c.contract_start, c.contract_end, "
                           + "c.service_type, c.contract_amt, c.status "
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
                    v.custSeq       = rs.getInt("cust_seq");
                    v.custCode      = rs.getString("cust_code");
                    v.custName      = rs.getString("cust_name");
                    v.industry      = rs.getString("industry");
                    v.managerName   = rs.getString("manager_name");
                    v.managerTel    = rs.getString("manager_tel");
                    v.contractStart = rs.getString("contract_start");
                    v.contractEnd   = rs.getString("contract_end");
                    v.serviceType   = rs.getString("service_type");
                    v.contractAmt   = rs.getLong("contract_amt");
                    v.status        = rs.getString("status");
                    list.add(v);
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
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, Integer.parseInt(seqStr));
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) {
                        CustomerVO v = new CustomerVO();
                        v.custSeq       = rs.getInt("cust_seq");
                        v.custCode      = rs.getString("cust_code");
                        v.custName      = rs.getString("cust_name");
                        v.bizNo         = rs.getString("biz_no");
                        v.ceoName       = rs.getString("ceo_name");
                        v.industry      = rs.getString("industry");
                        v.address       = rs.getString("address");
                        v.phone         = rs.getString("phone");
                        v.email         = rs.getString("email");
                        v.managerName   = rs.getString("manager_name");
                        v.managerTel    = rs.getString("manager_tel");
                        v.managerEmail  = rs.getString("manager_email");
                        v.contractStart = rs.getString("contract_start");
                        v.contractEnd   = rs.getString("contract_end");
                        v.serviceType   = rs.getString("service_type");
                        v.contractAmt   = rs.getLong("contract_amt");
                        v.status        = rs.getString("status");
                        v.memo          = rs.getString("memo");
                        req.setAttribute("customer", v);
                    }
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
                   + "(cust_code, cust_name, biz_no, ceo_name, industry, address, phone, email, "
                   + " manager_name, manager_tel, manager_email, "
                   + " contract_start, contract_end, service_type, contract_amt, status, memo, reg_user) "
                   + "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(sql)) {

            // 고객사 코드 자동 생성 CUST-NNNN
            long nextSeq = queryLong(conn, "SELECT IFNULL(MAX(cust_seq),0)+1 FROM tb_customer");
            String custCode = String.format("CUST-%04d", nextSeq);

            ps.setString(1,  custCode);
            ps.setString(2,  req.getParameter("custName"));
            ps.setString(3,  req.getParameter("bizNo"));
            ps.setString(4,  req.getParameter("ceoName"));
            ps.setString(5,  req.getParameter("industry"));
            ps.setString(6,  req.getParameter("address"));
            ps.setString(7,  req.getParameter("phone"));
            ps.setString(8,  req.getParameter("email"));
            ps.setString(9,  req.getParameter("managerName"));
            ps.setString(10, req.getParameter("managerTel"));
            ps.setString(11, req.getParameter("managerEmail"));
            ps.setString(12, emptyToNull(req.getParameter("contractStart")));
            ps.setString(13, emptyToNull(req.getParameter("contractEnd")));
            ps.setString(14, req.getParameter("serviceType"));
            ps.setLong(15,   parseLong(req.getParameter("contractAmt")));
            ps.setString(16, nvl(req.getParameter("status"), "ACTIVE"));
            ps.setString(17, req.getParameter("memo"));
            ps.setString(18, loginUser);
            ps.executeUpdate();

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
                   + "cust_name=?, biz_no=?, ceo_name=?, industry=?, address=?, phone=?, email=?, "
                   + "manager_name=?, manager_tel=?, manager_email=?, "
                   + "contract_start=?, contract_end=?, service_type=?, contract_amt=?, "
                   + "status=?, memo=?, upd_user=? "
                   + "WHERE cust_seq=? AND del_yn='N'";

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1,  req.getParameter("custName"));
            ps.setString(2,  req.getParameter("bizNo"));
            ps.setString(3,  req.getParameter("ceoName"));
            ps.setString(4,  req.getParameter("industry"));
            ps.setString(5,  req.getParameter("address"));
            ps.setString(6,  req.getParameter("phone"));
            ps.setString(7,  req.getParameter("email"));
            ps.setString(8,  req.getParameter("managerName"));
            ps.setString(9,  req.getParameter("managerTel"));
            ps.setString(10, req.getParameter("managerEmail"));
            ps.setString(11, emptyToNull(req.getParameter("contractStart")));
            ps.setString(12, emptyToNull(req.getParameter("contractEnd")));
            ps.setString(13, req.getParameter("serviceType"));
            ps.setLong(14,   parseLong(req.getParameter("contractAmt")));
            ps.setString(15, nvl(req.getParameter("status"), "ACTIVE"));
            ps.setString(16, req.getParameter("memo"));
            ps.setString(17, loginUser);
            ps.setInt(18,    Integer.parseInt(req.getParameter("custSeq")));
            ps.executeUpdate();

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

    // ── Value Object ─────────────────────────────────────
    public static class CustomerVO {
        public int    custSeq;
        public String custCode, custName, bizNo, ceoName, industry, address;
        public String phone, email;
        public String managerName, managerTel, managerEmail;
        public String contractStart, contractEnd, serviceType;
        public long   contractAmt;
        public String status, memo;
    }
}

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

/**
 * 고객사 상세 + 사업정보 + IT자산 관리 서블릿
 *
 *  GET  /CustomerDetailServlet?action=detail&custSeq=N  → 상세 페이지
 *  POST /CustomerDetailServlet?action=projectSave       → 사업 저장
 *  POST /CustomerDetailServlet?action=projectDelete     → 사업 삭제
 *  POST /CustomerDetailServlet?action=assetSave         → 자산 저장
 *  POST /CustomerDetailServlet?action=assetDelete       → 자산 삭제
 */
@WebServlet("/CustomerDetailServlet")
public class CustomerDetailServlet extends HttpServlet {

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
        String action   = nvl(req.getParameter("action"), "detail");
        String custSeqStr = req.getParameter("custSeq");

        if ("detail".equals(action) && custSeqStr != null) {
            doDetail(req, resp, Integer.parseInt(custSeqStr));
        } else {
            resp.sendRedirect("CustomerServlet?action=list");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = nvl(req.getParameter("action"), "");
        switch (action) {
            case "projectSave"   -> doProjectSave(req, resp);
            case "projectDelete" -> doProjectDelete(req, resp);
            case "assetSave"     -> doAssetSave(req, resp);
            case "assetDelete"   -> doAssetDelete(req, resp);
            default -> resp.sendRedirect("CustomerServlet?action=list");
        }
    }

    // ─────────────────────────────────────────────────────
    // 상세 페이지
    // ─────────────────────────────────────────────────────
    private void doDetail(HttpServletRequest req, HttpServletResponse resp, int custSeq)
            throws ServletException, IOException {

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {

            // 고객사 기본정보
            CustomerVO customer = null;
            String custSql = "SELECT * FROM tb_customer WHERE cust_seq=? AND del_yn='N'";
            try (PreparedStatement ps = conn.prepareStatement(custSql)) {
                ps.setInt(1, custSeq);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    customer = new CustomerVO();
                    customer.custSeq    = rs.getInt("cust_seq");
                    customer.custCode   = rs.getString("cust_code");
                    customer.custName   = rs.getString("cust_name");
                    customer.bizNo      = rs.getString("biz_no");
                    customer.ceoName    = rs.getString("ceo_name");
                    customer.industry   = rs.getString("industry");
                    customer.address    = rs.getString("address");
                    customer.phone      = rs.getString("phone");
                    customer.email      = rs.getString("email");
                    customer.managerName  = rs.getString("manager_name");
                    customer.managerTel   = rs.getString("manager_tel");
                    customer.managerEmail = rs.getString("manager_email");
                    customer.contractStart = rs.getString("contract_start");
                    customer.contractEnd   = rs.getString("contract_end");
                    customer.serviceType   = rs.getString("service_type");
                    customer.contractAmt   = rs.getLong("contract_amt");
                    customer.status        = rs.getString("status");
                    customer.memo          = rs.getString("memo");
                }
            }

            if (customer == null) {
                resp.sendRedirect("CustomerServlet?action=list");
                return;
            }

            // 사업정보 목록
            List<ProjectVO> projects = new ArrayList<>();
            String projSql = "SELECT * FROM tb_project WHERE cust_seq=? AND del_yn='N' ORDER BY proj_seq DESC";
            try (PreparedStatement ps = conn.prepareStatement(projSql)) {
                ps.setInt(1, custSeq);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    ProjectVO p = new ProjectVO();
                    p.projSeq      = rs.getInt("proj_seq");
                    p.projName     = rs.getString("proj_name");
                    p.contractAmt  = rs.getLong("contract_amt");
                    p.contractStart = rs.getString("contract_start");
                    p.contractEnd   = rs.getString("contract_end");
                    p.status        = rs.getString("status");
                    p.managerName   = rs.getString("manager_name");
                    p.memo          = rs.getString("memo");
                    projects.add(p);
                }
            }

            // IT 자산 목록
            List<AssetVO> assets = new ArrayList<>();
            String assetSql = "SELECT * FROM tb_asset WHERE cust_seq=? AND del_yn='N' ORDER BY asset_type, asset_seq DESC";
            try (PreparedStatement ps = conn.prepareStatement(assetSql)) {
                ps.setInt(1, custSeq);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    AssetVO a = new AssetVO();
                    a.assetSeq  = rs.getInt("asset_seq");
                    a.assetType = rs.getString("asset_type");
                    a.assetName = rs.getString("asset_name");
                    a.model     = rs.getString("model");
                    a.ipAddr    = rs.getString("ip_addr");
                    a.osInfo    = rs.getString("os_info");
                    a.location  = rs.getString("location");
                    a.status    = rs.getString("status");
                    a.purchaseDt = rs.getString("purchase_dt");
                    a.expireDt   = rs.getString("expire_dt");
                    a.memo       = rs.getString("memo");
                    assets.add(a);
                }
            }

            req.setAttribute("customer", customer);
            req.setAttribute("projects", projects);
            req.setAttribute("assets",   assets);

        } catch (Exception e) {
            req.setAttribute("dbError", e.getMessage());
        }

        req.getRequestDispatcher("/customer/customer_detail.jsp").forward(req, resp);
    }

    // ─────────────────────────────────────────────────────
    // 사업 저장 (신규/수정)
    // ─────────────────────────────────────────────────────
    private void doProjectSave(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String loginUser  = (String) req.getSession().getAttribute("loginUser");
        String custSeqStr = req.getParameter("custSeq");
        String projSeqStr = req.getParameter("projSeq");
        int custSeq = Integer.parseInt(custSeqStr);

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            if (projSeqStr == null || projSeqStr.isEmpty()) {
                // 신규
                String sql = "INSERT INTO tb_project (cust_seq, proj_name, contract_amt, contract_start, contract_end, status, manager_name, memo, reg_user) VALUES (?,?,?,?,?,?,?,?,?)";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, custSeq);
                    ps.setString(2, req.getParameter("projName"));
                    ps.setLong(3,   parseLong(req.getParameter("contractAmt")));
                    ps.setString(4, emptyToNull(req.getParameter("contractStart")));
                    ps.setString(5, emptyToNull(req.getParameter("contractEnd")));
                    ps.setString(6, nvl(req.getParameter("status"), "ACTIVE"));
                    ps.setString(7, req.getParameter("managerName"));
                    ps.setString(8, req.getParameter("memo"));
                    ps.setString(9, loginUser);
                    ps.executeUpdate();
                }
            } else {
                // 수정
                String sql = "UPDATE tb_project SET proj_name=?, contract_amt=?, contract_start=?, contract_end=?, status=?, manager_name=?, memo=?, upd_user=? WHERE proj_seq=?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, req.getParameter("projName"));
                    ps.setLong(2,   parseLong(req.getParameter("contractAmt")));
                    ps.setString(3, emptyToNull(req.getParameter("contractStart")));
                    ps.setString(4, emptyToNull(req.getParameter("contractEnd")));
                    ps.setString(5, nvl(req.getParameter("status"), "ACTIVE"));
                    ps.setString(6, req.getParameter("managerName"));
                    ps.setString(7, req.getParameter("memo"));
                    ps.setString(8, loginUser);
                    ps.setInt(9,    Integer.parseInt(projSeqStr));
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        resp.sendRedirect("CustomerDetailServlet?action=detail&custSeq=" + custSeq + "&tab=project");
    }

    // ─────────────────────────────────────────────────────
    // 사업 삭제
    // ─────────────────────────────────────────────────────
    private void doProjectDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String loginUser  = (String) req.getSession().getAttribute("loginUser");
        String custSeqStr = req.getParameter("custSeq");
        String projSeqStr = req.getParameter("projSeq");

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                 "UPDATE tb_project SET del_yn='Y', upd_user=? WHERE proj_seq=?")) {
            ps.setString(1, loginUser);
            ps.setInt(2, Integer.parseInt(projSeqStr));
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
        resp.sendRedirect("CustomerDetailServlet?action=detail&custSeq=" + custSeqStr + "&tab=project");
    }

    // ─────────────────────────────────────────────────────
    // 자산 저장 (신규/수정)
    // ─────────────────────────────────────────────────────
    private void doAssetSave(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String loginUser  = (String) req.getSession().getAttribute("loginUser");
        String custSeqStr = req.getParameter("custSeq");
        String assetSeqStr = req.getParameter("assetSeq");
        int custSeq = Integer.parseInt(custSeqStr);

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            if (assetSeqStr == null || assetSeqStr.isEmpty()) {
                // 신규
                String sql = "INSERT INTO tb_asset (cust_seq, asset_type, asset_name, model, ip_addr, os_info, location, status, purchase_dt, expire_dt, memo, reg_user) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1,    custSeq);
                    ps.setString(2, nvl(req.getParameter("assetType"), "ETC"));
                    ps.setString(3, req.getParameter("assetName"));
                    ps.setString(4, req.getParameter("model"));
                    ps.setString(5, req.getParameter("ipAddr"));
                    ps.setString(6, req.getParameter("osInfo"));
                    ps.setString(7, req.getParameter("location"));
                    ps.setString(8, nvl(req.getParameter("status"), "ACTIVE"));
                    ps.setString(9, emptyToNull(req.getParameter("purchaseDt")));
                    ps.setString(10, emptyToNull(req.getParameter("expireDt")));
                    ps.setString(11, req.getParameter("memo"));
                    ps.setString(12, loginUser);
                    ps.executeUpdate();
                }
            } else {
                // 수정
                String sql = "UPDATE tb_asset SET asset_type=?, asset_name=?, model=?, ip_addr=?, os_info=?, location=?, status=?, purchase_dt=?, expire_dt=?, memo=?, upd_user=? WHERE asset_seq=?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, nvl(req.getParameter("assetType"), "ETC"));
                    ps.setString(2, req.getParameter("assetName"));
                    ps.setString(3, req.getParameter("model"));
                    ps.setString(4, req.getParameter("ipAddr"));
                    ps.setString(5, req.getParameter("osInfo"));
                    ps.setString(6, req.getParameter("location"));
                    ps.setString(7, nvl(req.getParameter("status"), "ACTIVE"));
                    ps.setString(8, emptyToNull(req.getParameter("purchaseDt")));
                    ps.setString(9, emptyToNull(req.getParameter("expireDt")));
                    ps.setString(10, req.getParameter("memo"));
                    ps.setString(11, loginUser);
                    ps.setInt(12,   Integer.parseInt(assetSeqStr));
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        resp.sendRedirect("CustomerDetailServlet?action=detail&custSeq=" + custSeq + "&tab=asset");
    }

    // ─────────────────────────────────────────────────────
    // 자산 삭제
    // ─────────────────────────────────────────────────────
    private void doAssetDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String loginUser   = (String) req.getSession().getAttribute("loginUser");
        String custSeqStr  = req.getParameter("custSeq");
        String assetSeqStr = req.getParameter("assetSeq");

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                 "UPDATE tb_asset SET del_yn='Y', upd_user=? WHERE asset_seq=?")) {
            ps.setString(1, loginUser);
            ps.setInt(2, Integer.parseInt(assetSeqStr));
            ps.executeUpdate();
        } catch (Exception e) {
            e.printStackTrace();
        }
        resp.sendRedirect("CustomerDetailServlet?action=detail&custSeq=" + custSeqStr + "&tab=asset");
    }

    // ── 유틸 ──────────────────────────────────────────────
    private String nvl(String s, String def) { return (s == null || s.isEmpty()) ? def : s; }
    private String emptyToNull(String s)     { return (s == null || s.isEmpty()) ? null : s; }
    private long   parseLong(String s)       { try { return Long.parseLong(s.replaceAll("[^0-9]", "")); } catch (Exception e) { return 0L; } }

    // ── Value Objects ─────────────────────────────────────
    public static class CustomerVO {
        public int    custSeq;
        public String custCode, custName, bizNo, ceoName, industry, address;
        public String phone, email;
        public String managerName, managerTel, managerEmail;
        public String contractStart, contractEnd, serviceType;
        public long   contractAmt;
        public String status, memo;
    }

    public static class ProjectVO {
        public int    projSeq;
        public String projName;
        public long   contractAmt;
        public String contractStart, contractEnd, status, managerName, memo;
    }

    public static class AssetVO {
        public int    assetSeq;
        public String assetType, assetName, model, ipAddr, osInfo, location;
        public String status, purchaseDt, expireDt, memo;
    }
}

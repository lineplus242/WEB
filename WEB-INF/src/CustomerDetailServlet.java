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
 * 고객사 상세 + 사업정보 + IT자산 + 랙 실장도 관리 서블릿
 *
 *  GET  /CustomerDetailServlet?action=detail&custSeq=N  → 상세 페이지
 *  POST /CustomerDetailServlet?action=projectSave       → 사업 저장
 *  POST /CustomerDetailServlet?action=projectDelete     → 사업 삭제
 *  POST /CustomerDetailServlet?action=assetSave         → 자산 저장
 *  POST /CustomerDetailServlet?action=assetDelete       → 자산 삭제
 *  POST /CustomerDetailServlet?action=rackSave          → 랙 저장
 *  POST /CustomerDetailServlet?action=rackDelete        → 랙 삭제
 *  POST /CustomerDetailServlet?action=rackUnitSave      → 랙 유닛 저장
 *  POST /CustomerDetailServlet?action=rackUnitDelete    → 랙 유닛 삭제
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
            case "assetSave"       -> doAssetSave(req, resp);
            case "assetDelete"     -> doAssetDelete(req, resp);
            case "rackSave"        -> doRackSave(req, resp);
            case "rackDelete"      -> doRackDelete(req, resp);
            case "rackUnitSave"    -> doRackUnitSave(req, resp);
            case "rackUnitDelete"  -> doRackUnitDelete(req, resp);
            case "rackReorder"     -> doRackReorder(req, resp);
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
                    customer.address    = rs.getString("address");
                    customer.phone  = rs.getString("phone");
                    customer.email  = rs.getString("email");
                    customer.status = rs.getString("status");
                    customer.memo          = rs.getString("memo");
                }
            }

            if (customer == null) {
                resp.sendRedirect("CustomerServlet?action=list");
                return;
            }

            // 담당자 목록 로드
            String mgrSql = "SELECT manager_name, manager_tel, manager_email FROM tb_customer_manager WHERE cust_seq=? ORDER BY sort_order, manager_seq";
            try (PreparedStatement ps = conn.prepareStatement(mgrSql)) {
                ps.setInt(1, custSeq);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    ManagerVO m = new ManagerVO();
                    m.name  = rs.getString("manager_name");
                    m.tel   = rs.getString("manager_tel");
                    m.email = rs.getString("manager_email");
                    customer.managers.add(m);
                }
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
            // 자산 전체 로드 후 부모-자식 순서로 정렬
            List<AssetVO> allAssets = new ArrayList<>();
            String assetSql = "SELECT * FROM tb_asset WHERE cust_seq=? AND del_yn='N' ORDER BY parent_seq IS NOT NULL, parent_seq, asset_seq";
            try (PreparedStatement ps = conn.prepareStatement(assetSql)) {
                ps.setInt(1, custSeq);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    AssetVO a = new AssetVO();
                    a.assetSeq   = rs.getInt("asset_seq");
                    int ps2      = rs.getInt("parent_seq");
                    a.parentSeq  = rs.wasNull() ? 0 : ps2;
                    a.assetType  = rs.getString("asset_type");
                    a.assetRole  = nvl(rs.getString("asset_role"), "PHYSICAL");
                    a.virtType   = rs.getString("virt_type");
                    a.assetName  = rs.getString("asset_name");
                    a.maker      = rs.getString("maker");
                    a.model      = rs.getString("model");
                    a.hostname   = rs.getString("hostname");
                    a.ipAddr     = rs.getString("ip_addr");
                    a.disk       = rs.getString("disk");
                    a.cpu        = rs.getString("cpu");
                    a.memory     = rs.getString("memory");
                    a.osInfo     = rs.getString("os_info");
                    a.location   = rs.getString("location");
                    a.status     = rs.getString("status");
                    a.purchaseDt   = rs.getString("purchase_dt");
                    a.memo         = rs.getString("memo");
                    a.accountInfo  = rs.getString("account_info");
                    int su = rs.getInt("size_u");
                    a.sizeU = rs.wasNull() ? null : su;
                    allAssets.add(a);
                }
            }
            // 부모-자식 순서 정렬: 최상위 → 각 부모 바로 아래 자식들
            java.util.Map<Integer, List<AssetVO>> childMap = new java.util.LinkedHashMap<>();
            List<AssetVO> topLevel = new ArrayList<>();
            for (AssetVO a : allAssets) {
                if (a.parentSeq == 0) topLevel.add(a);
                else childMap.computeIfAbsent(a.parentSeq, k -> new ArrayList<>()).add(a);
            }
            List<AssetVO> assets = new ArrayList<>();
            for (AssetVO parent : topLevel) {
                List<AssetVO> children = childMap.getOrDefault(parent.assetSeq, new ArrayList<>());
                parent.childCount = children.size();
                assets.add(parent);
                assets.addAll(children);
            }
            // 부모가 삭제된 고아 자식도 포함
            childMap.forEach((pSeq, children) -> {
                boolean parentExists = topLevel.stream().anyMatch(a -> a.assetSeq == pSeq);
                if (!parentExists) assets.addAll(children);
            });

            // 랙 목록
            List<RackVO> racks = new ArrayList<>();
            String rackSql = "SELECT rack_seq, rack_name, total_u, location, memo, sort_order FROM tb_rack WHERE cust_seq=? AND del_yn='N' ORDER BY sort_order, rack_seq";
            try (PreparedStatement ps = conn.prepareStatement(rackSql)) {
                ps.setInt(1, custSeq);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    RackVO r = new RackVO();
                    r.rackSeq   = rs.getInt("rack_seq");
                    r.rackName  = rs.getString("rack_name");
                    r.totalU    = rs.getInt("total_u");
                    r.location  = rs.getString("location");
                    r.memo      = rs.getString("memo");
                    r.sortOrder = rs.getInt("sort_order");
                    racks.add(r);
                }
            }
            String unitSql = "SELECT unit_seq, side, start_u, size_u, device_name, device_type, ip_addr, memo FROM tb_rack_unit WHERE rack_seq=? ORDER BY side, start_u";
            for (RackVO r : racks) {
                try (PreparedStatement ps = conn.prepareStatement(unitSql)) {
                    ps.setInt(1, r.rackSeq);
                    ResultSet rs = ps.executeQuery();
                    while (rs.next()) {
                        RackUnitVO u = new RackUnitVO();
                        u.unitSeq    = rs.getInt("unit_seq");
                        u.side       = rs.getString("side");
                        u.startU     = rs.getInt("start_u");
                        u.sizeU      = rs.getInt("size_u");
                        u.deviceName = rs.getString("device_name");
                        u.deviceType = rs.getString("device_type");
                        u.ipAddr     = rs.getString("ip_addr");
                        u.memo       = rs.getString("memo");
                        r.units.add(u);
                    }
                }
            }

            req.setAttribute("customer", customer);
            req.setAttribute("projects", projects);
            req.setAttribute("assets",   assets);
            req.setAttribute("racks",    racks);

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
                String sql = "INSERT INTO tb_asset (cust_seq, parent_seq, asset_type, asset_role, virt_type, asset_name, maker, model, size_u, hostname, ip_addr, disk, cpu, memory, os_info, location, status, purchase_dt, account_info, memo, reg_user) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1,     custSeq);
                    String pSeqStr = req.getParameter("parentSeq");
                    if (pSeqStr == null || pSeqStr.isEmpty()) ps.setNull(2, java.sql.Types.INTEGER);
                    else ps.setInt(2, Integer.parseInt(pSeqStr));
                    ps.setString(3,  nvl(req.getParameter("assetType"), "SERVER"));
                    ps.setString(4,  nvl(req.getParameter("assetRole"), "PHYSICAL"));
                    ps.setString(5,  emptyToNull(req.getParameter("virtType")));
                    ps.setString(6,  req.getParameter("assetName"));
                    ps.setString(7,  emptyToNull(req.getParameter("maker")));
                    ps.setString(8,  emptyToNull(req.getParameter("model")));
                    String suStr = req.getParameter("sizeU");
                    if (suStr == null || suStr.isEmpty()) ps.setNull(9, java.sql.Types.INTEGER);
                    else ps.setInt(9, Integer.parseInt(suStr));
                    ps.setString(10, emptyToNull(req.getParameter("hostname")));
                    ps.setString(11, emptyToNull(req.getParameter("ipAddr")));
                    ps.setString(12, emptyToNull(req.getParameter("disk")));
                    ps.setString(13, emptyToNull(req.getParameter("cpu")));
                    ps.setString(14, emptyToNull(req.getParameter("memory")));
                    ps.setString(15, emptyToNull(req.getParameter("osInfo")));
                    ps.setString(16, emptyToNull(req.getParameter("location")));
                    ps.setString(17, nvl(req.getParameter("status"), "ACTIVE"));
                    ps.setString(18, emptyToNull(req.getParameter("purchaseDt")));
                    ps.setString(19, emptyToNull(req.getParameter("accountInfo")));
                    ps.setString(20, emptyToNull(req.getParameter("memo")));
                    ps.setString(21, loginUser);
                    ps.executeUpdate();
                }
            } else {
                // 수정
                String sql = "UPDATE tb_asset SET parent_seq=?, asset_type=?, asset_role=?, virt_type=?, asset_name=?, maker=?, model=?, size_u=?, hostname=?, ip_addr=?, disk=?, cpu=?, memory=?, os_info=?, location=?, status=?, purchase_dt=?, account_info=?, memo=?, upd_user=? WHERE asset_seq=?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    String pSeqStr2 = req.getParameter("parentSeq");
                    if (pSeqStr2 == null || pSeqStr2.isEmpty()) ps.setNull(1, java.sql.Types.INTEGER);
                    else ps.setInt(1, Integer.parseInt(pSeqStr2));
                    ps.setString(2,  nvl(req.getParameter("assetType"), "SERVER"));
                    ps.setString(3,  nvl(req.getParameter("assetRole"), "PHYSICAL"));
                    ps.setString(4,  emptyToNull(req.getParameter("virtType")));
                    ps.setString(5,  req.getParameter("assetName"));
                    ps.setString(6,  emptyToNull(req.getParameter("maker")));
                    ps.setString(7,  emptyToNull(req.getParameter("model")));
                    String suStr2 = req.getParameter("sizeU");
                    if (suStr2 == null || suStr2.isEmpty()) ps.setNull(8, java.sql.Types.INTEGER);
                    else ps.setInt(8, Integer.parseInt(suStr2));
                    ps.setString(9,  emptyToNull(req.getParameter("hostname")));
                    ps.setString(10, emptyToNull(req.getParameter("ipAddr")));
                    ps.setString(11, emptyToNull(req.getParameter("disk")));
                    ps.setString(12, emptyToNull(req.getParameter("cpu")));
                    ps.setString(13, emptyToNull(req.getParameter("memory")));
                    ps.setString(14, emptyToNull(req.getParameter("osInfo")));
                    ps.setString(15, emptyToNull(req.getParameter("location")));
                    ps.setString(16, nvl(req.getParameter("status"), "ACTIVE"));
                    ps.setString(17, emptyToNull(req.getParameter("purchaseDt")));
                    ps.setString(18, emptyToNull(req.getParameter("accountInfo")));
                    ps.setString(19, emptyToNull(req.getParameter("memo")));
                    ps.setString(20, loginUser);
                    ps.setInt(21,    Integer.parseInt(assetSeqStr));
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

    // ─────────────────────────────────────────────────────
    // 랙 저장 (신규/수정)
    // ─────────────────────────────────────────────────────
    private void doRackSave(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String custSeqStr = req.getParameter("custSeq");
        String rackSeqStr = req.getParameter("rackSeq");
        int custSeq = Integer.parseInt(custSeqStr);

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            if (rackSeqStr == null || rackSeqStr.isEmpty()) {
                // sort_order = 현재 고객사의 최대값 + 1
                int nextOrder = 0;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COALESCE(MAX(sort_order),0)+1 FROM tb_rack WHERE cust_seq=? AND del_yn='N'")) {
                    ps.setInt(1, custSeq);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) nextOrder = rs.getInt(1);
                }
                String sql = "INSERT INTO tb_rack (cust_seq, rack_name, total_u, location, memo, sort_order) VALUES (?,?,?,?,?,?)";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, custSeq);
                    ps.setString(2, req.getParameter("rackName"));
                    ps.setInt(3, parseIntDef(req.getParameter("totalU"), 42));
                    ps.setString(4, emptyToNull(req.getParameter("location")));
                    ps.setString(5, emptyToNull(req.getParameter("memo")));
                    ps.setInt(6, nextOrder);
                    ps.executeUpdate();
                }
            } else {
                String sql = "UPDATE tb_rack SET rack_name=?, total_u=?, location=?, memo=? WHERE rack_seq=?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, req.getParameter("rackName"));
                    ps.setInt(2, parseIntDef(req.getParameter("totalU"), 42));
                    ps.setString(3, emptyToNull(req.getParameter("location")));
                    ps.setString(4, emptyToNull(req.getParameter("memo")));
                    ps.setInt(5, Integer.parseInt(rackSeqStr));
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        resp.sendRedirect("CustomerDetailServlet?action=detail&custSeq=" + custSeq + "&tab=asset&sub=rack");
    }

    // ─────────────────────────────────────────────────────
    // 랙 삭제
    // ─────────────────────────────────────────────────────
    private void doRackDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String custSeqStr = req.getParameter("custSeq");
        String rackSeqStr = req.getParameter("rackSeq");

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            // 랙 유닛 먼저 삭제
            try (PreparedStatement ps = conn.prepareStatement("DELETE FROM tb_rack_unit WHERE rack_seq=?")) {
                ps.setInt(1, Integer.parseInt(rackSeqStr));
                ps.executeUpdate();
            }
            try (PreparedStatement ps = conn.prepareStatement("UPDATE tb_rack SET del_yn='Y' WHERE rack_seq=?")) {
                ps.setInt(1, Integer.parseInt(rackSeqStr));
                ps.executeUpdate();
            }
        } catch (Exception e) { e.printStackTrace(); }
        resp.sendRedirect("CustomerDetailServlet?action=detail&custSeq=" + custSeqStr + "&tab=asset&sub=rack");
    }

    // ─────────────────────────────────────────────────────
    // 랙 유닛 저장 (신규/수정)
    // ─────────────────────────────────────────────────────
    private void doRackUnitSave(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String custSeqStr = req.getParameter("custSeq");
        String unitSeqStr = req.getParameter("unitSeq");
        String rackSeqStr = req.getParameter("rackSeq");

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            if (unitSeqStr == null || unitSeqStr.isEmpty()) {
                String sql = "INSERT INTO tb_rack_unit (rack_seq, side, start_u, size_u, device_name, device_type, ip_addr, memo) VALUES (?,?,?,?,?,?,?,?)";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, Integer.parseInt(rackSeqStr));
                    ps.setString(2, nvl(req.getParameter("side"), "F"));
                    ps.setInt(3, Integer.parseInt(req.getParameter("startU")));
                    ps.setInt(4, parseIntDef(req.getParameter("sizeU"), 1));
                    ps.setString(5, req.getParameter("deviceName"));
                    ps.setString(6, nvl(req.getParameter("deviceType"), "SERVER"));
                    ps.setString(7, emptyToNull(req.getParameter("ipAddr")));
                    ps.setString(8, emptyToNull(req.getParameter("memo")));
                    ps.executeUpdate();
                }
            } else {
                String sql = "UPDATE tb_rack_unit SET side=?, start_u=?, size_u=?, device_name=?, device_type=?, ip_addr=?, memo=? WHERE unit_seq=?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setString(1, nvl(req.getParameter("side"), "F"));
                    ps.setInt(2, Integer.parseInt(req.getParameter("startU")));
                    ps.setInt(3, parseIntDef(req.getParameter("sizeU"), 1));
                    ps.setString(4, req.getParameter("deviceName"));
                    ps.setString(5, nvl(req.getParameter("deviceType"), "SERVER"));
                    ps.setString(6, emptyToNull(req.getParameter("ipAddr")));
                    ps.setString(7, emptyToNull(req.getParameter("memo")));
                    ps.setInt(8, Integer.parseInt(unitSeqStr));
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        resp.sendRedirect("CustomerDetailServlet?action=detail&custSeq=" + custSeqStr + "&tab=asset&sub=rack");
    }

    // ─────────────────────────────────────────────────────
    // 랙 유닛 삭제
    // ─────────────────────────────────────────────────────
    private void doRackUnitDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String custSeqStr = req.getParameter("custSeq");
        String unitSeqStr = req.getParameter("unitSeq");

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement("DELETE FROM tb_rack_unit WHERE unit_seq=?")) {
            ps.setInt(1, Integer.parseInt(unitSeqStr));
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
        resp.sendRedirect("CustomerDetailServlet?action=detail&custSeq=" + custSeqStr + "&tab=asset&sub=rack");
    }

    // ─────────────────────────────────────────────────────
    // 랙 순서 변경
    // ─────────────────────────────────────────────────────
    private void doRackReorder(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String custSeqStr = req.getParameter("custSeq");
        String order      = req.getParameter("order"); // "rackSeq1,rackSeq2,..."
        if (order == null || order.isEmpty()) {
            resp.sendRedirect("CustomerDetailServlet?action=detail&custSeq=" + custSeqStr + "&tab=asset&sub=rack");
            return;
        }
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            String[] seqs = order.split(",");
            for (int i = 0; i < seqs.length; i++) {
                String s = seqs[i].trim();
                if (s.isEmpty()) continue;
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE tb_rack SET sort_order=? WHERE rack_seq=? AND cust_seq=?")) {
                    ps.setInt(1, i);
                    ps.setInt(2, Integer.parseInt(s));
                    ps.setInt(3, Integer.parseInt(custSeqStr));
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        resp.sendRedirect("CustomerDetailServlet?action=detail&custSeq=" + custSeqStr + "&tab=asset&sub=rack");
    }

    // ── 유틸 ──────────────────────────────────────────────
    private String nvl(String s, String def)     { return (s == null || s.isEmpty()) ? def : s; }
    private String emptyToNull(String s)         { return (s == null || s.isEmpty()) ? null : s; }
    private long   parseLong(String s)           { try { return Long.parseLong(s.replaceAll("[^0-9]", "")); } catch (Exception e) { return 0L; } }
    private int    parseIntDef(String s, int def) { try { return Integer.parseInt(s.trim()); } catch (Exception e) { return def; } }

    // ── Value Objects ─────────────────────────────────────
    public static class CustomerVO {
        public int    custSeq;
        public String custCode, custName, bizNo, ceoName, address;
        public String phone, email;
        public String contractStart, contractEnd;
        public long   contractAmt;
        public String status, memo;
        public List<ManagerVO> managers = new ArrayList<>();
    }

    public static class ManagerVO {
        public String name, tel, email;
    }

    public static class ProjectVO {
        public int    projSeq;
        public String projName;
        public long   contractAmt;
        public String contractStart, contractEnd, status, managerName, memo;
    }

    public static class AssetVO {
        public int    assetSeq, parentSeq;   // parentSeq=0 이면 최상위
        public String assetType, assetRole, virtType;
        public String assetName, maker, model, hostname, ipAddr;
        public String disk, cpu, memory, osInfo, location;
        public String status, purchaseDt, memo, accountInfo;
        public Integer sizeU;
        public int childCount;  // DB 저장 안 함, 로드 시 계산
    }

    public static class RackVO {
        public int    rackSeq, totalU, sortOrder;
        public String rackName, location, memo;
        public List<RackUnitVO> units = new ArrayList<>();
    }

    public static class RackUnitVO {
        public int    unitSeq, startU, sizeU;
        public String side, deviceName, deviceType, ipAddr, memo;
    }
}

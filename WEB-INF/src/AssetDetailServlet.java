package com.admin.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.*;
import java.nio.file.*;
import java.sql.*;
import java.util.*;

/**
 * 장비 상세 페이지 서블릿
 *
 *  GET  /AssetDetailServlet?assetSeq=N          → 상세 페이지
 *  POST /AssetDetailServlet?action=photoUpload  → 사진 업로드
 *  POST /AssetDetailServlet?action=photoDelete  → 사진 삭제
 *  POST /AssetDetailServlet?action=portSave     → 포트맵 저장 (신규/수정)
 *  POST /AssetDetailServlet?action=portDelete   → 포트맵 삭제
 */
@WebServlet("/AssetDetailServlet")
@MultipartConfig(maxFileSize = 10_000_000, maxRequestSize = 15_000_000)
public class AssetDetailServlet extends HttpServlet {

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
        String assetSeqStr = req.getParameter("assetSeq");
        if (assetSeqStr == null || assetSeqStr.isEmpty()) {
            resp.sendRedirect("CustomerServlet?action=list");
            return;
        }
        doDetail(req, resp, Integer.parseInt(assetSeqStr));
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = nvl(req.getParameter("action"), "");
        switch (action) {
            case "photoUpload" -> doPhotoUpload(req, resp);
            case "photoDelete" -> doPhotoDelete(req, resp);
            case "portSave"    -> doPortSave(req, resp);
            case "portDelete"  -> doPortDelete(req, resp);
            default            -> resp.sendRedirect("CustomerServlet?action=list");
        }
    }

    // ─────────────────────────────────────────────────────
    // 상세 조회
    // ─────────────────────────────────────────────────────
    private void doDetail(HttpServletRequest req, HttpServletResponse resp, int assetSeq)
            throws ServletException, IOException {

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {

            // 자산 기본정보 + 고객사명
            AssetDetailVO asset = null;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT a.*, c.cust_name FROM tb_asset a JOIN tb_customer c ON a.cust_seq = c.cust_seq WHERE a.asset_seq=? AND a.del_yn='N'")) {
                ps.setInt(1, assetSeq);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    asset = new AssetDetailVO();
                    asset.assetSeq    = rs.getInt("asset_seq");
                    int ps2           = rs.getInt("parent_seq");
                    asset.parentSeq   = rs.wasNull() ? 0 : ps2;
                    asset.custSeq     = rs.getInt("cust_seq");
                    asset.custName    = rs.getString("cust_name");
                    asset.assetType   = rs.getString("asset_type");
                    asset.assetRole   = nvl(rs.getString("asset_role"), "PHYSICAL");
                    asset.virtType    = rs.getString("virt_type");
                    asset.assetName   = rs.getString("asset_name");
                    asset.maker       = rs.getString("maker");
                    asset.model       = rs.getString("model");
                    int su            = rs.getInt("size_u");
                    asset.sizeU       = rs.wasNull() ? null : su;
                    asset.hostname    = rs.getString("hostname");
                    asset.ipAddr      = rs.getString("ip_addr");
                    asset.disk        = rs.getString("disk");
                    asset.cpu         = rs.getString("cpu");
                    asset.memory      = rs.getString("memory");
                    asset.osInfo      = rs.getString("os_info");
                    asset.location    = rs.getString("location");
                    asset.status      = rs.getString("status");
                    asset.purchaseDt  = rs.getString("purchase_dt");
                    asset.expireDt    = rs.getString("expire_dt");
                    asset.accountInfo = rs.getString("account_info");
                    asset.memo        = rs.getString("memo");
                }
            }
            if (asset == null) {
                resp.sendRedirect("CustomerServlet?action=list");
                return;
            }

            // 사진 (전면/후면)
            PhotoVO frontPhoto = null, rearPhoto = null;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT * FROM tb_asset_photo WHERE asset_seq=? ORDER BY photo_seq")) {
                ps.setInt(1, assetSeq);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    PhotoVO ph = new PhotoVO();
                    ph.photoSeq = rs.getInt("photo_seq");
                    ph.side     = rs.getString("side");
                    ph.filePath = rs.getString("file_path");
                    ph.origName = rs.getString("orig_name");
                    if ("F".equals(ph.side)) frontPhoto = ph;
                    else                     rearPhoto  = ph;
                }
            }

            // 통합 포트맵 (출발 + 수신 병합)
            List<PortMapVO> unifiedPortMap = new ArrayList<>();

            // 출발 포트맵 (이 장비 → 상대)
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT p.*, a.asset_name AS dst_asset_name FROM tb_port_map p " +
                    "LEFT JOIN tb_asset a ON p.dst_asset_seq = a.asset_seq WHERE p.asset_seq=? ORDER BY p.sort_order, p.port_seq")) {
                ps.setInt(1, assetSeq);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    PortMapVO pm      = new PortMapVO();
                    pm.portSeq        = rs.getInt("port_seq");
                    pm.ownerAssetSeq  = assetSeq;
                    pm.srcPort        = rs.getString("src_port");
                    pm.dstDeviceName  = rs.getString("dst_device_name");
                    pm.dstPort        = rs.getString("dst_port");
                    pm.dstAssetName   = rs.getString("dst_asset_name");
                    int dSeq          = rs.getInt("dst_asset_seq");
                    pm.dstAssetSeq    = rs.wasNull() ? null : dSeq;
                    pm.cableType      = rs.getString("cable_type");
                    pm.cableColor     = rs.getString("cable_color");
                    pm.memo           = rs.getString("memo");
                    pm.sortOrder      = rs.getInt("sort_order");
                    pm.direction      = "OUT";
                    pm.myPort         = pm.srcPort;
                    pm.peerPort       = pm.dstPort;
                    pm.peerAssetSeq   = pm.dstAssetSeq;
                    pm.peerAssetName  = pm.dstAssetName != null ? pm.dstAssetName : pm.dstDeviceName;
                    pm.peerDeviceName = pm.dstDeviceName;
                    pm.ownerAssetName = asset.assetName;
                    unifiedPortMap.add(pm);
                }
            }

            // 수신 포트맵 (상대 → 이 장비)
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT p.*, a.asset_name AS src_asset_name FROM tb_port_map p " +
                    "JOIN tb_asset a ON p.asset_seq = a.asset_seq " +
                    "WHERE p.dst_asset_seq=? AND a.del_yn='N' ORDER BY p.sort_order, p.port_seq")) {
                ps.setInt(1, assetSeq);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    PortMapVO pm      = new PortMapVO();
                    pm.portSeq        = rs.getInt("port_seq");
                    pm.ownerAssetSeq  = rs.getInt("asset_seq");
                    pm.srcAssetName   = rs.getString("src_asset_name");
                    pm.srcPort        = rs.getString("src_port");
                    pm.dstPort        = rs.getString("dst_port");
                    pm.cableType      = rs.getString("cable_type");
                    pm.cableColor     = rs.getString("cable_color");
                    pm.memo           = rs.getString("memo");
                    pm.sortOrder      = rs.getInt("sort_order");
                    pm.direction      = "IN";
                    pm.myPort         = pm.dstPort;
                    pm.peerPort       = pm.srcPort;
                    pm.peerAssetSeq   = pm.ownerAssetSeq;
                    pm.peerAssetName  = pm.srcAssetName;
                    pm.ownerAssetName = pm.srcAssetName;
                    unifiedPortMap.add(pm);
                }
            }

            // 내 포트명 기준 알파벳 정렬
            unifiedPortMap.sort((a2, b2) -> {
                String pa = a2.myPort != null ? a2.myPort : "";
                String pb = b2.myPort != null ? b2.myPort : "";
                return pa.compareToIgnoreCase(pb);
            });

            // 같은 고객사 자산 (도착지 자동완성용)
            List<SimpleAssetVO> siblingAssets = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT asset_seq, asset_name FROM tb_asset WHERE cust_seq=? AND del_yn='N' AND asset_seq != ? ORDER BY asset_name")) {
                ps.setInt(1, asset.custSeq);
                ps.setInt(2, assetSeq);
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    SimpleAssetVO sa = new SimpleAssetVO();
                    sa.assetSeq  = rs.getInt("asset_seq");
                    sa.assetName = rs.getString("asset_name");
                    siblingAssets.add(sa);
                }
            }

            req.setAttribute("asset",           asset);
            req.setAttribute("frontPhoto",      frontPhoto);
            req.setAttribute("rearPhoto",       rearPhoto);
            req.setAttribute("unifiedPortMap",  unifiedPortMap);
            req.setAttribute("siblingAssets",   siblingAssets);

        } catch (Exception e) {
            req.setAttribute("dbError", e.getMessage());
        }

        String uploadErr = req.getParameter("uploadErr");
        if (uploadErr != null && !uploadErr.isEmpty()) {
            req.setAttribute("dbError", "사진 업로드 오류: " + uploadErr);
        }

        req.getRequestDispatcher("/asset/asset_detail.jsp").forward(req, resp);
    }

    // ─────────────────────────────────────────────────────
    // 사진 업로드
    // ─────────────────────────────────────────────────────
    private void doPhotoUpload(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        int assetSeq = Integer.parseInt(req.getParameter("assetSeq"));
        String side  = "B".equals(req.getParameter("side")) ? "B" : "F";

        try {
            Part filePart = req.getPart("photoFile");
            if (filePart == null || filePart.getSize() == 0) {
                resp.sendRedirect("AssetDetailServlet?assetSeq=" + assetSeq);
                return;
            }
            String origName  = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
            String ext       = origName.contains(".") ? origName.substring(origName.lastIndexOf(".")).toLowerCase() : ".jpg";
            String savedName = side + "_" + System.currentTimeMillis() + ext;
            String uploadDir = getServletContext().getRealPath("/upload/asset/" + assetSeq + "/");
            File dir = new File(uploadDir);
            if (!dir.exists() && !dir.mkdirs()) {
                throw new IOException("업로드 디렉터리 생성 실패: " + uploadDir + " (권한 확인 필요)");
            }

            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
                // 기존 파일 삭제
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT file_path FROM tb_asset_photo WHERE asset_seq=? AND side=?")) {
                    ps.setInt(1, assetSeq); ps.setString(2, side);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) {
                        String old = rs.getString("file_path");
                        if (old != null) {
                            File f = new File(getServletContext().getRealPath("/" + old));
                            if (f.exists()) f.delete();
                        }
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM tb_asset_photo WHERE asset_seq=? AND side=?")) {
                    ps.setInt(1, assetSeq); ps.setString(2, side); ps.executeUpdate();
                }
                filePart.write(uploadDir + File.separator + savedName);
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO tb_asset_photo (asset_seq, side, file_path, orig_name) VALUES (?,?,?,?)")) {
                    ps.setInt(1, assetSeq); ps.setString(2, side);
                    ps.setString(3, "upload/asset/" + assetSeq + "/" + savedName);
                    ps.setString(4, origName);
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect("AssetDetailServlet?assetSeq=" + assetSeq + "&photoTab=" + side
                    + "&uploadErr=" + java.net.URLEncoder.encode(e.getMessage() != null ? e.getMessage() : e.getClass().getName(), "UTF-8"));
            return;
        }
        resp.sendRedirect("AssetDetailServlet?assetSeq=" + assetSeq + "&photoTab=" + side);
    }

    // ─────────────────────────────────────────────────────
    // 사진 삭제
    // ─────────────────────────────────────────────────────
    private void doPhotoDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        int assetSeq = Integer.parseInt(req.getParameter("assetSeq"));
        String side  = "B".equals(req.getParameter("side")) ? "B" : "F";

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT file_path FROM tb_asset_photo WHERE asset_seq=? AND side=?")) {
                ps.setInt(1, assetSeq); ps.setString(2, side);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    String old = rs.getString("file_path");
                    if (old != null) {
                        File f = new File(getServletContext().getRealPath("/" + old));
                        if (f.exists()) f.delete();
                    }
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM tb_asset_photo WHERE asset_seq=? AND side=?")) {
                ps.setInt(1, assetSeq); ps.setString(2, side); ps.executeUpdate();
            }
        } catch (Exception e) { e.printStackTrace(); }
        resp.sendRedirect("AssetDetailServlet?assetSeq=" + assetSeq + "&photoTab=" + side);
    }

    // ─────────────────────────────────────────────────────
    // 포트맵 저장 (신규/수정)
    // ─────────────────────────────────────────────────────
    private void doPortSave(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        int assetSeq      = Integer.parseInt(req.getParameter("assetSeq"));
        String portSeqStr = req.getParameter("portSeq");
        String srcPort       = req.getParameter("srcPort");
        String dstSeqStr     = req.getParameter("dstAssetSeq");
        String dstDeviceName = emptyToNull(req.getParameter("dstDeviceName"));
        String dstPort       = emptyToNull(req.getParameter("dstPort"));
        String cableType     = emptyToNull(req.getParameter("cableType"));
        String cableColor    = emptyToNull(req.getParameter("cableColor"));
        String memo          = emptyToNull(req.getParameter("memo"));
        String retSeqSave    = req.getParameter("returnAssetSeq");

        // IN 행을 B 관점으로 수정할 때: 모달에서 srcPort=B포트, dstPort=A포트로 입력됨
        // DB에는 src_port=A포트, dst_port=B포트로 저장해야 하므로 교환
        boolean swap = "Y".equals(nvl(req.getParameter("swapSrcDst"), ""));
        String actualSrcPort    = swap ? emptyToNull(req.getParameter("dstPort")) : srcPort;
        String actualDstPort    = swap ? srcPort                                   : dstPort;
        String actualDstSeqStr  = swap ? retSeqSave                               : dstSeqStr;
        String actualDstDevName = swap ? null                                     : dstDeviceName;

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            if (portSeqStr == null || portSeqStr.isEmpty()) {
                int sort = 0;
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT COALESCE(MAX(sort_order),0)+1 FROM tb_port_map WHERE asset_seq=?")) {
                    ps.setInt(1, assetSeq);
                    ResultSet rs = ps.executeQuery();
                    if (rs.next()) sort = rs.getInt(1);
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO tb_port_map (asset_seq,src_port,dst_asset_seq,dst_device_name,dst_port,cable_type,cable_color,memo,sort_order) VALUES (?,?,?,?,?,?,?,?,?)")) {
                    ps.setInt(1, assetSeq);
                    ps.setString(2, actualSrcPort);
                    if (actualDstSeqStr == null || actualDstSeqStr.isEmpty()) ps.setNull(3, Types.INTEGER);
                    else ps.setInt(3, Integer.parseInt(actualDstSeqStr));
                    ps.setString(4, actualDstDevName); ps.setString(5, actualDstPort);
                    ps.setString(6, cableType);        ps.setString(7, cableColor);
                    ps.setString(8, memo);             ps.setInt(9, sort);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE tb_port_map SET src_port=?,dst_asset_seq=?,dst_device_name=?,dst_port=?,cable_type=?,cable_color=?,memo=? WHERE port_seq=? AND asset_seq=?")) {
                    ps.setString(1, actualSrcPort);
                    if (actualDstSeqStr == null || actualDstSeqStr.isEmpty()) ps.setNull(2, Types.INTEGER);
                    else ps.setInt(2, Integer.parseInt(actualDstSeqStr));
                    ps.setString(3, actualDstDevName); ps.setString(4, actualDstPort);
                    ps.setString(5, cableType);        ps.setString(6, cableColor);
                    ps.setString(7, memo);
                    ps.setInt(8, Integer.parseInt(portSeqStr));
                    ps.setInt(9, assetSeq);
                    ps.executeUpdate();
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        int redirectSeqSave = (retSeqSave != null && !retSeqSave.isEmpty()) ? Integer.parseInt(retSeqSave) : assetSeq;
        resp.sendRedirect("AssetDetailServlet?assetSeq=" + redirectSeqSave + "&tab=port");
    }

    // ─────────────────────────────────────────────────────
    // 포트맵 삭제
    // ─────────────────────────────────────────────────────
    private void doPortDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        int assetSeq = Integer.parseInt(req.getParameter("assetSeq"));
        int portSeq  = Integer.parseInt(req.getParameter("portSeq"));
        String retSeq = req.getParameter("returnAssetSeq");
        int redirectSeq = (retSeq != null && !retSeq.isEmpty()) ? Integer.parseInt(retSeq) : assetSeq;

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                     "DELETE FROM tb_port_map WHERE port_seq=? AND asset_seq=?")) {
            ps.setInt(1, portSeq); ps.setInt(2, assetSeq);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
        resp.sendRedirect("AssetDetailServlet?assetSeq=" + redirectSeq + "&tab=port");
    }

    // ── 유틸 ──────────────────────────────────────────────
    private String nvl(String s, String def) { return (s == null || s.isEmpty()) ? def : s; }
    private String emptyToNull(String s)     { return (s == null || s.isEmpty()) ? null : s; }

    // ── Value Objects ─────────────────────────────────────
    public static class AssetDetailVO {
        public int     assetSeq, parentSeq, custSeq;
        public String  custName, assetType, assetRole, virtType;
        public String  assetName, maker, model, hostname, ipAddr;
        public String  disk, cpu, memory, osInfo, location;
        public String  status, purchaseDt, expireDt, accountInfo, memo;
        public Integer sizeU;
    }

    public static class PhotoVO {
        public int    photoSeq;
        public String side, filePath, origName;
    }

    public static class PortMapVO {
        public int     portSeq, sortOrder, ownerAssetSeq;
        public String  srcPort, dstDeviceName, dstPort, cableType, cableColor, memo, dstAssetName, srcAssetName;
        public Integer dstAssetSeq;
        // 통합 포트맵용 정규화 필드
        public String  direction;       // "OUT" | "IN"
        public String  myPort;          // 이 장비의 포트
        public String  peerPort;        // 상대 장비의 포트
        public String  peerAssetName;   // 상대 장비명
        public String  peerDeviceName;  // 상대 장비 자유입력명 (OUT일 때)
        public Integer peerAssetSeq;    // 상대 장비 seq (링크용)
        public String  ownerAssetName;  // 레코드 소유자(출발지 장비) 이름
    }

    public static class SimpleAssetVO {
        public int    assetSeq;
        public String assetName;
    }
}

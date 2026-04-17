package com.admin.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import org.w3c.dom.*;
import javax.xml.parsers.*;
import java.io.*;
import java.nio.file.*;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * 보안점검 결과 뷰어 서블릿
 *
 *  GET  /SecurityScan?action=list              → 목록 페이지
 *  GET  /SecurityScan?action=detail&scanId=N   → 상세 페이지
 *  GET  /SecurityScan?action=detail&batchId=N  → 배치 상세 (첫 번째 스캔)
 *  POST /SecurityScan?action=upload            → tar 업로드 (1개 이상)
 *  POST /SecurityScan?action=delete            → 삭제 (scanId 또는 batchId)
 *  POST /SecurityScan?action=updateItem        → 항목 수정 (JSON)
 */
@WebServlet("/SecurityScan")
@MultipartConfig(maxFileSize = 52_428_800, maxRequestSize = 209_715_200)
public class SecurityScanServlet extends HttpServlet {

    private static final String DB_URL  = "jdbc:mariadb://localhost:3306/admin_db?characterEncoding=UTF-8&serverTimezone=Asia/Seoul";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "wkd11!#Eod";
    private static final String UPLOAD_DIR = "/var/lib/tomcat/webapps/app/upload/security/";

    @Override
    public void init() throws ServletException {
        try {
            Class.forName("org.mariadb.jdbc.Driver");
            new File(UPLOAD_DIR).mkdirs();
        } catch (ClassNotFoundException e) { throw new ServletException(e); }
    }

    // ─────────────────────────────────────────────────────
    // GET
    // ─────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        if (session(req) == null) { resp.sendRedirect("../login.jsp"); return; }

        String action = nvlD(req.getParameter("action"), "list");
        switch (action) {
            case "detail" -> doDetail(req, resp);
            default       -> doList(req, resp);
        }
    }

    // ─────────────────────────────────────────────────────
    // POST
    // ─────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        if (session(req) == null) { resp.sendRedirect("../login.jsp"); return; }

        String action = nvlD(req.getParameter("action"), "");
        switch (action) {
            case "upload"     -> doUpload(req, resp);
            case "delete"     -> doDelete(req, resp);
            case "updateItem" -> doUpdateItem(req, resp);
            default           -> resp.sendError(404);
        }
    }

    // ─────────────────────────────────────────────────────
    // 목록 조회
    // ─────────────────────────────────────────────────────
    private void doList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<ScanVO> scans = new ArrayList<>();
        List<BatchVO> batches = new ArrayList<>();
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            // 배치 목록
            String bsql = "SELECT b.batch_id, b.batch_name, b.created_at, COUNT(s.scan_id) AS server_count " +
                          "FROM security_scan_batch b LEFT JOIN security_scan s ON s.batch_id=b.batch_id " +
                          "GROUP BY b.batch_id ORDER BY b.created_at DESC";
            try (PreparedStatement ps = conn.prepareStatement(bsql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    BatchVO b = new BatchVO();
                    b.batchId     = rs.getInt("batch_id");
                    b.batchName   = nvl(rs.getString("batch_name"));
                    b.createdAt   = nvl(rs.getString("created_at"));
                    b.serverCount = rs.getInt("server_count");
                    batches.add(b);
                }
            }
            // 개별 스캔 목록 (batch_id IS NULL)
            String ssql = "SELECT scan_id, server_label, hostname, os_type, scan_date, uploaded_at, " +
                          "file_name, total_count, ok_count, vuln_count, manual_count " +
                          "FROM security_scan WHERE batch_id IS NULL ORDER BY uploaded_at DESC";
            try (PreparedStatement ps = conn.prepareStatement(ssql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) { scans.add(mapScan(rs)); }
            }
        } catch (SQLException e) {
            req.setAttribute("dbError", e.getMessage());
        }
        req.setAttribute("scans", scans);
        req.setAttribute("batches", batches);
        req.getRequestDispatcher("/security/security_scan_list.jsp").forward(req, resp);
    }

    // ─────────────────────────────────────────────────────
    // 상세 조회
    // ─────────────────────────────────────────────────────
    private void doDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String scanIdStr  = req.getParameter("scanId");
        String batchIdStr = req.getParameter("batchId");

        List<ScanVO> tabScans = new ArrayList<>();
        ScanVO currentScan = null;
        List<ScanItemVO> items = new ArrayList<>();

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            if (batchIdStr != null) {
                int batchId = Integer.parseInt(batchIdStr);
                // 배치 내 모든 스캔
                String bsql = "SELECT scan_id, server_label, hostname, os_type, scan_date, uploaded_at, " +
                              "file_name, total_count, ok_count, vuln_count, manual_count " +
                              "FROM security_scan WHERE batch_id=? ORDER BY scan_id";
                try (PreparedStatement ps = conn.prepareStatement(bsql)) {
                    ps.setInt(1, batchId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) { tabScans.add(mapScan(rs)); }
                    }
                }
                if (!tabScans.isEmpty()) {
                    // 선택된 탭 결정
                    int selectedScanId = scanIdStr != null ? Integer.parseInt(scanIdStr) : tabScans.get(0).scanId;
                    for (ScanVO s : tabScans) {
                        if (s.scanId == selectedScanId) { currentScan = s; break; }
                    }
                    if (currentScan == null) currentScan = tabScans.get(0);
                    req.setAttribute("batchId", batchId);
                }
            } else if (scanIdStr != null) {
                int scanId = Integer.parseInt(scanIdStr);
                String ssql = "SELECT scan_id, server_label, hostname, os_type, scan_date, uploaded_at, " +
                              "file_name, total_count, ok_count, vuln_count, manual_count " +
                              "FROM security_scan WHERE scan_id=?";
                try (PreparedStatement ps = conn.prepareStatement(ssql)) {
                    ps.setInt(1, scanId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) currentScan = mapScan(rs);
                    }
                }
            }

            if (currentScan != null) {
                String isql = "SELECT item_id, i_code, i_title, inspection_code, original_result, result, evidence, memo " +
                              "FROM security_scan_item WHERE scan_id=? ORDER BY item_id";
                try (PreparedStatement ps = conn.prepareStatement(isql)) {
                    ps.setInt(1, currentScan.scanId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) {
                            ScanItemVO item = new ScanItemVO();
                            item.itemId         = rs.getInt("item_id");
                            item.iCode          = nvl(rs.getString("i_code"));
                            item.iTitle         = nvl(rs.getString("i_title"));
                            item.inspectionCode = nvl(rs.getString("inspection_code"));
                            item.originalResult = nvl(rs.getString("original_result"));
                            item.result         = nvl(rs.getString("result"));
                            item.evidence       = nvl(rs.getString("evidence"));
                            item.memo           = nvl(rs.getString("memo"));
                            items.add(item);
                        }
                    }
                }
                // 요약 카운트 재계산 (수정된 result 기준)
                currentScan.okCount     = 0;
                currentScan.vulnCount   = 0;
                currentScan.manualCount = 0;
                for (ScanItemVO item : items) {
                    String r = item.result;
                    if ("양호".equals(r) || "양호함".equals(r)) currentScan.okCount++;
                    else if ("취약".equals(r)) currentScan.vulnCount++;
                    else currentScan.manualCount++;
                }
                currentScan.totalCount = items.size();
            }
        } catch (SQLException e) {
            req.setAttribute("dbError", e.getMessage());
        }

        req.setAttribute("tabScans", tabScans);
        req.setAttribute("currentScan", currentScan);
        req.setAttribute("items", items);
        req.getRequestDispatcher("/security/security_scan_detail.jsp").forward(req, resp);
    }

    // ─────────────────────────────────────────────────────
    // 업로드 처리
    // ─────────────────────────────────────────────────────
    private void doUpload(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String batchName  = nvl(req.getParameter("batchName")).trim();
        String[] labels   = req.getParameterValues("serverLabel");
        Collection<Part> fileParts = new ArrayList<>();
        for (Part part : req.getParts()) {
            if ("tarFile".equals(part.getName()) && part.getSize() > 0) {
                fileParts.add(part);
            }
        }

        if (fileParts.isEmpty()) {
            req.setAttribute("uploadError", "업로드할 파일이 없습니다.");
            doList(req, resp);
            return;
        }

        boolean isMulti = fileParts.size() > 1;
        Integer batchId = null;

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            if (isMulti) {
                String bName = batchName.isEmpty() ? "배치 " + new SimpleDateFormat("yyyy-MM-dd HH:mm").format(new java.util.Date()) : batchName;
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO security_scan_batch(batch_name) VALUES(?)", Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, bName);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) { if (rs.next()) batchId = rs.getInt(1); }
                }
            }

            int idx = 0;
            int firstScanId = -1;
            for (Part part : fileParts) {
                String originalName = getFileName(part);
                String label = (labels != null && idx < labels.length) ? nvl(labels[idx]).trim() : "";
                idx++;

                // tar 저장
                String savedName = System.currentTimeMillis() + "_" + originalName;
                File savedFile = new File(UPLOAD_DIR + savedName);
                part.write(savedFile.getAbsolutePath());

                // 임시 디렉토리에 추출
                File tmpDir = new File("/tmp/security_scan_" + System.currentTimeMillis());
                tmpDir.mkdirs();
                try {
                    ProcessBuilder pb = new ProcessBuilder("tar", "xf", savedFile.getAbsolutePath(), "-C", tmpDir.getAbsolutePath());
                    pb.redirectErrorStream(true);
                    Process p = pb.start();
                    p.waitFor();

                    // XML 파일 찾기
                    File xmlFile = null;
                    for (File f : tmpDir.listFiles()) {
                        if (f.getName().endsWith(".xml")) { xmlFile = f; break; }
                    }
                    if (xmlFile == null) continue;

                    // XML 파싱
                    DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
                    dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
                    Document doc = dbf.newDocumentBuilder().parse(xmlFile);
                    doc.getDocumentElement().normalize();

                    // Info 섹션
                    String sysVersion = getTagText(doc, "sVersion");
                    String lastTime   = getTagText(doc, "LastTime");

                    // 호스트명·OS 추출 (파일명: hostname.xml 또는 sVersion에서)
                    String hostname = xmlFile.getName().replace(".xml", "");
                    String osType   = "";
                    if (sysVersion != null && sysVersion.contains("Linux")) osType = "Linux";
                    else if (sysVersion != null && sysVersion.contains("AIX")) osType = "AIX";
                    else if (sysVersion != null && sysVersion.contains("SunOS")) osType = "SunOS";
                    else if (sysVersion != null && sysVersion.contains("HP-UX")) osType = "HP-UX";

                    // 파일명에서 날짜 추출 (hostname_OS_YYYYMMDD.tar)
                    java.sql.Date scanDate = null;
                    try {
                        String baseName = originalName.replace(".tar", "");
                        String[] parts2 = baseName.split("_");
                        String datePart = parts2[parts2.length - 1];
                        if (datePart.matches("\\d{8}")) {
                            scanDate = java.sql.Date.valueOf(
                                datePart.substring(0,4) + "-" + datePart.substring(4,6) + "-" + datePart.substring(6,8));
                        }
                    } catch (Exception ignored) {}

                    if (label.isEmpty()) label = hostname;

                    // security_scan 저장
                    int scanId;
                    String insertScan = "INSERT INTO security_scan(batch_id, server_label, hostname, os_type, scan_date, " +
                                       "file_name, sys_version, last_time) VALUES(?,?,?,?,?,?,?,?)";
                    try (PreparedStatement ps = conn.prepareStatement(insertScan, Statement.RETURN_GENERATED_KEYS)) {
                        ps.setObject(1, batchId);
                        ps.setString(2, label);
                        ps.setString(3, hostname);
                        ps.setString(4, osType);
                        ps.setObject(5, scanDate);
                        ps.setString(6, originalName);
                        ps.setString(7, sysVersion != null ? sysVersion.substring(0, Math.min(sysVersion.length(), 65535)) : null);
                        ps.setString(8, lastTime != null ? lastTime.substring(0, Math.min(lastTime.length(), 100)) : null);
                        ps.executeUpdate();
                        try (ResultSet rs = ps.getGeneratedKeys()) { scanId = rs.next() ? rs.getInt(1) : -1; }
                    }
                    if (scanId == -1) continue;
                    if (firstScanId == -1) firstScanId = scanId;

                    // 항목 저장
                    NodeList items = doc.getElementsByTagName("Item");
                    int okCount = 0, vulnCount = 0, manualCount = 0;
                    String insertItem = "INSERT INTO security_scan_item(scan_id, i_code, i_title, inspection_code, original_result, result, evidence) " +
                                       "VALUES(?,?,?,?,?,?,?)";
                    try (PreparedStatement ps = conn.prepareStatement(insertItem)) {
                        for (int i = 0; i < items.getLength(); i++) {
                            Element el = (Element) items.item(i);
                            String iCode    = getElText(el, "iCode");
                            String iTitle   = getElText(el, "iTitle");
                            String inspCode = getElText(el, "InspectionCode");
                            String rawResult = nvl(getElText(el, "Result")).trim();
                            String result   = normalizeResult(rawResult);
                            String evidence = nvl(getElText(el, "Evidence")).trim();

                            if ("양호".equals(result)) okCount++;
                            else if ("취약".equals(result)) vulnCount++;
                            else manualCount++;

                            ps.setInt(1, scanId);
                            ps.setString(2, iCode);
                            ps.setString(3, iTitle);
                            ps.setString(4, inspCode);
                            ps.setString(5, result);
                            ps.setString(6, result);
                            ps.setString(7, evidence);
                            ps.addBatch();
                        }
                        ps.executeBatch();
                    }

                    // 카운트 업데이트
                    int total = okCount + vulnCount + manualCount;
                    try (PreparedStatement ps = conn.prepareStatement(
                            "UPDATE security_scan SET total_count=?, ok_count=?, vuln_count=?, manual_count=? WHERE scan_id=?")) {
                        ps.setInt(1, total); ps.setInt(2, okCount); ps.setInt(3, vulnCount);
                        ps.setInt(4, manualCount); ps.setInt(5, scanId);
                        ps.executeUpdate();
                    }
                } finally {
                    deleteDir(tmpDir);
                }
            }

            // 리다이렉트
            if (batchId != null) {
                resp.sendRedirect("SecurityScan?action=detail&batchId=" + batchId);
            } else if (firstScanId != -1) {
                resp.sendRedirect("SecurityScan?action=detail&scanId=" + firstScanId);
            } else {
                resp.sendRedirect("SecurityScan?action=list");
            }

        } catch (Exception e) {
            req.setAttribute("uploadError", e.getMessage());
            doList(req, resp);
        }
    }

    // ─────────────────────────────────────────────────────
    // 삭제
    // ─────────────────────────────────────────────────────
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String scanIdStr  = req.getParameter("scanId");
        String batchIdStr = req.getParameter("batchId");
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            if (batchIdStr != null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM security_scan_batch WHERE batch_id=?")) {
                    ps.setInt(1, Integer.parseInt(batchIdStr));
                    ps.executeUpdate();
                }
            } else if (scanIdStr != null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM security_scan WHERE scan_id=?")) {
                    ps.setInt(1, Integer.parseInt(scanIdStr));
                    ps.executeUpdate();
                }
            }
        } catch (SQLException e) { /* ignore */ }
        resp.sendRedirect("SecurityScan?action=list");
    }

    // ─────────────────────────────────────────────────────
    // 항목 수정 (JSON 응답)
    // ─────────────────────────────────────────────────────
    private void doUpdateItem(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        int    itemId = Integer.parseInt(nvlD(req.getParameter("itemId"), "0"));
        String result = nvl(req.getParameter("result")).trim();
        String memo   = nvl(req.getParameter("memo")).trim();

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE security_scan_item SET result=?, memo=? WHERE item_id=?")) {
                ps.setString(1, result);
                ps.setString(2, memo.isEmpty() ? null : memo);
                ps.setInt(3, itemId);
                ps.executeUpdate();
            }
            // 스캔 카운트 재계산
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT scan_id FROM security_scan_item WHERE item_id=?")) {
                ps.setInt(1, itemId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        int scanId = rs.getInt(1);
                        updateScanCounts(conn, scanId);
                    }
                }
            }
            resp.getWriter().write("{\"ok\":true}");
        } catch (SQLException e) {
            resp.getWriter().write("{\"ok\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}");
        }
    }

    // ─────────────────────────────────────────────────────
    // 헬퍼
    // ─────────────────────────────────────────────────────
    private void updateScanCounts(Connection conn, int scanId) throws SQLException {
        String sql = "SELECT result FROM security_scan_item WHERE scan_id=?";
        int ok = 0, vuln = 0, manual = 0;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, scanId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String r = nvl(rs.getString(1));
                    if ("양호".equals(r)) ok++;
                    else if ("취약".equals(r)) vuln++;
                    else manual++;
                }
            }
        }
        int total = ok + vuln + manual;
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE security_scan SET total_count=?, ok_count=?, vuln_count=?, manual_count=? WHERE scan_id=?")) {
            ps.setInt(1, total); ps.setInt(2, ok); ps.setInt(3, vuln);
            ps.setInt(4, manual); ps.setInt(5, scanId);
            ps.executeUpdate();
        }
    }

    private String normalizeResult(String r) {
        if (r == null) return "수동점검";
        if (r.startsWith("양호")) return "양호";
        if (r.startsWith("취약")) return "취약";
        if (r.startsWith("N/A") || r.startsWith("n/a") || r.startsWith("해당없음")) return "N/A";
        return "수동점검";
    }

    private ScanVO mapScan(ResultSet rs) throws SQLException {
        ScanVO s = new ScanVO();
        s.scanId      = rs.getInt("scan_id");
        s.serverLabel = nvl(rs.getString("server_label"));
        s.hostname    = nvl(rs.getString("hostname"));
        s.osType      = nvl(rs.getString("os_type"));
        s.scanDate    = nvl(rs.getString("scan_date"));
        s.uploadedAt  = nvl(rs.getString("uploaded_at"));
        s.fileName    = nvl(rs.getString("file_name"));
        s.totalCount  = rs.getInt("total_count");
        s.okCount     = rs.getInt("ok_count");
        s.vulnCount   = rs.getInt("vuln_count");
        s.manualCount = rs.getInt("manual_count");
        return s;
    }

    private String getTagText(Document doc, String tag) {
        NodeList nl = doc.getElementsByTagName(tag);
        if (nl.getLength() == 0) return null;
        return nl.item(0).getTextContent();
    }

    private String getElText(Element el, String tag) {
        NodeList nl = el.getElementsByTagName(tag);
        if (nl.getLength() == 0) return "";
        return nvl(nl.item(0).getTextContent());
    }

    private String getFileName(Part part) {
        for (String cd : part.getHeader("content-disposition").split(";")) {
            if (cd.trim().startsWith("filename")) {
                return cd.substring(cd.indexOf('=') + 1).trim().replace("\"", "");
            }
        }
        return "upload_" + System.currentTimeMillis() + ".tar";
    }

    private void deleteDir(File dir) {
        if (dir == null || !dir.exists()) return;
        File[] files = dir.listFiles();
        if (files != null) for (File f : files) { if (f.isDirectory()) deleteDir(f); else f.delete(); }
        dir.delete();
    }

    private HttpSession session(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        return (s != null && s.getAttribute("loginUser") != null) ? s : null;
    }

    private String nvl(String s) { return s != null ? s : ""; }
    private String nvlD(String s, String def) { return (s != null && !s.isEmpty()) ? s : def; }

    private String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }

    // ─────────────────────────────────────────────────────
    // VO Classes
    // ─────────────────────────────────────────────────────
    public static class ScanVO {
        public int    scanId, totalCount, okCount, vulnCount, manualCount;
        public String serverLabel, hostname, osType, scanDate, uploadedAt, fileName;
    }

    public static class BatchVO {
        public int    batchId, serverCount;
        public String batchName, createdAt;
    }

    public static class ScanItemVO {
        public int    itemId;
        public String iCode, iTitle, inspectionCode, originalResult, result, evidence, memo;
    }
}

package com.admin.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.*;
import org.apache.poi.common.usermodel.HyperlinkType;
import org.apache.poi.ss.util.CellReference;
import org.w3c.dom.*;
import javax.xml.parsers.*;
import java.io.*;
import java.nio.file.*;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.regex.*;

/**
 * 보안점검 결과 뷰어 서블릿
 *
 *  GET  /SecurityScan?action=list              → 목록 페이지
 *  GET  /SecurityScan?action=detail&batchId=N  → 배치 상세
 *  GET  /SecurityScan?action=downloadExcel     → 엑셀 다운로드 (batchId)
 *  POST /SecurityScan?action=upload            → tar 업로드 (배치로 저장)
 *  POST /SecurityScan?action=delete            → 삭제 (batchId)
 *  POST /SecurityScan?action=updateItem        → 항목 수정 (JSON)
 */
@WebServlet("/SecurityScan")
@MultipartConfig(maxFileSize = 52_428_800, maxRequestSize = 209_715_200)
public class SecurityScanServlet extends HttpServlet {

    private static final String UPLOAD_DIR = "/var/lib/tomcat/webapps/app/upload/security/";

    @Override
    public void init() throws ServletException {
        new File(UPLOAD_DIR).mkdirs();
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
            case "detail"             -> doDetail(req, resp);
            case "downloadExcel"      -> doDownloadExcel(req, resp);
            case "getEvidenceTypes"   -> doGetEvidenceTypes(req, resp);
            case "getFollowupStatus"  -> doGetFollowupStatus(req, resp);
            default                   -> doList(req, resp);
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
            case "upload"                   -> doUpload(req, resp);
            case "uploadFollowup"           -> doUploadFollowup(req, resp);
            case "uploadBatchFollowup"      -> doUploadBatchFollowup(req, resp);
            case "delete"                   -> doDelete(req, resp);
            case "updateItem"               -> doUpdateItem(req, resp);
            case "saveEvidenceTypes"        -> doSaveEvidenceTypes(req, resp);
            case "getEvidenceTypes"         -> doGetEvidenceTypes(req, resp);
            case "batchUpdateEvidenceTypes" -> doBatchUpdateEvidenceTypes(req, resp);
            default                         -> resp.sendError(404);
        }
    }

    // ─────────────────────────────────────────────────────
    // 목록 조회
    // ─────────────────────────────────────────────────────
    private void doList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<BatchVO> batches = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection()) {
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
        } catch (SQLException e) {
            req.setAttribute("dbError", e.getMessage());
        }
        req.setAttribute("batches", batches);
        req.getRequestDispatcher("/security/security_scan_list.jsp").forward(req, resp);
    }

    // ─────────────────────────────────────────────────────
    // 상세 조회
    // ─────────────────────────────────────────────────────
    private void doDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        resp.setHeader("Pragma", "no-cache");
        resp.setDateHeader("Expires", 0);
        String scanIdStr  = req.getParameter("scanId");
        String batchIdStr = req.getParameter("batchId");

        List<ScanVO> tabScans = new ArrayList<>();
        ScanVO currentScan = null;
        List<ScanItemVO> items = new ArrayList<>();

        try (Connection conn = DBUtil.getConnection()) {
            if (batchIdStr != null) {
                int batchId = Integer.parseInt(batchIdStr);
                String bsql = "SELECT scan_id, server_label, hostname, ip_address, os_type, scan_date, uploaded_at, " +
                              "file_name, total_count, ok_count, vuln_count, manual_count, followup_scan_id " +
                              "FROM security_scan WHERE batch_id=? ORDER BY scan_id";
                try (PreparedStatement ps = conn.prepareStatement(bsql)) {
                    ps.setInt(1, batchId);
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) { tabScans.add(mapScan(rs)); }
                    }
                }
                if (!tabScans.isEmpty()) {
                    int selectedScanId = scanIdStr != null ? Integer.parseInt(scanIdStr) : tabScans.get(0).scanId;
                    for (ScanVO s : tabScans) {
                        if (s.scanId == selectedScanId) { currentScan = s; break; }
                    }
                    if (currentScan == null) currentScan = tabScans.get(0);
                    req.setAttribute("batchId", batchId);
                }
            } else if (scanIdStr != null) {
                int scanId = Integer.parseInt(scanIdStr);
                String ssql = "SELECT scan_id, server_label, hostname, ip_address, os_type, scan_date, uploaded_at, " +
                              "file_name, total_count, ok_count, vuln_count, manual_count, followup_scan_id " +
                              "FROM security_scan WHERE scan_id=?";
                try (PreparedStatement ps = conn.prepareStatement(ssql)) {
                    ps.setInt(1, scanId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) currentScan = mapScan(rs);
                    }
                }
            }

            if (currentScan != null) {
                String isql = "SELECT item_id, i_code, i_title, inspection_code, original_result, result, evidence, txt_evidence, ref_evidence, memo " +
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
                            item.txtEvidence    = nvl(rs.getString("txt_evidence"));
                            item.refEvidence    = nvl(rs.getString("ref_evidence"));
                            item.memo           = nvl(rs.getString("memo"));
                            items.add(item);
                        }
                    }
                }
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

        // 이행점검 항목 맵 (i_code → ScanItemVO) + 이행점검 스캔 정보
        Map<String, ScanItemVO> followupItemMap = new LinkedHashMap<>();
        if (currentScan != null && currentScan.followupScanId > 0) {
            try (Connection conn2 = DBUtil.getConnection()) {
                for (ScanItemVO fu : loadItems(conn2, currentScan.followupScanId)) {
                    followupItemMap.put(fu.iCode, fu);
                }
                String fuScanSql = "SELECT file_name, scan_date FROM security_scan WHERE scan_id=?";
                try (PreparedStatement ps = conn2.prepareStatement(fuScanSql)) {
                    ps.setInt(1, currentScan.followupScanId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            req.setAttribute("followupFileName", nvl(rs.getString("file_name")));
                            req.setAttribute("followupScanDate", nvl(rs.getString("scan_date")));
                        }
                    }
                }
            } catch (SQLException ignored) {}
        }
        req.setAttribute("followupItemMap", followupItemMap);

        req.getRequestDispatcher("/security/security_scan_detail.jsp").forward(req, resp);
    }

    // ─────────────────────────────────────────────────────
    // 업로드 처리
    // ─────────────────────────────────────────────────────
    private void doUpload(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String batchName  = nvl(req.getParameter("batchName")).trim();
        String[] labels   = req.getParameterValues("serverLabel");
        String[] ips      = req.getParameterValues("ipAddress");
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

        Integer batchId = null;

        try (Connection conn = DBUtil.getConnection()) {
            String bName = batchName.isEmpty() ? "점검 " + new SimpleDateFormat("yyyy-MM-dd HH:mm").format(new java.util.Date()) : batchName;
            try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO security_scan_batch(batch_name) VALUES(?)", Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, bName);
                ps.executeUpdate();
                try (ResultSet rs = ps.getGeneratedKeys()) { if (rs.next()) batchId = rs.getInt(1); }
            }

            int idx = 0;
            for (Part part : fileParts) {
                String originalName = getFileName(part);
                String label = (labels != null && idx < labels.length) ? nvl(labels[idx]).trim() : "";
                String ip    = (ips    != null && idx < ips.length)    ? nvl(ips[idx]).trim()    : "";
                idx++;

                String savedName = System.currentTimeMillis() + "_" + originalName;
                File savedFile = new File(UPLOAD_DIR + savedName);
                part.write(savedFile.getAbsolutePath());

                File tmpDir = new File("/tmp/security_scan_" + System.currentTimeMillis());
                tmpDir.mkdirs();
                try {
                    ProcessBuilder pb = new ProcessBuilder("tar", "xf", savedFile.getAbsolutePath(), "-C", tmpDir.getAbsolutePath());
                    pb.redirectErrorStream(true);
                    Process p = pb.start();
                    p.waitFor();

                    File xmlFile = null;
                    for (File f : tmpDir.listFiles()) {
                        if (f.getName().endsWith(".xml")) { xmlFile = f; break; }
                    }
                    if (xmlFile == null) continue;

                    DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
                    dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
                    Document doc = dbf.newDocumentBuilder().parse(xmlFile);
                    doc.getDocumentElement().normalize();

                    String sysVersion = getTagText(doc, "sVersion");
                    String lastTime   = getTagText(doc, "LastTime");

                    String hostname = xmlFile.getName().replace(".xml", "");
                    String osType   = "";
                    if (sysVersion != null && sysVersion.contains("Linux")) osType = "Linux";
                    else if (sysVersion != null && sysVersion.contains("AIX")) osType = "AIX";
                    else if (sysVersion != null && sysVersion.contains("SunOS")) osType = "SunOS";
                    else if (sysVersion != null && sysVersion.contains("HP-UX")) osType = "HP-UX";

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

                    int scanId;
                    String insertScan = "INSERT INTO security_scan(batch_id, server_label, hostname, ip_address, os_type, scan_date, " +
                                       "file_name, sys_version, last_time) VALUES(?,?,?,?,?,?,?,?,?)";
                    try (PreparedStatement ps = conn.prepareStatement(insertScan, Statement.RETURN_GENERATED_KEYS)) {
                        ps.setObject(1, batchId);
                        ps.setString(2, label);
                        ps.setString(3, hostname);
                        ps.setString(4, ip.isEmpty() ? null : ip);
                        ps.setString(5, osType);
                        ps.setObject(6, scanDate);
                        ps.setString(7, originalName);
                        ps.setString(8, sysVersion != null ? sysVersion.substring(0, Math.min(sysVersion.length(), 65535)) : null);
                        ps.setString(9, lastTime != null ? lastTime.substring(0, Math.min(lastTime.length(), 100)) : null);
                        ps.executeUpdate();
                        try (ResultSet rs = ps.getGeneratedKeys()) { scanId = rs.next() ? rs.getInt(1) : -1; }
                    }
                    if (scanId == -1) continue;

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

                    int total = okCount + vulnCount + manualCount;
                    try (PreparedStatement ps = conn.prepareStatement(
                            "UPDATE security_scan SET total_count=?, ok_count=?, vuln_count=?, manual_count=? WHERE scan_id=?")) {
                        ps.setInt(1, total); ps.setInt(2, okCount); ps.setInt(3, vulnCount);
                        ps.setInt(4, manualCount); ps.setInt(5, scanId);
                        ps.executeUpdate();
                    }

                    File txtFile = null, refFile = null;
                    File[] extracted = tmpDir.listFiles();
                    if (extracted != null) {
                        for (File f : extracted) {
                            if (f.getName().endsWith("_REF.txt")) refFile = f;
                            else if (f.getName().endsWith(".txt"))  txtFile = f;
                        }
                    }

                    Map<String, String> txtMap = txtFile != null ? parseTxtFile(txtFile) : new HashMap<>();
                    Map<String, String> refMap = refFile != null ? parseTxtFile(refFile) : new HashMap<>();
                    if (!txtMap.isEmpty() || !refMap.isEmpty()) {
                        try (PreparedStatement psTxt = conn.prepareStatement(
                                "UPDATE security_scan_item SET txt_evidence=?, ref_evidence=? WHERE scan_id=? AND i_code=?")) {
                            for (int i = 0; i < items.getLength(); i++) {
                                Element el = (Element) items.item(i);
                                String iCode = getElText(el, "iCode");
                                String tv = txtMap.containsKey(iCode) ? txtMap.get(iCode) : null;
                                String rv = refMap.containsKey(iCode) ? refMap.get(iCode) : null;
                                if (tv != null || rv != null) {
                                    psTxt.setString(1, tv);
                                    psTxt.setString(2, rv);
                                    psTxt.setInt(3, scanId);
                                    psTxt.setString(4, iCode);
                                    psTxt.addBatch();
                                }
                            }
                            psTxt.executeBatch();
                        }
                    }
                } finally {
                    deleteDir(tmpDir);
                }
            }

            if (batchId != null) {
                resp.sendRedirect("SecurityScan?action=detail&batchId=" + batchId);
            } else {
                resp.sendRedirect("SecurityScan?action=list");
            }

        } catch (Exception e) {
            req.setAttribute("uploadError", e.getMessage());
            doList(req, resp);
        }
    }

    // ─────────────────────────────────────────────────────
    // 이행점검 업로드
    // ─────────────────────────────────────────────────────
    private void doUploadFollowup(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int scanId = Integer.parseInt(nvlD(req.getParameter("scanId"), "0"));
        String batchIdParam = nvl(req.getParameter("batchId"));
        if (scanId == 0) { resp.sendRedirect("SecurityScan?action=list"); return; }

        Part filePart = null;
        for (Part p : req.getParts()) {
            if ("tarFile".equals(p.getName()) && p.getSize() > 0) { filePart = p; break; }
        }
        if (filePart == null) {
            String rd = batchIdParam.isEmpty() ? "SecurityScan?action=list"
                      : "SecurityScan?action=detail&batchId=" + batchIdParam + "&scanId=" + scanId;
            resp.sendRedirect(rd); return;
        }

        try (Connection conn = DBUtil.getConnection()) {
            // 기존 이행점검이 있으면 삭제
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT followup_scan_id FROM security_scan WHERE scan_id=?")) {
                ps.setInt(1, scanId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        int oldFu = rs.getInt("followup_scan_id");
                        if (!rs.wasNull() && oldFu > 0) {
                            try (PreparedStatement del = conn.prepareStatement(
                                    "DELETE FROM security_scan WHERE scan_id=?")) {
                                del.setInt(1, oldFu);
                                del.executeUpdate();
                            }
                            try (PreparedStatement upd = conn.prepareStatement(
                                    "UPDATE security_scan SET followup_scan_id=NULL WHERE scan_id=?")) {
                                upd.setInt(1, scanId);
                                upd.executeUpdate();
                            }
                        }
                    }
                }
            }

            // 원본 스캔 서버 정보 조회
            String origLabel = "", origIp = "", origOsType = "";
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT server_label, ip_address, os_type FROM security_scan WHERE scan_id=?")) {
                ps.setInt(1, scanId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        origLabel  = nvl(rs.getString("server_label"));
                        origIp     = nvl(rs.getString("ip_address"));
                        origOsType = nvl(rs.getString("os_type"));
                    }
                }
            }

            String originalName = getFileName(filePart);
            String savedName = System.currentTimeMillis() + "_" + originalName;
            File savedFile = new File(UPLOAD_DIR + savedName);
            filePart.write(savedFile.getAbsolutePath());

            File tmpDir = new File("/tmp/security_scan_fu_" + System.currentTimeMillis());
            tmpDir.mkdirs();
            try {
                ProcessBuilder pb = new ProcessBuilder("tar", "xf", savedFile.getAbsolutePath(), "-C", tmpDir.getAbsolutePath());
                pb.redirectErrorStream(true);
                Process p = pb.start();
                p.waitFor();

                File xmlFile = null;
                for (File f : tmpDir.listFiles()) {
                    if (f.getName().endsWith(".xml")) { xmlFile = f; break; }
                }
                if (xmlFile == null) throw new Exception("XML 파일을 찾을 수 없습니다.");

                DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
                dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
                Document doc = dbf.newDocumentBuilder().parse(xmlFile);
                doc.getDocumentElement().normalize();

                String sysVersion = getTagText(doc, "sVersion");
                String lastTime   = getTagText(doc, "LastTime");
                String hostname   = xmlFile.getName().replace(".xml", "");
                String osType     = origOsType;
                if (sysVersion != null) {
                    if (sysVersion.contains("Linux")) osType = "Linux";
                    else if (sysVersion.contains("AIX")) osType = "AIX";
                    else if (sysVersion.contains("SunOS")) osType = "SunOS";
                    else if (sysVersion.contains("HP-UX")) osType = "HP-UX";
                }

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

                int followupScanId;
                String insertScan = "INSERT INTO security_scan(batch_id, server_label, hostname, ip_address, os_type, scan_date, " +
                                    "file_name, sys_version, last_time) VALUES(NULL,?,?,?,?,?,?,?,?)";
                try (PreparedStatement ps = conn.prepareStatement(insertScan, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, origLabel);
                    ps.setString(2, hostname);
                    ps.setString(3, origIp.isEmpty() ? null : origIp);
                    ps.setString(4, osType);
                    ps.setObject(5, scanDate);
                    ps.setString(6, originalName);
                    ps.setString(7, sysVersion != null ? sysVersion.substring(0, Math.min(sysVersion.length(), 65535)) : null);
                    ps.setString(8, lastTime != null ? lastTime.substring(0, Math.min(lastTime.length(), 100)) : null);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) { followupScanId = rs.next() ? rs.getInt(1) : -1; }
                }
                if (followupScanId == -1) throw new Exception("이행점검 스캔 생성 실패");

                NodeList itemNodes = doc.getElementsByTagName("Item");
                int okCount = 0, vulnCount = 0, manualCount = 0;
                String insertItem = "INSERT INTO security_scan_item(scan_id, i_code, i_title, inspection_code, original_result, result, evidence) " +
                                    "VALUES(?,?,?,?,?,?,?)";
                try (PreparedStatement ps = conn.prepareStatement(insertItem)) {
                    for (int i = 0; i < itemNodes.getLength(); i++) {
                        Element el = (Element) itemNodes.item(i);
                        String iCode     = getElText(el, "iCode");
                        String iTitle    = getElText(el, "iTitle");
                        String inspCode  = getElText(el, "InspectionCode");
                        String rawResult = nvl(getElText(el, "Result")).trim();
                        String result    = normalizeResult(rawResult);
                        String evidence  = nvl(getElText(el, "Evidence")).trim();
                        if ("양호".equals(result)) okCount++;
                        else if ("취약".equals(result)) vulnCount++;
                        else manualCount++;
                        ps.setInt(1, followupScanId);
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

                int total = okCount + vulnCount + manualCount;
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE security_scan SET total_count=?, ok_count=?, vuln_count=?, manual_count=? WHERE scan_id=?")) {
                    ps.setInt(1, total); ps.setInt(2, okCount); ps.setInt(3, vulnCount);
                    ps.setInt(4, manualCount); ps.setInt(5, followupScanId);
                    ps.executeUpdate();
                }

                File txtFile = null, refFile = null;
                File[] extracted = tmpDir.listFiles();
                if (extracted != null) {
                    for (File f : extracted) {
                        if (f.getName().endsWith("_REF.txt")) refFile = f;
                        else if (f.getName().endsWith(".txt")) txtFile = f;
                    }
                }
                Map<String, String> txtMap = txtFile != null ? parseTxtFile(txtFile) : new HashMap<>();
                Map<String, String> refMap = refFile != null ? parseTxtFile(refFile) : new HashMap<>();
                if (!txtMap.isEmpty() || !refMap.isEmpty()) {
                    try (PreparedStatement psTxt = conn.prepareStatement(
                            "UPDATE security_scan_item SET txt_evidence=?, ref_evidence=? WHERE scan_id=? AND i_code=?")) {
                        for (int i = 0; i < itemNodes.getLength(); i++) {
                            Element el = (Element) itemNodes.item(i);
                            String iCode = getElText(el, "iCode");
                            String tv = txtMap.containsKey(iCode) ? txtMap.get(iCode) : null;
                            String rv = refMap.containsKey(iCode) ? refMap.get(iCode) : null;
                            if (tv != null || rv != null) {
                                psTxt.setString(1, tv);
                                psTxt.setString(2, rv);
                                psTxt.setInt(3, followupScanId);
                                psTxt.setString(4, iCode);
                                psTxt.addBatch();
                            }
                        }
                        psTxt.executeBatch();
                    }
                }

                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE security_scan SET followup_scan_id=? WHERE scan_id=?")) {
                    ps.setInt(1, followupScanId);
                    ps.setInt(2, scanId);
                    ps.executeUpdate();
                }
            } finally {
                deleteDir(tmpDir);
            }
        } catch (Exception e) {
            req.setAttribute("uploadError", e.getMessage());
            doList(req, resp);
            return;
        }

        String redirect = batchIdParam.isEmpty()
            ? "SecurityScan?action=detail&scanId=" + scanId
            : "SecurityScan?action=detail&batchId=" + batchIdParam + "&scanId=" + scanId;
        resp.sendRedirect(redirect);
    }

    // ─────────────────────────────────────────────────────
    // 이행점검 상태 조회 (JSON)
    // ─────────────────────────────────────────────────────
    private void doGetFollowupStatus(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        int batchId = Integer.parseInt(nvlD(req.getParameter("batchId"), "0"));
        if (batchId == 0) { resp.getWriter().write("[]"); return; }
        StringBuilder sb = new StringBuilder("[");
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                 "SELECT scan_id, server_label, hostname, followup_scan_id " +
                 "FROM security_scan WHERE batch_id=? ORDER BY scan_id")) {
            ps.setInt(1, batchId);
            try (ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) sb.append(",");
                    first = false;
                    int fuId = rs.getInt("followup_scan_id");
                    sb.append("{\"scanId\":").append(rs.getInt("scan_id"))
                      .append(",\"serverLabel\":\"").append(escapeJson(nvl(rs.getString("server_label"))))
                      .append("\",\"hostname\":\"").append(escapeJson(nvl(rs.getString("hostname"))))
                      .append("\",\"hasFollowup\":").append(!rs.wasNull() && fuId > 0)
                      .append("}");
                }
            }
        } catch (SQLException e) {
            resp.getWriter().write("[]"); return;
        }
        sb.append("]");
        resp.getWriter().write(sb.toString());
    }

    // ─────────────────────────────────────────────────────
    // 이행점검 일괄 업로드
    // ─────────────────────────────────────────────────────
    private void doUploadBatchFollowup(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String batchIdParam = nvl(req.getParameter("batchId"));
        // tarFile_{scanId} 형식의 part를 찾아 각각 처리
        for (Part part : req.getParts()) {
            String partName = part.getName();
            if (!partName.startsWith("tarFile_") || part.getSize() == 0) continue;
            String scanIdStr = partName.substring("tarFile_".length());
            int scanId;
            try { scanId = Integer.parseInt(scanIdStr); } catch (NumberFormatException e) { continue; }
            // 기존 doUploadFollowup 로직을 직접 호출 (req에 적절한 파라미터가 없으므로 직접 처리)
            processFollowupPart(scanId, part, batchIdParam);
        }
        resp.sendRedirect("SecurityScan?action=list");
    }

    private void processFollowupPart(int scanId, Part filePart, String batchIdParam) {
        try (Connection conn = DBUtil.getConnection()) {
            // 기존 이행점검 삭제
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT followup_scan_id FROM security_scan WHERE scan_id=?")) {
                ps.setInt(1, scanId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        int oldFu = rs.getInt("followup_scan_id");
                        if (!rs.wasNull() && oldFu > 0) {
                            try (PreparedStatement del = conn.prepareStatement(
                                    "DELETE FROM security_scan WHERE scan_id=?")) {
                                del.setInt(1, oldFu); del.executeUpdate();
                            }
                            try (PreparedStatement upd = conn.prepareStatement(
                                    "UPDATE security_scan SET followup_scan_id=NULL WHERE scan_id=?")) {
                                upd.setInt(1, scanId); upd.executeUpdate();
                            }
                        }
                    }
                }
            }
            String origLabel = "", origIp = "", origOsType = "";
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT server_label, ip_address, os_type FROM security_scan WHERE scan_id=?")) {
                ps.setInt(1, scanId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        origLabel  = nvl(rs.getString("server_label"));
                        origIp     = nvl(rs.getString("ip_address"));
                        origOsType = nvl(rs.getString("os_type"));
                    }
                }
            }
            String originalName = getFileName(filePart);
            String savedName = System.currentTimeMillis() + "_" + originalName;
            File savedFile = new File(UPLOAD_DIR + savedName);
            filePart.write(savedFile.getAbsolutePath());

            File tmpDir = new File("/tmp/security_scan_bfu_" + System.currentTimeMillis() + "_" + scanId);
            tmpDir.mkdirs();
            try {
                ProcessBuilder pb = new ProcessBuilder("tar", "xf", savedFile.getAbsolutePath(), "-C", tmpDir.getAbsolutePath());
                pb.redirectErrorStream(true);
                pb.start().waitFor();
                File xmlFile = null;
                for (File f : tmpDir.listFiles()) {
                    if (f.getName().endsWith(".xml")) { xmlFile = f; break; }
                }
                if (xmlFile == null) return;
                DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
                dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
                Document doc = dbf.newDocumentBuilder().parse(xmlFile);
                doc.getDocumentElement().normalize();
                String sysVersion = getTagText(doc, "sVersion");
                String lastTime   = getTagText(doc, "LastTime");
                String hostname   = xmlFile.getName().replace(".xml", "");
                String osType     = origOsType;
                if (sysVersion != null) {
                    if (sysVersion.contains("Linux")) osType = "Linux";
                    else if (sysVersion.contains("AIX")) osType = "AIX";
                    else if (sysVersion.contains("SunOS")) osType = "SunOS";
                    else if (sysVersion.contains("HP-UX")) osType = "HP-UX";
                }
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

                int followupScanId;
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO security_scan(batch_id, server_label, hostname, ip_address, os_type, scan_date, " +
                        "file_name, sys_version, last_time) VALUES(NULL,?,?,?,?,?,?,?,?)", Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, origLabel);
                    ps.setString(2, hostname);
                    ps.setString(3, origIp.isEmpty() ? null : origIp);
                    ps.setString(4, osType);
                    ps.setObject(5, scanDate);
                    ps.setString(6, originalName);
                    ps.setString(7, sysVersion != null ? sysVersion.substring(0, Math.min(sysVersion.length(), 65535)) : null);
                    ps.setString(8, lastTime != null ? lastTime.substring(0, Math.min(lastTime.length(), 100)) : null);
                    ps.executeUpdate();
                    try (ResultSet rs = ps.getGeneratedKeys()) { followupScanId = rs.next() ? rs.getInt(1) : -1; }
                }
                if (followupScanId == -1) return;

                NodeList itemNodes = doc.getElementsByTagName("Item");
                int ok = 0, vuln = 0, manual = 0;
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO security_scan_item(scan_id, i_code, i_title, inspection_code, original_result, result, evidence) VALUES(?,?,?,?,?,?,?)")) {
                    for (int i = 0; i < itemNodes.getLength(); i++) {
                        Element el = (Element) itemNodes.item(i);
                        String result = normalizeResult(nvl(getElText(el, "Result")).trim());
                        if ("양호".equals(result)) ok++;
                        else if ("취약".equals(result)) vuln++;
                        else manual++;
                        ps.setInt(1, followupScanId);
                        ps.setString(2, getElText(el, "iCode"));
                        ps.setString(3, getElText(el, "iTitle"));
                        ps.setString(4, getElText(el, "InspectionCode"));
                        ps.setString(5, result); ps.setString(6, result);
                        ps.setString(7, nvl(getElText(el, "Evidence")).trim());
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE security_scan SET total_count=?, ok_count=?, vuln_count=?, manual_count=? WHERE scan_id=?")) {
                    ps.setInt(1, ok+vuln+manual); ps.setInt(2, ok); ps.setInt(3, vuln);
                    ps.setInt(4, manual); ps.setInt(5, followupScanId); ps.executeUpdate();
                }
                File txtFile = null, refFile = null;
                for (File f : tmpDir.listFiles()) {
                    if (f.getName().endsWith("_REF.txt")) refFile = f;
                    else if (f.getName().endsWith(".txt")) txtFile = f;
                }
                Map<String, String> txtMap = txtFile != null ? parseTxtFile(txtFile) : new HashMap<>();
                Map<String, String> refMap = refFile != null ? parseTxtFile(refFile) : new HashMap<>();
                if (!txtMap.isEmpty() || !refMap.isEmpty()) {
                    try (PreparedStatement ps = conn.prepareStatement(
                            "UPDATE security_scan_item SET txt_evidence=?, ref_evidence=? WHERE scan_id=? AND i_code=?")) {
                        for (int i = 0; i < itemNodes.getLength(); i++) {
                            Element el = (Element) itemNodes.item(i);
                            String iCode = getElText(el, "iCode");
                            String tv = txtMap.containsKey(iCode) ? txtMap.get(iCode) : null;
                            String rv = refMap.containsKey(iCode) ? refMap.get(iCode) : null;
                            if (tv != null || rv != null) {
                                psBatchTxt(ps, tv, rv, followupScanId, iCode);
                            }
                        }
                        ps.executeBatch();
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE security_scan SET followup_scan_id=? WHERE scan_id=?")) {
                    ps.setInt(1, followupScanId); ps.setInt(2, scanId); ps.executeUpdate();
                }
            } finally {
                deleteDir(tmpDir);
            }
        } catch (Exception ignored) {}
    }

    private void psBatchTxt(PreparedStatement ps, String tv, String rv, int scanId, String iCode) throws SQLException {
        ps.setString(1, tv); ps.setString(2, rv); ps.setInt(3, scanId); ps.setString(4, iCode); ps.addBatch();
    }

    // ─────────────────────────────────────────────────────
    // 엑셀 다운로드 (unix_template.xlsx 템플릿 방식)
    // ─────────────────────────────────────────────────────
    private void doDownloadExcel(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String scanIdStr  = req.getParameter("scanId");
        String batchIdStr = req.getParameter("batchId");

        List<ScanVO> scans = new ArrayList<>();
        try (Connection conn = DBUtil.getConnection()) {
            String sql;
            if (batchIdStr != null) {
                sql = "SELECT scan_id, server_label, hostname, ip_address, os_type, scan_date, uploaded_at, " +
                      "file_name, total_count, ok_count, vuln_count, manual_count, followup_scan_id " +
                      "FROM security_scan WHERE batch_id=? ORDER BY scan_id";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, Integer.parseInt(batchIdStr));
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) scans.add(mapScan(rs));
                    }
                }
            } else if (scanIdStr != null) {
                sql = "SELECT scan_id, server_label, hostname, ip_address, os_type, scan_date, uploaded_at, " +
                      "file_name, total_count, ok_count, vuln_count, manual_count, followup_scan_id " +
                      "FROM security_scan WHERE scan_id=?";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, Integer.parseInt(scanIdStr));
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) scans.add(mapScan(rs));
                    }
                }
            }

            if (scans.isEmpty()) { resp.sendError(404, "스캔 데이터 없음"); return; }

            InputStream tpl = getServletContext().getResourceAsStream("/WEB-INF/template/unix_template.xlsx");
            if (tpl == null) { resp.sendError(500, "템플릿 파일 없음"); return; }

            try (XSSFWorkbook wb = new XSSFWorkbook(tpl)) {
                XSSFCreationHelper createHelper = wb.getCreationHelper();

                // ── "Ⅲ. 점검대상" 시트 ──────────────────────────
                // 헤더: B4=연번, C4=서버명, D4=HOSTNAME, E4=IP Address, F4=OS/Version, G4=비고
                // 데이터: Row5(index4) 부터
                XSSFSheet indexSheet = wb.getSheet("Ⅲ. 점검대상");
                if (indexSheet != null) {
                    // 첫 번째 데이터행 스타일 복사용
                    Row styleRow = indexSheet.getRow(4);
                    for (int i = 0; i < scans.size(); i++) {
                        ScanVO s = scans.get(i);
                        Row row = (i == 0 && styleRow != null) ? styleRow : indexSheet.createRow(4 + i);
                        setCell(row, 1, String.valueOf(i + 1));
                        setCell(row, 2, nvlLabel(s.serverLabel, s.hostname));
                        setCell(row, 3, s.hostname);
                        setCell(row, 4, s.ipAddress);
                        setCell(row, 5, s.osType);
                        setCell(row, 6, "");
                    }
                }

                // ── "template" 시트 (서버별 복제) ────────────────
                // 서버정보: C4=서버이름, F4=OS/Version, C5=HOSTNAME, C6=IP Address
                // 항목: Row12(index11)~Row78(index77) → C=순번, D=점검항목, I=현황, K=결과
                XSSFSheet tmplSheet = wb.getSheet("template");
                if (tmplSheet != null) {
                    int tmplIdx = wb.getSheetIndex(tmplSheet);
                    for (int si = 0; si < scans.size(); si++) {
                        ScanVO scan = scans.get(si);
                        XSSFSheet sheet;
                        if (scans.size() == 1) {
                            sheet = tmplSheet;
                        } else {
                            String sheetName = truncate(nvlLabel(scan.serverLabel, scan.hostname), 31);
                            sheet = wb.cloneSheet(tmplIdx, sheetName);
                        }
                        sheet.setTabColor(new XSSFColor(new byte[]{(byte)0xA6, (byte)0xC9, (byte)0xEC}, null));

                        // 서버 정보 셀 채우기 (라벨 옆 값 셀)
                        setSheetCell(sheet, 3, 2, nvlLabel(scan.serverLabel, scan.hostname)); // C4
                        setSheetCell(sheet, 3, 5, scan.osType);                               // F4
                        setSheetCell(sheet, 4, 2, scan.hostname);                             // C5
                        setSheetCell(sheet, 5, 2, scan.ipAddress);                            // C6

                        // 항목 행 채우기 (Row12~78, 0-based index 11~77)
                        List<ScanItemVO> items = loadItems(conn, scan.scanId);
                        int maxRow = 77; // index 77 = row 78
                        for (int ii = 0; ii < items.size() && (11 + ii) <= maxRow; ii++) {
                            ScanItemVO item = items.get(ii);
                            Row row = sheet.getRow(11 + ii);
                            if (row == null) row = sheet.createRow(11 + ii);
                            setCell(row, 8, item.result);  // I: 결과
                            setCell(row, 10, buildEvidence(item.evidence, item.txtEvidence, item.refEvidence, item.evidenceTypes)); // K: 현황
                        }
                        if (scan.followupScanId > 0) {
                            List<ScanItemVO> fuItems = loadItems(conn, scan.followupScanId);
                            for (int ii = 0; ii < fuItems.size() && (11 + ii) <= maxRow; ii++) {
                                ScanItemVO fuItem = fuItems.get(ii);
                                Row row = sheet.getRow(11 + ii);
                                if (row == null) row = sheet.createRow(11 + ii);
                                setCell(row, 14, fuItem.result);  // O: 이행점검 결과
                                setCell(row, 15, buildEvidence(fuItem.evidence, fuItem.txtEvidence, fuItem.refEvidence, fuItem.evidenceTypes)); // P: 이행점검 현황
                            }
                        }
                    }
                    // 배치: 원본 template 시트 삭제
                    if (scans.size() > 1) {
                        wb.removeSheetAt(wb.getSheetIndex(wb.getSheet("template")));
                    }
                }

                // "Ⅳ. 보안점검 결과" 시트: G4부터 서버명 가로 나열, 아래로 결과 채움
                XSSFSheet resultSheet = wb.getSheet("Ⅳ. 보안점검 결과");
                if (resultSheet != null) {
                    // 헤더 스타일: F4(row=3, col=5) 서식 복제
                    XSSFCellStyle headerStyle = wb.createCellStyle();
                    Row f4Row = resultSheet.getRow(3);
                    if (f4Row != null) {
                        Cell f4Cell = f4Row.getCell(5);
                        if (f4Cell != null) headerStyle.cloneStyleFrom(f4Cell.getCellStyle());
                    }
                    // 결과 셀 스타일: 4면 얇은 테두리 + 맑은 고딕 8pt + 가로/세로 중앙 정렬
                    XSSFFont resultFont = wb.createFont();
                    resultFont.setFontName("맑은 고딕");
                    resultFont.setFontHeightInPoints((short) 8);
                    XSSFCellStyle borderStyle = wb.createCellStyle();
                    borderStyle.setBorderTop(BorderStyle.THIN);
                    borderStyle.setBorderBottom(BorderStyle.THIN);
                    borderStyle.setBorderLeft(BorderStyle.THIN);
                    borderStyle.setBorderRight(BorderStyle.THIN);
                    borderStyle.setFont(resultFont);
                    borderStyle.setAlignment(HorizontalAlignment.CENTER);
                    borderStyle.setVerticalAlignment(VerticalAlignment.CENTER);
                    // 합계 행 스타일: 맑은 고딕 8pt + 가운데 정렬 + 4면 테두리
                    XSSFFont sumFont4 = wb.createFont();
                    sumFont4.setFontName("맑은 고딕");
                    sumFont4.setFontHeightInPoints((short) 8);
                    XSSFCellStyle sumStyle4 = wb.createCellStyle();
                    sumStyle4.setFont(sumFont4);
                    sumStyle4.setAlignment(HorizontalAlignment.CENTER);
                    sumStyle4.setVerticalAlignment(VerticalAlignment.CENTER);
                    sumStyle4.setBorderTop(BorderStyle.THIN);
                    sumStyle4.setBorderBottom(BorderStyle.THIN);
                    sumStyle4.setBorderLeft(BorderStyle.THIN);
                    sumStyle4.setBorderRight(BorderStyle.THIN);
                    // 점수 행 스타일: 맑은 고딕 8pt + 가운데 정렬 + 4면 테두리 + 퍼센트 서식
                    XSSFFont pctFont4 = wb.createFont();
                    pctFont4.setFontName("맑은 고딕");
                    pctFont4.setFontHeightInPoints((short) 8);
                    XSSFCellStyle pctStyle4 = wb.createCellStyle();
                    pctStyle4.setFont(pctFont4);
                    pctStyle4.setAlignment(HorizontalAlignment.CENTER);
                    pctStyle4.setVerticalAlignment(VerticalAlignment.CENTER);
                    pctStyle4.setBorderTop(BorderStyle.THIN);
                    pctStyle4.setBorderBottom(BorderStyle.THIN);
                    pctStyle4.setBorderLeft(BorderStyle.THIN);
                    pctStyle4.setBorderRight(BorderStyle.THIN);
                    pctStyle4.setDataFormat(wb.createDataFormat().getFormat("0%"));

                    for (int si = 0; si < scans.size(); si++) {
                        ScanVO scan = scans.get(si);
                        int colIdx = 6 + si;
                        String targetSheet4 = scans.size() == 1 ? "template"
                            : truncate(nvlLabel(scan.serverLabel, scan.hostname), 31);
                        // 헤더 셀 값 + F4 스타일 + 내부 링크
                        setSheetCell(resultSheet, 3, colIdx, nvlLabel(scan.serverLabel, scan.hostname));
                        Row headerRow = resultSheet.getRow(3);
                        if (headerRow != null) {
                            Cell headerCell = headerRow.getCell(colIdx);
                            if (headerCell != null) {
                                headerCell.setCellStyle(headerStyle);
                                XSSFHyperlink link4 = (XSSFHyperlink) createHelper.createHyperlink(HyperlinkType.DOCUMENT);
                                link4.setAddress("'" + targetSheet4.replace("'", "''") + "'!A1");
                                headerCell.setHyperlink(link4);
                            }
                        }
                        // 결과 셀: 서버 상세 시트 I 컬럼 수식 참조 + 테두리 스타일
                        List<ScanItemVO> items = loadItems(conn, scan.scanId);
                        String escapedName4 = targetSheet4.replace("'", "''");
                        String colLetter4 = CellReference.convertNumToColString(colIdx);
                        for (int ii = 0; ii < items.size() && (4 + ii) <= 70; ii++) {
                            int rowIdx = 4 + ii;
                            Row resultRow = resultSheet.getRow(rowIdx);
                            if (resultRow == null) resultRow = resultSheet.createRow(rowIdx);
                            Cell resultCell = resultRow.getCell(colIdx);
                            if (resultCell == null) resultCell = resultRow.createCell(colIdx);
                            resultCell.setCellFormula("'" + escapedName4 + "'!I" + (12 + ii));
                            resultCell.setCellStyle(borderStyle);
                        }
                        // 서버별 취약 합계 (행 72~75, 0-indexed 71~74)
                        setSheetFormula(resultSheet, 71, colIdx,
                            "COUNTIF(" + colLetter4 + "5:" + colLetter4 + "71,\"취약\")");
                        resultSheet.getRow(71).getCell(colIdx).setCellStyle(sumStyle4);
                        setSheetFormula(resultSheet, 72, colIdx,
                            "COUNTIFS(" + colLetter4 + "5:" + colLetter4 + "71,\"취약\",$E$5:$E$71,\"상\")");
                        resultSheet.getRow(72).getCell(colIdx).setCellStyle(sumStyle4);
                        setSheetFormula(resultSheet, 73, colIdx,
                            "COUNTIFS(" + colLetter4 + "5:" + colLetter4 + "71,\"취약\",$E$5:$E$71,\"중\")");
                        resultSheet.getRow(73).getCell(colIdx).setCellStyle(sumStyle4);
                        setSheetFormula(resultSheet, 74, colIdx,
                            "COUNTIFS(" + colLetter4 + "5:" + colLetter4 + "71,\"취약\",$E$5:$E$71,\"하\")");
                        resultSheet.getRow(74).getCell(colIdx).setCellStyle(sumStyle4);
                        // 서버별 점수 행 76 (0-indexed 75): 상세 시트 K79 참조 + 퍼센트 서식
                        setSheetFormula(resultSheet, 75, colIdx,
                            "'" + escapedName4 + "'!K79");
                        resultSheet.getRow(75).getCell(colIdx).setCellStyle(pctStyle4);
                    }
                    // F76: 전체 서버 보안점검 점수 평균 + 퍼센트 서식
                    setSheetFormula(resultSheet, 75, 5, "AVERAGE(G76:XFD76)");
                    resultSheet.getRow(75).getCell(5).setCellStyle(pctStyle4);
                }

                // ── "Ⅴ. 이행점검 결과" 시트: G4부터 서버명, 아래로 이행점검 결과
                XSSFSheet followupSheet = wb.getSheet("Ⅴ. 이행점검 결과");
                if (followupSheet != null) {
                    XSSFCellStyle fuHeaderStyle = wb.createCellStyle();
                    Row fu4Row = followupSheet.getRow(3);
                    if (fu4Row != null) {
                        Cell fu4Cell = fu4Row.getCell(5);
                        if (fu4Cell != null) fuHeaderStyle.cloneStyleFrom(fu4Cell.getCellStyle());
                    }
                    XSSFFont fuFont = wb.createFont();
                    fuFont.setFontName("맑은 고딕");
                    fuFont.setFontHeightInPoints((short) 8);
                    XSSFCellStyle fuBorderStyle = wb.createCellStyle();
                    fuBorderStyle.setBorderTop(BorderStyle.THIN);
                    fuBorderStyle.setBorderBottom(BorderStyle.THIN);
                    fuBorderStyle.setBorderLeft(BorderStyle.THIN);
                    fuBorderStyle.setBorderRight(BorderStyle.THIN);
                    fuBorderStyle.setFont(fuFont);
                    fuBorderStyle.setAlignment(HorizontalAlignment.CENTER);
                    fuBorderStyle.setVerticalAlignment(VerticalAlignment.CENTER);
                    // 합계 행 스타일: 맑은 고딕 8pt + 가운데 정렬 + 4면 테두리
                    XSSFFont sumFont5 = wb.createFont();
                    sumFont5.setFontName("맑은 고딕");
                    sumFont5.setFontHeightInPoints((short) 8);
                    XSSFCellStyle sumStyle5 = wb.createCellStyle();
                    sumStyle5.setFont(sumFont5);
                    sumStyle5.setAlignment(HorizontalAlignment.CENTER);
                    sumStyle5.setVerticalAlignment(VerticalAlignment.CENTER);
                    sumStyle5.setBorderTop(BorderStyle.THIN);
                    sumStyle5.setBorderBottom(BorderStyle.THIN);
                    sumStyle5.setBorderLeft(BorderStyle.THIN);
                    sumStyle5.setBorderRight(BorderStyle.THIN);
                    // 점수 행 스타일: 맑은 고딕 8pt + 가운데 정렬 + 4면 테두리 + 퍼센트 서식
                    XSSFFont pctFont5 = wb.createFont();
                    pctFont5.setFontName("맑은 고딕");
                    pctFont5.setFontHeightInPoints((short) 8);
                    XSSFCellStyle pctStyle5 = wb.createCellStyle();
                    pctStyle5.setFont(pctFont5);
                    pctStyle5.setAlignment(HorizontalAlignment.CENTER);
                    pctStyle5.setVerticalAlignment(VerticalAlignment.CENTER);
                    pctStyle5.setBorderTop(BorderStyle.THIN);
                    pctStyle5.setBorderBottom(BorderStyle.THIN);
                    pctStyle5.setBorderLeft(BorderStyle.THIN);
                    pctStyle5.setBorderRight(BorderStyle.THIN);
                    pctStyle5.setDataFormat(wb.createDataFormat().getFormat("0%"));

                    for (int si = 0; si < scans.size(); si++) {
                        ScanVO scan = scans.get(si);
                        if (scan.followupScanId == 0) continue;
                        int colIdx = 6 + si;
                        String targetSheet5 = scans.size() == 1 ? "template"
                            : truncate(nvlLabel(scan.serverLabel, scan.hostname), 31);
                        setSheetCell(followupSheet, 3, colIdx, nvlLabel(scan.serverLabel, scan.hostname));
                        Row headerRow = followupSheet.getRow(3);
                        if (headerRow != null) {
                            Cell headerCell = headerRow.getCell(colIdx);
                            if (headerCell == null) headerCell = headerRow.createCell(colIdx);
                            headerCell.setCellStyle(fuHeaderStyle);
                            XSSFHyperlink link5 = (XSSFHyperlink) createHelper.createHyperlink(HyperlinkType.DOCUMENT);
                            link5.setAddress("'" + targetSheet5.replace("'", "''") + "'!A1");
                            headerCell.setHyperlink(link5);
                        }
                        List<ScanItemVO> fuItems = loadItems(conn, scan.followupScanId);
                        String escapedName5 = targetSheet5.replace("'", "''");
                        String colLetter5 = CellReference.convertNumToColString(colIdx);
                        for (int ii = 0; ii < fuItems.size() && (4 + ii) <= 70; ii++) {
                            int rowIdx = 4 + ii;
                            Row resultRow = followupSheet.getRow(rowIdx);
                            if (resultRow == null) resultRow = followupSheet.createRow(rowIdx);
                            Cell resultCell = resultRow.getCell(colIdx);
                            if (resultCell == null) resultCell = resultRow.createCell(colIdx);
                            resultCell.setCellFormula("'" + escapedName5 + "'!O" + (12 + ii));
                            resultCell.setCellStyle(fuBorderStyle);
                        }
                        // 서버별 취약 합계 (행 72~75, 0-indexed 71~74)
                        setSheetFormula(followupSheet, 71, colIdx,
                            "COUNTIF(" + colLetter5 + "5:" + colLetter5 + "71,\"취약\")");
                        followupSheet.getRow(71).getCell(colIdx).setCellStyle(sumStyle5);
                        setSheetFormula(followupSheet, 72, colIdx,
                            "COUNTIFS(" + colLetter5 + "5:" + colLetter5 + "71,\"취약\",$E$5:$E$71,\"상\")");
                        followupSheet.getRow(72).getCell(colIdx).setCellStyle(sumStyle5);
                        setSheetFormula(followupSheet, 73, colIdx,
                            "COUNTIFS(" + colLetter5 + "5:" + colLetter5 + "71,\"취약\",$E$5:$E$71,\"중\")");
                        followupSheet.getRow(73).getCell(colIdx).setCellStyle(sumStyle5);
                        setSheetFormula(followupSheet, 74, colIdx,
                            "COUNTIFS(" + colLetter5 + "5:" + colLetter5 + "71,\"취약\",$E$5:$E$71,\"하\")");
                        followupSheet.getRow(74).getCell(colIdx).setCellStyle(sumStyle5);
                        // 서버별 점수 행 76 (0-indexed 75): 상세 시트 Q79 참조 + 퍼센트 서식
                        setSheetFormula(followupSheet, 75, colIdx,
                            "'" + escapedName5 + "'!Q79");
                        followupSheet.getRow(75).getCell(colIdx).setCellStyle(pctStyle5);
                    }
                    // F76: 전체 서버 이행점검 점수 평균 + 퍼센트 서식
                    setSheetFormula(followupSheet, 75, 5, "AVERAGE(G76:XFD76)");
                    followupSheet.getRow(75).getCell(5).setCellStyle(pctStyle5);
                }

                String filename = (batchIdStr != null ? "batch_" + batchIdStr : "scan_" + scanIdStr) + "_result.xlsx";
                resp.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
                resp.setHeader("Content-Disposition",
                    "attachment; filename=\"" + filename + "\"; filename*=UTF-8''" + java.net.URLEncoder.encode(filename, "UTF-8"));
                wb.setForceFormulaRecalculation(true);
                wb.write(resp.getOutputStream());
            }
        } catch (Exception e) {
            resp.sendError(500, "엑셀 생성 오류: " + e.getMessage());
        }
    }

    private List<ScanItemVO> loadItems(Connection conn, int scanId) throws SQLException {
        List<ScanItemVO> list = new ArrayList<>();
        String sql = "SELECT item_id, i_code, i_title, inspection_code, original_result, result, evidence, txt_evidence, ref_evidence, memo, evidence_types " +
                     "FROM security_scan_item WHERE scan_id=? ORDER BY item_id";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, scanId);
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
                    item.txtEvidence    = nvl(rs.getString("txt_evidence"));
                    item.refEvidence    = nvl(rs.getString("ref_evidence"));
                    item.memo           = nvl(rs.getString("memo"));
                    String et = rs.getString("evidence_types");
                    item.evidenceTypes  = (et != null && !et.isEmpty()) ? et : "xml,txt,ref";
                    list.add(item);
                }
            }
        }
        return list;
    }

    private String buildEvidence(String xml, String txt, String ref, String evidenceTypes) {
        String types = (evidenceTypes != null && !evidenceTypes.isEmpty()) ? evidenceTypes : "xml,txt,ref";
        java.util.List<String[]> parts = new java.util.ArrayList<>();
        if (types.contains("xml") && !xml.isEmpty()) parts.add(new String[]{"[XML]", xml});
        if (types.contains("txt") && !txt.isEmpty()) parts.add(new String[]{"[TXT]", txt});
        if (types.contains("ref") && !ref.isEmpty()) parts.add(new String[]{"[REF]", ref});
        boolean showLabel = parts.size() >= 2;
        StringBuilder sb = new StringBuilder();
        for (String[] part : parts) {
            if (sb.length() > 0) sb.append("\n\n");
            if (showLabel) sb.append(part[0]).append("\n");
            sb.append(part[1]);
        }
        return sb.toString();
    }

    private void setCell(Row row, int col, String value) {
        Cell cell = row.getCell(col);
        if (cell == null) cell = row.createCell(col);
        cell.setCellValue(truncate(value != null ? value : "", 32767));
    }

    private void setSheetCell(XSSFSheet sheet, int rowIdx, int colIdx, String value) {
        Row row = sheet.getRow(rowIdx);
        if (row == null) row = sheet.createRow(rowIdx);
        Cell cell = row.getCell(colIdx);
        if (cell == null) cell = row.createCell(colIdx);
        cell.setCellValue(truncate(value != null ? value : "", 32767));
    }

    private void setSheetFormula(XSSFSheet sheet, int rowIdx, int colIdx, String formula) {
        Row row = sheet.getRow(rowIdx);
        if (row == null) row = sheet.createRow(rowIdx);
        Cell cell = row.getCell(colIdx);
        if (cell == null) cell = row.createCell(colIdx);
        cell.setCellFormula(formula);
    }

    private String nvlLabel(String label, String fallback) {
        return (label != null && !label.isEmpty()) ? label : nvl(fallback);
    }

    private String truncate(String s, int max) {
        if (s == null) return "";
        return s.length() <= max ? s : s.substring(0, max);
    }

    // ─────────────────────────────────────────────────────
    // 삭제
    // ─────────────────────────────────────────────────────
    protected void doDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String scanIdStr  = req.getParameter("scanId");
        String batchIdStr = req.getParameter("batchId");
        try (Connection conn = DBUtil.getConnection()) {
            if (batchIdStr != null) {
                int bid = Integer.parseInt(batchIdStr);
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE ss_fu FROM security_scan ss_fu " +
                        "INNER JOIN security_scan ss ON ss.followup_scan_id = ss_fu.scan_id " +
                        "WHERE ss.batch_id=?")) {
                    ps.setInt(1, bid);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "DELETE FROM security_scan_batch WHERE batch_id=?")) {
                    ps.setInt(1, bid);
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
        int    itemId       = Integer.parseInt(nvlD(req.getParameter("itemId"), "0"));
        String result       = nvl(req.getParameter("result")).trim();
        String memo         = nvl(req.getParameter("memo")).trim();
        String evidenceTypes = nvl(req.getParameter("evidenceTypes")).trim();
        if (evidenceTypes.isEmpty()) evidenceTypes = "xml,txt,ref";

        try (Connection conn = DBUtil.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE security_scan_item SET result=?, memo=?, evidence_types=? WHERE item_id=?")) {
                ps.setString(1, result);
                ps.setString(2, memo.isEmpty() ? null : memo);
                ps.setString(3, evidenceTypes);
                ps.setInt(4, itemId);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT scan_id FROM security_scan_item WHERE item_id=?")) {
                ps.setInt(1, itemId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) updateScanCounts(conn, rs.getInt(1));
                }
            }
            resp.getWriter().write("{\"ok\":true}");
        } catch (SQLException e) {
            resp.getWriter().write("{\"ok\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}");
        }
    }

    // ─────────────────────────────────────────────────────
    // 항목 현황 타입 조회 (카드 오픈 시 DB 직접 조회)
    // ─────────────────────────────────────────────────────
    private void doGetEvidenceTypes(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        int itemId = Integer.parseInt(nvlD(req.getParameter("itemId"), "0"));
        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT evidence_types FROM security_scan_item WHERE item_id=?")) {
            ps.setInt(1, itemId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String et = rs.getString("evidence_types");
                    if (et == null || et.isEmpty()) et = "xml,txt,ref";
                    resp.getWriter().write("{\"ok\":true,\"evidenceTypes\":\"" + et + "\"}");
                } else {
                    resp.getWriter().write("{\"ok\":false}");
                }
            }
        } catch (SQLException e) {
            resp.getWriter().write("{\"ok\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}");
        }
    }

    // ─────────────────────────────────────────────────────
    // 항목별 현황 타입 즉시 저장 (체크박스 onChange, JSON 응답)
    // ─────────────────────────────────────────────────────
    private void doSaveEvidenceTypes(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        int    itemId        = Integer.parseInt(nvlD(req.getParameter("itemId"), "0"));
        String evidenceTypes = nvl(req.getParameter("evidenceTypes")).trim();
        if (evidenceTypes.isEmpty()) evidenceTypes = "xml,txt,ref";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE security_scan_item SET evidence_types=? WHERE item_id=?")) {
            ps.setString(1, evidenceTypes);
            ps.setInt(2, itemId);
            ps.executeUpdate();
            resp.getWriter().write("{\"ok\":true}");
        } catch (SQLException e) {
            resp.getWriter().write("{\"ok\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}");
        }
    }

    // ─────────────────────────────────────────────────────
    // 서버 전체 현황 타입 일괄 수정 (JSON 응답)
    // ─────────────────────────────────────────────────────
    private void doBatchUpdateEvidenceTypes(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        int    scanId        = Integer.parseInt(nvlD(req.getParameter("scanId"), "0"));
        String evidenceTypes = nvl(req.getParameter("evidenceTypes")).trim();
        if (evidenceTypes.isEmpty()) evidenceTypes = "xml,txt,ref";

        try (Connection conn = DBUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "UPDATE security_scan_item SET evidence_types=? WHERE scan_id=?")) {
            ps.setString(1, evidenceTypes);
            ps.setInt(2, scanId);
            ps.executeUpdate();
            resp.getWriter().write("{\"ok\":true}");
        } catch (SQLException e) {
            resp.getWriter().write("{\"ok\":false,\"error\":\"" + escapeJson(e.getMessage()) + "\"}");
        }
    }

    // ─────────────────────────────────────────────────────
    // 헬퍼
    // ─────────────────────────────────────────────────────
    private void updateScanCounts(Connection conn, int scanId) throws SQLException {
        int ok = 0, vuln = 0, manual = 0;
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT result FROM security_scan_item WHERE scan_id=?")) {
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

    private Map<String, String> parseTxtFile(File f) {
        Map<String, String> map = new LinkedHashMap<>();
        try {
            String content = new String(java.nio.file.Files.readAllBytes(f.toPath()), "UTF-8");
            String[] sections = content.split("#{20,}");
            Pattern p = Pattern.compile("\\[(U-\\d+)[^\\]]*\\]");
            for (String section : sections) {
                Matcher m = p.matcher(section);
                if (m.find()) {
                    String code = m.group(1);
                    String rest = section.substring(m.end());
                    int nl = rest.indexOf('\n');
                    String body = (nl >= 0 ? rest.substring(nl + 1) : "").trim();
                    if (!body.isEmpty()) map.put(code, body);
                }
            }
        } catch (Exception ignored) {}
        return map;
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
        s.scanId         = rs.getInt("scan_id");
        s.serverLabel    = nvl(rs.getString("server_label"));
        s.hostname       = nvl(rs.getString("hostname"));
        s.ipAddress      = nvl(rs.getString("ip_address"));
        s.osType         = nvl(rs.getString("os_type"));
        s.scanDate       = nvl(rs.getString("scan_date"));
        s.uploadedAt     = nvl(rs.getString("uploaded_at"));
        s.fileName       = nvl(rs.getString("file_name"));
        s.totalCount     = rs.getInt("total_count");
        s.okCount        = rs.getInt("ok_count");
        s.vulnCount      = rs.getInt("vuln_count");
        s.manualCount    = rs.getInt("manual_count");
        s.followupScanId = rs.getInt("followup_scan_id");
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
        public int    scanId, totalCount, okCount, vulnCount, manualCount, followupScanId;
        public String serverLabel, hostname, ipAddress, osType, scanDate, uploadedAt, fileName;
    }

    public static class BatchVO {
        public int    batchId, serverCount;
        public String batchName, createdAt;
    }

    public static class ScanItemVO {
        public int    itemId;
        public String iCode, iTitle, inspectionCode, originalResult, result, evidence, txtEvidence, refEvidence, memo;
        public String evidenceTypes;
    }
}

package com.admin.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.*;
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
 *  GET  /SecurityScan?action=detail&scanId=N   → 상세 페이지
 *  GET  /SecurityScan?action=detail&batchId=N  → 배치 상세 (첫 번째 스캔)
 *  GET  /SecurityScan?action=downloadExcel     → 엑셀 다운로드 (scanId or batchId)
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
            case "detail"           -> doDetail(req, resp);
            case "downloadExcel"    -> doDownloadExcel(req, resp);
            case "getEvidenceTypes" -> doGetEvidenceTypes(req, resp);
            default                 -> doList(req, resp);
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
        List<ScanVO> scans = new ArrayList<>();
        List<BatchVO> batches = new ArrayList<>();
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
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
            String ssql = "SELECT scan_id, server_label, hostname, ip_address, os_type, scan_date, uploaded_at, " +
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
        resp.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
        resp.setHeader("Pragma", "no-cache");
        resp.setDateHeader("Expires", 0);
        String scanIdStr  = req.getParameter("scanId");
        String batchIdStr = req.getParameter("batchId");

        List<ScanVO> tabScans = new ArrayList<>();
        ScanVO currentScan = null;
        List<ScanItemVO> items = new ArrayList<>();

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            if (batchIdStr != null) {
                int batchId = Integer.parseInt(batchIdStr);
                String bsql = "SELECT scan_id, server_label, hostname, ip_address, os_type, scan_date, uploaded_at, " +
                              "file_name, total_count, ok_count, vuln_count, manual_count " +
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
                    if (firstScanId == -1) firstScanId = scanId;

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
    // 엑셀 다운로드 (unix_template.xlsx 템플릿 방식)
    // ─────────────────────────────────────────────────────
    private void doDownloadExcel(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String scanIdStr  = req.getParameter("scanId");
        String batchIdStr = req.getParameter("batchId");

        List<ScanVO> scans = new ArrayList<>();
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            String sql;
            if (batchIdStr != null) {
                sql = "SELECT scan_id, server_label, hostname, ip_address, os_type, scan_date, uploaded_at, " +
                      "file_name, total_count, ok_count, vuln_count, manual_count " +
                      "FROM security_scan WHERE batch_id=? ORDER BY scan_id";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    ps.setInt(1, Integer.parseInt(batchIdStr));
                    try (ResultSet rs = ps.executeQuery()) {
                        while (rs.next()) scans.add(mapScan(rs));
                    }
                }
            } else if (scanIdStr != null) {
                sql = "SELECT scan_id, server_label, hostname, ip_address, os_type, scan_date, uploaded_at, " +
                      "file_name, total_count, ok_count, vuln_count, manual_count " +
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
                    // 결과 셀 스타일: 4면 얇은 테두리 + 글씨 8pt + 가로/세로 중앙 정렬
                    XSSFFont resultFont = wb.createFont();
                    resultFont.setFontHeightInPoints((short) 8);
                    XSSFCellStyle borderStyle = wb.createCellStyle();
                    borderStyle.setBorderTop(BorderStyle.THIN);
                    borderStyle.setBorderBottom(BorderStyle.THIN);
                    borderStyle.setBorderLeft(BorderStyle.THIN);
                    borderStyle.setBorderRight(BorderStyle.THIN);
                    borderStyle.setFont(resultFont);
                    borderStyle.setAlignment(HorizontalAlignment.CENTER);
                    borderStyle.setVerticalAlignment(VerticalAlignment.CENTER);

                    for (int si = 0; si < scans.size(); si++) {
                        ScanVO scan = scans.get(si);
                        int colIdx = 6 + si;
                        // 헤더 셀 값 + F4 스타일
                        setSheetCell(resultSheet, 3, colIdx, nvlLabel(scan.serverLabel, scan.hostname));
                        Row headerRow = resultSheet.getRow(3);
                        if (headerRow != null) {
                            Cell headerCell = headerRow.getCell(colIdx);
                            if (headerCell != null) headerCell.setCellStyle(headerStyle);
                        }
                        // 결과 셀 값 + 테두리 스타일
                        List<ScanItemVO> items = loadItems(conn, scan.scanId);
                        for (int ii = 0; ii < items.size() && (4 + ii) <= 70; ii++) {
                            int rowIdx = 4 + ii;
                            setSheetCell(resultSheet, rowIdx, colIdx, items.get(ii).result);
                            Row resultRow = resultSheet.getRow(rowIdx);
                            if (resultRow != null) {
                                Cell resultCell = resultRow.getCell(colIdx);
                                if (resultCell != null) resultCell.setCellStyle(borderStyle);
                            }
                        }
                    }
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
        int    itemId       = Integer.parseInt(nvlD(req.getParameter("itemId"), "0"));
        String result       = nvl(req.getParameter("result")).trim();
        String memo         = nvl(req.getParameter("memo")).trim();
        String evidenceTypes = nvl(req.getParameter("evidenceTypes")).trim();
        if (evidenceTypes.isEmpty()) evidenceTypes = "xml,txt,ref";

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
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
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
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

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
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

        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
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
        s.scanId      = rs.getInt("scan_id");
        s.serverLabel = nvl(rs.getString("server_label"));
        s.hostname    = nvl(rs.getString("hostname"));
        s.ipAddress   = nvl(rs.getString("ip_address"));
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

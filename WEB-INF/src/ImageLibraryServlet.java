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
 * 이미지 라이브러리 서블릿
 *
 *  GET  /ImageLibraryServlet?action=list           → JSON 목록 (ADMIN)
 *  GET  /ImageLibraryServlet?action=listForPicker  → JSON 목록 (로그인 유저)
 *  POST /ImageLibraryServlet?action=upload         → 이미지 업로드 (ADMIN)
 *  POST /ImageLibraryServlet?action=delete         → 이미지 삭제 (ADMIN)
 */
@WebServlet("/ImageLibraryServlet")
@MultipartConfig(maxFileSize = 10_000_000, maxRequestSize = 15_000_000)
public class ImageLibraryServlet extends HttpServlet {

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

        if (!isLoggedIn(req)) { resp.sendError(401); return; }

        String action = nvl(req.getParameter("action"), "");
        switch (action) {
            case "list"          -> doList(req, resp, true);
            case "listForPicker" -> doList(req, resp, false);
            default              -> resp.sendError(404);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        if (!isLoggedIn(req))  { resp.sendError(401); return; }
        if (!isAdmin(req))     { resp.sendError(403); return; }

        String action = nvl(req.getParameter("action"), "");
        switch (action) {
            case "upload" -> doUpload(req, resp);
            case "delete" -> doImgDelete(req, resp);
            default       -> resp.sendError(404);
        }
    }

    // ─────────────────────────────────────────────────────
    // 목록 조회 → JSON
    // ─────────────────────────────────────────────────────
    private void doList(HttpServletRequest req, HttpServletResponse resp, boolean adminMode)
            throws IOException {

        String category = req.getParameter("category");
        String keyword  = req.getParameter("q");

        StringBuilder sb = new StringBuilder("[");
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            StringBuilder sql = new StringBuilder(
                "SELECT img_seq, img_name, file_path, file_size, content_type, category, uploaded_by, created_at " +
                "FROM tb_image_library WHERE is_deleted=0");
            List<Object> params = new ArrayList<>();
            if (category != null && !category.isEmpty() && !"전체".equals(category)) {
                sql.append(" AND category=?");
                params.add(category);
            }
            if (keyword != null && !keyword.isEmpty()) {
                sql.append(" AND img_name LIKE ?");
                params.add("%" + keyword + "%");
            }
            sql.append(" ORDER BY created_at DESC");

            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                for (int i = 0; i < params.size(); i++) ps.setObject(i + 1, params.get(i));
                ResultSet rs = ps.executeQuery();
                boolean first = true;
                while (rs.next()) {
                    if (!first) sb.append(",");
                    first = false;
                    sb.append("{");
                    sb.append("\"imgSeq\":").append(rs.getInt("img_seq")).append(",");
                    sb.append("\"imgName\":\"").append(escJson(rs.getString("img_name"))).append("\",");
                    sb.append("\"filePath\":\"").append(escJson(rs.getString("file_path"))).append("\",");
                    sb.append("\"fileSize\":").append(rs.getInt("file_size")).append(",");
                    sb.append("\"contentType\":\"").append(escJson(nvl(rs.getString("content_type"), ""))).append("\",");
                    sb.append("\"category\":\"").append(escJson(nvl(rs.getString("category"), "기타"))).append("\",");
                    sb.append("\"uploadedBy\":\"").append(escJson(nvl(rs.getString("uploaded_by"), ""))).append("\",");
                    sb.append("\"createdAt\":\"").append(escJson(nvl(rs.getString("created_at"), ""))).append("\"");
                    sb.append("}");
                }
            }
        } catch (Exception e) {
            resp.setContentType("application/json; charset=UTF-8");
            resp.getWriter().write("{\"error\":\"" + escJson(e.getMessage()) + "\"}");
            return;
        }
        sb.append("]");
        resp.setContentType("application/json; charset=UTF-8");
        resp.getWriter().write(sb.toString());
    }

    // ─────────────────────────────────────────────────────
    // 이미지 업로드
    // ─────────────────────────────────────────────────────
    private void doUpload(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String imgName  = nvl(req.getParameter("imgName"), "").trim();
        String category = nvl(req.getParameter("category"), "기타");
        String loginUser = (String) req.getSession().getAttribute("loginUser");

        if (imgName.isEmpty()) {
            jsonError(resp, "이름을 입력하세요.");
            return;
        }

        try {
            Part filePart = req.getPart("imageFile");
            if (filePart == null || filePart.getSize() == 0) {
                jsonError(resp, "파일을 선택하세요.");
                return;
            }
            String origName  = Paths.get(filePart.getSubmittedFileName()).getFileName().toString();
            String ext       = origName.contains(".") ? origName.substring(origName.lastIndexOf(".")).toLowerCase() : ".jpg";
            String savedName = "lib_" + System.currentTimeMillis() + "_" + UUID.randomUUID().toString().substring(0, 8) + ext;
            String uploadDir = getServletContext().getRealPath("/upload/library/");
            File dir = new File(uploadDir);
            if (!dir.exists() && !dir.mkdirs()) {
                jsonError(resp, "디렉터리 생성 실패");
                return;
            }
            filePart.write(uploadDir + File.separator + savedName);

            String filePath    = "upload/library/" + savedName;
            int    fileSize    = (int) filePart.getSize();
            String contentType = filePart.getContentType();

            try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
                 PreparedStatement ps = conn.prepareStatement(
                     "INSERT INTO tb_image_library (img_name, file_name, file_path, file_size, content_type, category, uploaded_by) VALUES (?,?,?,?,?,?,?)",
                     Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, imgName);
                ps.setString(2, savedName);
                ps.setString(3, filePath);
                ps.setInt(4, fileSize);
                ps.setString(5, contentType);
                ps.setString(6, category);
                ps.setString(7, loginUser);
                ps.executeUpdate();
                ResultSet keys = ps.getGeneratedKeys();
                int newSeq = keys.next() ? keys.getInt(1) : 0;
                resp.setContentType("application/json; charset=UTF-8");
                resp.getWriter().write("{\"ok\":true,\"imgSeq\":" + newSeq +
                    ",\"filePath\":\"" + escJson(filePath) + "\"" +
                    ",\"imgName\":\"" + escJson(imgName) + "\"" +
                    ",\"category\":\"" + escJson(category) + "\"}");
            }
        } catch (Exception e) {
            e.printStackTrace();
            jsonError(resp, e.getMessage() != null ? e.getMessage() : "업로드 실패");
        }
    }

    // ─────────────────────────────────────────────────────
    // 이미지 삭제 (소프트)
    // ─────────────────────────────────────────────────────
    private void doImgDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {

        String imgSeqStr = req.getParameter("imgSeq");
        if (imgSeqStr == null || imgSeqStr.isEmpty()) {
            jsonError(resp, "imgSeq 필요");
            return;
        }
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
             PreparedStatement ps = conn.prepareStatement(
                 "UPDATE tb_image_library SET is_deleted=1 WHERE img_seq=?")) {
            ps.setInt(1, Integer.parseInt(imgSeqStr));
            ps.executeUpdate();
            resp.setContentType("application/json; charset=UTF-8");
            resp.getWriter().write("{\"ok\":true}");
        } catch (Exception e) {
            e.printStackTrace();
            jsonError(resp, e.getMessage() != null ? e.getMessage() : "삭제 실패");
        }
    }

    // ── 유틸 ──────────────────────────────────────────────
    private boolean isLoggedIn(HttpServletRequest req) {
        return req.getSession(false) != null
            && req.getSession(false).getAttribute("loginUser") != null;
    }
    private boolean isAdmin(HttpServletRequest req) {
        if (!isLoggedIn(req)) return false;
        return "ADMIN".equals(req.getSession(false).getAttribute("loginRole"));
    }
    private String nvl(String s, String def) { return (s == null || s.isEmpty()) ? def : s; }
    private String escJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t");
    }
    private void jsonError(HttpServletResponse resp, String msg) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        resp.getWriter().write("{\"ok\":false,\"error\":\"" + escJson(msg) + "\"}");
    }
}

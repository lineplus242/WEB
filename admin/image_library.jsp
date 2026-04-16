<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    if (session.getAttribute("loginUser") == null) { response.sendRedirect("../login.jsp"); return; }
    String loginName = (String) session.getAttribute("loginName");
    String loginRole = (String) session.getAttribute("loginRole");
    if (!"ADMIN".equals(loginRole)) { response.sendRedirect("../main.jsp"); return; }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>이미지 라이브러리 - 관리 시스템</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <script>(function(){if(localStorage.getItem('theme')==='light')document.documentElement.setAttribute('data-theme','light');})()</script>
    <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500&family=DM+Mono:wght@400;500&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'DM Sans', sans-serif; background: #0e0f11; color: #e8e9eb; min-height: 100vh; display: flex; }

        .sidebar { width: 220px; background: #0b0c0f; border-right: 1px solid #1e2025; display: flex; flex-direction: column; position: fixed; top: 0; left: 0; height: 100vh; z-index: 100; }
        .sb-brand { display: flex; align-items: center; gap: 10px; padding: 20px 20px 16px; border-bottom: 1px solid #1e2025; }
        .sb-icon { width: 28px; height: 28px; background: #3b6ef5; border-radius: 7px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
        .sb-icon svg { width: 15px; height: 15px; fill: #fff; }
        .sb-name { font-size: 13px; font-weight: 500; color: #e8e9eb; }
        .sb-dot { color: #3b6ef5; }
        .sb-section { padding: 16px 20px 6px; font-size: 10px; font-weight: 500; color: #3d4251; letter-spacing: 0.08em; text-transform: uppercase; }
        .sb-item { display: flex; align-items: center; gap: 10px; padding: 8px 12px; border-radius: 7px; margin: 1px 8px; font-size: 13px; color: #6b7280; text-decoration: none; transition: background 0.12s; }
        .sb-item:hover { background: #161820; color: #c8cad0; }
        .sb-item.active { background: #1a1e2e; color: #6b9af5; }
        .sb-item svg { width: 15px; height: 15px; flex-shrink: 0; opacity: 0.7; }
        .sb-item.active svg { opacity: 1; }
        .sb-bottom { margin-top: auto; border-top: 1px solid #1e2025; padding: 12px; }
        .user-row { display:flex;align-items:center;gap:10px;padding:8px;border-radius:8px;cursor:pointer;transition:background .12s; }
        .user-row:hover,.user-row.open { background:#161820; }
        .avatar { width:30px;height:30px;border-radius:50%;background:#1a1e2e;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:500;color:#6b9af5;flex-shrink:0; }
        .user-info p { font-size:12px;font-weight:500;color:#c8cad0; }
        .user-info span { font-size:11px;color:#3d4251; }
        .user-chevron { width:12px;height:12px;margin-left:auto;flex-shrink:0;color:#3d4251;transition:transform .2s; }
        .user-row.open .user-chevron { transform:rotate(180deg); }
        .user-menu { display:none;background:#1a1c22;border:1px solid #252830;border-radius:10px;padding:5px;margin-bottom:4px; }
        .user-menu.open { display:block; }
        .user-menu-item { display:flex;align-items:center;gap:8px;padding:8px 10px;border-radius:7px;font-size:12px;color:#c8cad0;text-decoration:none;transition:background .12s;width:100%;border:none;background:none;cursor:pointer;font-family:inherit; }
        .user-menu-item:hover { background:#252830; }
        .user-menu-item.danger { color:#e05656; }
        .user-menu-item.danger:hover { background:#2a1015; }

        .main { margin-left: 220px; flex: 1; display: flex; flex-direction: column; }
        .topbar { height: 52px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; justify-content: space-between; padding: 0 28px; background: #0e0f11; position: sticky; top: 0; z-index: 50; }
        .topbar-title { font-size: 14px; font-weight: 500; color: #f2f3f5; }
        .content { padding: 28px; }

        /* 툴바 */
        .toolbar { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; flex-wrap: wrap; gap: 12px; }
        .toolbar-left { display: flex; align-items: center; gap: 10px; flex-wrap: wrap; }
        .search-wrap { position: relative; }
        .search-wrap input { background: #131519; border: 1px solid #1e2025; border-radius: 8px; padding: 8px 12px 8px 36px; font-size: 13px; color: #e8e9eb; font-family: 'DM Sans', sans-serif; outline: none; width: 220px; transition: border 0.15s; }
        .search-wrap input:focus { border-color: #3b6ef5; }
        .search-wrap svg { position: absolute; left: 10px; top: 50%; transform: translateY(-50%); width: 15px; height: 15px; color: #4b5161; pointer-events: none; }
        .cat-filter { background: #131519; border: 1px solid #1e2025; border-radius: 8px; padding: 8px 12px; font-size: 13px; color: #c8cad0; font-family: 'DM Sans', sans-serif; outline: none; cursor: pointer; }
        .cat-filter option { background: #131519; }

        .btn { padding: 8px 18px; border-radius: 8px; font-size: 13px; font-family: 'DM Sans', sans-serif; cursor: pointer; border: none; font-weight: 500; transition: background 0.15s; display: inline-flex; align-items: center; gap: 6px; }
        .btn-primary { background: #3b6ef5; color: #fff; }
        .btn-primary:hover { background: #2f5ee0; }
        .btn-danger { background: #1a0d0d; color: #e05656; border: 1px solid #2a0d0d; }
        .btn-danger:hover { background: #2a1010; }

        /* 이미지 그리드 */
        .img-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; }
        .img-card { background: #131519; border: 1px solid #1e2025; border-radius: 12px; overflow: hidden; transition: border-color 0.15s; }
        .img-card:hover { border-color: #2a2d3a; }
        .img-thumb { width: 100%; height: 140px; object-fit: contain; background: #0e0f11; display: block; cursor: zoom-in; }
        .img-thumb-empty { width: 100%; height: 140px; background: #0e0f11; display: flex; align-items: center; justify-content: center; color: #3d4251; }
        .img-info { padding: 12px; }
        .img-name { font-size: 13px; font-weight: 500; color: #c8cad0; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-bottom: 4px; }
        .img-meta { font-size: 11px; color: #4b5161; display: flex; align-items: center; justify-content: space-between; }
        .img-cat { display: inline-block; padding: 2px 8px; border-radius: 99px; font-size: 10px; font-weight: 500; background: #1a1e2e; color: #6b9af5; margin-top: 6px; }
        .img-footer { padding: 8px 12px; border-top: 1px solid #1e2025; display: flex; justify-content: flex-end; }

        /* 빈 상태 */
        .empty-state { text-align: center; padding: 80px 20px; color: #3d4251; }
        .empty-state svg { opacity: 0.3; margin-bottom: 16px; }
        .empty-state p { font-size: 14px; }

        /* 모달 */
        .modal-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.7); z-index: 999; align-items: center; justify-content: center; }
        .modal-overlay.open { display: flex; }
        .modal { background: #131519; border: 1px solid #252830; border-radius: 14px; width: 480px; max-width: 95vw; overflow: hidden; }
        .modal-header { padding: 18px 20px; border-bottom: 1px solid #1e2025; display: flex; align-items: center; justify-content: space-between; }
        .modal-title { font-size: 14px; font-weight: 500; color: #f2f3f5; }
        .modal-close { width: 28px; height: 28px; border-radius: 7px; border: none; background: none; color: #6b7280; cursor: pointer; font-size: 18px; display: flex; align-items: center; justify-content: center; transition: background 0.12s; }
        .modal-close:hover { background: #1e2025; color: #c8cad0; }
        .modal-body { padding: 20px; }
        .modal-footer { padding: 14px 20px; border-top: 1px solid #1e2025; display: flex; justify-content: flex-end; gap: 8px; }

        .form-group { display: flex; flex-direction: column; gap: 6px; margin-bottom: 16px; }
        .form-group:last-child { margin-bottom: 0; }
        label { font-size: 11px; font-weight: 500; color: #6b7280; letter-spacing: 0.06em; text-transform: uppercase; }
        label .req { color: #3b6ef5; margin-left: 2px; }
        input[type=text], select { background: #0e0f11; border: 1px solid #252830; border-radius: 8px; padding: 9px 12px; font-size: 13px; color: #e8e9eb; font-family: 'DM Sans', sans-serif; outline: none; transition: border 0.15s; width: 100%; }
        input:focus, select:focus { border-color: #3b6ef5; }

        /* 드래그앤드롭 업로드 영역 */
        .drop-zone { border: 2px dashed #252830; border-radius: 10px; padding: 32px 20px; text-align: center; cursor: pointer; transition: border-color 0.15s, background 0.15s; }
        .drop-zone:hover, .drop-zone.drag-over { border-color: #3b6ef5; background: rgba(59,110,245,0.04); }
        .drop-zone svg { color: #4b5161; margin-bottom: 10px; }
        .drop-zone p { font-size: 13px; color: #6b7280; }
        .drop-zone p strong { color: #6b9af5; }
        .drop-zone .file-hint { font-size: 11px; color: #3d4251; margin-top: 4px; }
        .drop-preview { width: 100%; max-height: 160px; object-fit: contain; border-radius: 8px; margin-top: 12px; display: none; }

        /* 이미지 확대 모달 */
        .zoom-overlay { display: none; position: fixed; inset: 0; background: rgba(0,0,0,0.9); z-index: 1100; align-items: center; justify-content: center; cursor: zoom-out; }
        .zoom-overlay.open { display: flex; }
        .zoom-overlay img { max-width: 90vw; max-height: 90vh; object-fit: contain; border-radius: 8px; }

        /* 토스트 */
        .toast { position: fixed; bottom: 28px; left: 50%; transform: translateX(-50%); background: #1a1c22; border: 1px solid #252830; border-radius: 10px; padding: 12px 20px; font-size: 13px; color: #c8cad0; z-index: 2000; display: none; }
        .toast.show { display: block; animation: fadeInUp 0.2s ease; }
        .toast.ok { border-color: rgba(34,201,122,0.4); color: #22c97a; }
        .toast.err { border-color: rgba(224,86,86,0.4); color: #e05656; }
        @keyframes fadeInUp { from { opacity:0; transform: translateX(-50%) translateY(8px); } to { opacity:1; transform: translateX(-50%) translateY(0); } }
    </style>
    <link rel="stylesheet" href="../style/light.css">
</head>
<body>
    <nav class="sidebar">
        <div class="sb-brand">
            <div class="sb-icon"><svg viewBox="0 0 24 24"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/></svg></div>
            <span class="sb-name">ADMIN<span class="sb-dot">.</span>SYS</span>
        </div>
        <div class="sb-section">메뉴</div>
        <a href="../main.jsp" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/></svg>
            대시보드
        </a>
        <a href="../CustomerServlet?action=list" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z"/><path d="M9 22V12h6v10"/></svg>
            고객사 정보
        </a>
        <a href="../UserServlet?action=list" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87M16 3.13a4 4 0 010 7.75"/></svg>
            사용자 관리
        </a>
        <div class="sb-section">계정</div>
        <a href="../UserServlet?action=changePw" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0110 0v4"/></svg>
            비밀번호 변경
        </a>
        <div class="sb-section">시스템</div>
        <a href="../settings.jsp" class="sb-item">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.07 4.93a10 10 0 010 14.14M4.93 4.93a10 10 0 000 14.14"/></svg>
            설정
        </a>
        <a href="image_library.jsp" class="sb-item active">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>
            이미지 라이브러리
        </a>
        <div class="sb-bottom">
            <div id="userMenu" class="user-menu">
                <a href="../mypage.jsp" class="user-menu-item">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px;flex-shrink:0"><path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>
                    마이페이지
                </a>
                <div style="height:1px;background:#252830;margin:4px 2px"></div>
                <a href="../LogoutServlet" class="user-menu-item danger">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px;flex-shrink:0"><path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/></svg>
                    로그아웃
                </a>
            </div>
            <div class="user-row" onclick="toggleUserMenu(this)">
                <div class="avatar"><%= loginName != null ? String.valueOf(loginName.charAt(0)) : "관" %></div>
                <div class="user-info"><p><%= loginName != null ? loginName : "관리자" %></p><span><%= loginRole %></span></div>
                <svg class="user-chevron" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="18 15 12 9 6 15"/></svg>
            </div>
        </div>
    </nav>

    <div class="main">
        <div class="topbar">
            <span class="topbar-title">이미지 라이브러리</span>
            <div class="theme-toggle">
                <button class="theme-toggle-btn" id="btnDark"  onclick="setTheme('dark')">다크모드</button>
                <button class="theme-toggle-btn" id="btnLight" onclick="setTheme('light')">라이트모드</button>
            </div>
        </div>
        <div class="content">
            <div class="toolbar">
                <div class="toolbar-left">
                    <div class="search-wrap">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
                        <input type="text" id="searchInput" placeholder="이미지 이름 검색..." oninput="debounceLoad()">
                    </div>
                    <select class="cat-filter" id="catFilter" onchange="loadImages()">
                        <option value="">전체</option>
                        <option value="서버">서버</option>
                        <option value="네트워크">네트워크</option>
                        <option value="보안">보안</option>
                        <option value="스토리지">스토리지</option>
                        <option value="기타">기타</option>
                    </select>
                </div>
                <button class="btn btn-primary" onclick="openUploadModal()">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:14px;height:14px"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                    이미지 추가
                </button>
            </div>

            <div id="imgGrid" class="img-grid"></div>
            <div id="emptyState" class="empty-state" style="display:none">
                <svg width="56" height="56" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>
                <p>등록된 이미지가 없습니다</p>
            </div>
        </div>
    </div>

    <!-- 업로드 모달 -->
    <div class="modal-overlay" id="uploadModal">
        <div class="modal">
            <div class="modal-header">
                <span class="modal-title">이미지 추가</span>
                <button class="modal-close" onclick="closeUploadModal()">×</button>
            </div>
            <div class="modal-body">
                <div class="form-group">
                    <label>이미지 이름 <span class="req">*</span></label>
                    <input type="text" id="upImgName" placeholder="예) HP DL380 전면">
                </div>
                <div class="form-group">
                    <label>카테고리</label>
                    <select id="upCategory">
                        <option value="서버">서버</option>
                        <option value="네트워크">네트워크</option>
                        <option value="보안">보안</option>
                        <option value="스토리지">스토리지</option>
                        <option value="기타" selected>기타</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>이미지 파일 <span class="req">*</span></label>
                    <div class="drop-zone" id="dropZone" onclick="document.getElementById('upFile').click()"
                         ondragover="onDragOver(event)" ondragleave="onDragLeave(event)" ondrop="onDrop(event)">
                        <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>
                        <p>클릭하거나 파일을 <strong>드래그</strong>하여 업로드</p>
                        <p class="file-hint">JPG, PNG, GIF, WEBP · 최대 10MB</p>
                        <img id="dropPreview" class="drop-preview" alt="미리보기">
                    </div>
                    <input type="file" id="upFile" accept="image/*" style="display:none" onchange="onFileChange(this)">
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn" style="background:#1a1c22;color:#9ca3af;border:1px solid #252830" onclick="closeUploadModal()">취소</button>
                <button class="btn btn-primary" onclick="submitUpload()">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="width:13px;height:13px"><path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4"/><polyline points="17 8 12 3 7 8"/><line x1="12" y1="3" x2="12" y2="15"/></svg>
                    업로드
                </button>
            </div>
        </div>
    </div>

    <!-- 이미지 확대 모달 -->
    <div class="zoom-overlay" id="zoomOverlay" onclick="closeZoom()">
        <img id="zoomImg" src="" alt="">
    </div>

    <!-- 토스트 -->
    <div class="toast" id="toast"></div>

    <script>
    let debTimer = null;
    function debounceLoad() { clearTimeout(debTimer); debTimer = setTimeout(loadImages, 300); }

    function loadImages() {
        const q   = document.getElementById('searchInput').value.trim();
        const cat = document.getElementById('catFilter').value;
        let url   = '../ImageLibraryServlet?action=list';
        if (q)   url += '&q='        + encodeURIComponent(q);
        if (cat) url += '&category=' + encodeURIComponent(cat);

        fetch(url).then(r => r.json()).then(data => {
            const grid  = document.getElementById('imgGrid');
            const empty = document.getElementById('emptyState');
            if (!Array.isArray(data) || data.length === 0) {
                grid.innerHTML = '';
                empty.style.display = 'block';
                return;
            }
            empty.style.display = 'none';
            grid.innerHTML = data.map(img => `
                <div class="img-card" id="card-${img.imgSeq}">
                    <img class="img-thumb" src="../${img.filePath}" alt="${esc(img.imgName)}"
                         onerror="this.style.display='none';this.nextElementSibling.style.display='flex'"
                         onclick="openZoom('../${img.filePath}')">
                    <div class="img-thumb-empty" style="display:none">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>
                    </div>
                    <div class="img-info">
                        <div class="img-name" title="${esc(img.imgName)}">${esc(img.imgName)}</div>
                        <div class="img-meta">
                            <span>${formatSize(img.fileSize)}</span>
                            <span>${img.createdAt ? img.createdAt.substring(0,10) : ''}</span>
                        </div>
                        <span class="img-cat">${esc(img.category)}</span>
                    </div>
                    <div class="img-footer">
                        <button class="btn btn-danger" style="padding:5px 12px;font-size:12px"
                                onclick="deleteImg(${img.imgSeq}, '${esc(img.imgName)}')">삭제</button>
                    </div>
                </div>
            `).join('');
        }).catch(e => showToast('목록 로드 실패: ' + e.message, 'err'));
    }

    // ── 업로드 모달 ──
    function openUploadModal() {
        document.getElementById('upImgName').value = '';
        document.getElementById('upCategory').value = '기타';
        document.getElementById('upFile').value = '';
        document.getElementById('dropPreview').style.display = 'none';
        document.getElementById('uploadModal').classList.add('open');
    }
    function closeUploadModal() { document.getElementById('uploadModal').classList.remove('open'); }

    function onFileChange(input) {
        if (!input.files || !input.files[0]) return;
        const reader = new FileReader();
        reader.onload = e => {
            const prev = document.getElementById('dropPreview');
            prev.src = e.target.result;
            prev.style.display = 'block';
        };
        reader.readAsDataURL(input.files[0]);
        // 파일명을 이름 인풋에 자동 채우기 (비어있을 때만)
        const nameInput = document.getElementById('upImgName');
        if (!nameInput.value.trim()) {
            nameInput.value = input.files[0].name.replace(/\.[^/.]+$/, '');
        }
    }

    function onDragOver(e) { e.preventDefault(); document.getElementById('dropZone').classList.add('drag-over'); }
    function onDragLeave(e) { document.getElementById('dropZone').classList.remove('drag-over'); }
    function onDrop(e) {
        e.preventDefault();
        document.getElementById('dropZone').classList.remove('drag-over');
        const file = e.dataTransfer.files[0];
        if (!file) return;
        const dt = new DataTransfer();
        dt.items.add(file);
        document.getElementById('upFile').files = dt.files;
        onFileChange(document.getElementById('upFile'));
    }

    function submitUpload() {
        const name = document.getElementById('upImgName').value.trim();
        const cat  = document.getElementById('upCategory').value;
        const file = document.getElementById('upFile').files[0];
        if (!name) { showToast('이름을 입력하세요.', 'err'); return; }
        if (!file) { showToast('파일을 선택하세요.', 'err'); return; }

        const fd = new FormData();
        fd.append('action',    'upload');
        fd.append('imgName',   name);
        fd.append('category',  cat);
        fd.append('imageFile', file);

        fetch('../ImageLibraryServlet', { method: 'POST', body: fd })
            .then(r => r.json())
            .then(d => {
                if (d.ok) {
                    closeUploadModal();
                    showToast('업로드 완료', 'ok');
                    loadImages();
                } else {
                    showToast('업로드 실패: ' + (d.error || ''), 'err');
                }
            }).catch(e => showToast('오류: ' + e.message, 'err'));
    }

    // ── 삭제 ──
    function deleteImg(imgSeq, imgName) {
        if (!confirm('"' + imgName + '"을 삭제하시겠습니까?\n이미 사용 중인 이미지는 영향받지 않습니다.')) return;
        const fd = new FormData();
        fd.append('action', 'delete');
        fd.append('imgSeq', imgSeq);
        fetch('../ImageLibraryServlet', { method: 'POST', body: fd })
            .then(r => r.json())
            .then(d => {
                if (d.ok) {
                    document.getElementById('card-' + imgSeq)?.remove();
                    showToast('삭제 완료', 'ok');
                    if (!document.querySelector('.img-card')) {
                        document.getElementById('emptyState').style.display = 'block';
                    }
                } else {
                    showToast('삭제 실패: ' + (d.error || ''), 'err');
                }
            });
    }

    // ── 확대 ──
    function openZoom(src) {
        document.getElementById('zoomImg').src = src;
        document.getElementById('zoomOverlay').classList.add('open');
    }
    function closeZoom() { document.getElementById('zoomOverlay').classList.remove('open'); }

    // ── 토스트 ──
    let toastTimer;
    function showToast(msg, type) {
        const t = document.getElementById('toast');
        t.textContent = msg;
        t.className = 'toast show ' + (type || '');
        clearTimeout(toastTimer);
        toastTimer = setTimeout(() => t.classList.remove('show'), 2800);
    }

    // ── 유틸 ──
    function esc(s) { return String(s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;'); }
    function formatSize(b) { if (!b) return ''; if (b < 1024) return b+'B'; if (b < 1048576) return (b/1024).toFixed(1)+'KB'; return (b/1048576).toFixed(1)+'MB'; }

    function toggleUserMenu(row){const m=document.getElementById('userMenu');if(!m)return;const o=m.classList.toggle('open');row.classList.toggle('open',o);}
    document.addEventListener('click',function(e){const m=document.getElementById('userMenu'),r=document.querySelector('.user-row');if(m&&r&&!r.contains(e.target)&&!m.contains(e.target)){m.classList.remove('open');r.classList.remove('open');}});
    document.addEventListener('keydown', e => { if (e.key === 'Escape') { closeUploadModal(); closeZoom(); } });

    loadImages();
    </script>
<script src="../js/common.js"></script>
<script>
    function setTheme(t){localStorage.setItem('theme',t);if(t==='light')document.documentElement.setAttribute('data-theme','light');else document.documentElement.removeAttribute('data-theme');document.getElementById('btnDark').classList.toggle('active',t!=='light');document.getElementById('btnLight').classList.toggle('active',t==='light');}
    (function(){var t=localStorage.getItem('theme')||'dark';document.getElementById('btnDark').classList.toggle('active',t!=='light');document.getElementById('btnLight').classList.toggle('active',t==='light');})();
</script>
</body>
</html>

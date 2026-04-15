-- =============================================
-- 사용자 테이블
-- =============================================
CREATE TABLE IF NOT EXISTS tb_user (
    user_seq    INT          NOT NULL AUTO_INCREMENT,
    user_id     VARCHAR(50)  NOT NULL,
    user_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(100) DEFAULT NULL,
    password    VARCHAR(128) NOT NULL,               -- SHA2-256 해시
    role        VARCHAR(20)  DEFAULT 'USER',         -- ADMIN / USER
    use_yn      CHAR(1)      DEFAULT 'Y',
    del_yn      CHAR(1)      DEFAULT 'N',
    reg_dt      DATETIME     DEFAULT NOW(),
    last_login  DATETIME     DEFAULT NULL,
    PRIMARY KEY (user_seq),
    UNIQUE KEY uq_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 로그인 이력 테이블
-- =============================================
CREATE TABLE IF NOT EXISTS tb_login_log (
    log_seq     INT         NOT NULL AUTO_INCREMENT,
    user_id     VARCHAR(50) DEFAULT NULL,
    ip_addr     VARCHAR(50) DEFAULT NULL,
    result      CHAR(1)     DEFAULT NULL,            -- S=성공, F=실패
    login_dt    DATETIME    DEFAULT NOW(),
    PRIMARY KEY (log_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 고객사 테이블
-- =============================================
CREATE TABLE IF NOT EXISTS tb_customer (
    cust_seq       INT          NOT NULL AUTO_INCREMENT,
    cust_code      VARCHAR(20)  DEFAULT NULL,        -- 자동생성: CUST-0001 형식
    cust_name      VARCHAR(200) NOT NULL,
    biz_no         VARCHAR(20)  DEFAULT NULL,        -- 사업자등록번호
    ceo_name       VARCHAR(100) DEFAULT NULL,
    address        TEXT         DEFAULT NULL,
    phone          VARCHAR(20)  DEFAULT NULL,
    email          VARCHAR(100) DEFAULT NULL,
    status         VARCHAR(20)  DEFAULT 'ACTIVE',
    memo           TEXT         DEFAULT NULL,
    del_yn         CHAR(1)      DEFAULT 'N',
    reg_dt         DATETIME     DEFAULT NOW(),
    reg_user       VARCHAR(100) DEFAULT NULL,
    upd_dt         DATETIME     DEFAULT NULL ON UPDATE NOW(),
    upd_user       VARCHAR(100) DEFAULT NULL,
    PRIMARY KEY (cust_seq),
    UNIQUE KEY uq_cust_code (cust_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 고객사 담당자 테이블
-- =============================================
CREATE TABLE IF NOT EXISTS tb_customer_manager (
    manager_seq   INT          NOT NULL AUTO_INCREMENT,
    cust_seq      INT          NOT NULL,
    manager_name  VARCHAR(100) DEFAULT NULL,
    manager_tel   VARCHAR(20)  DEFAULT NULL,
    manager_email VARCHAR(100) DEFAULT NULL,
    sort_order    INT          DEFAULT 0,
    PRIMARY KEY (manager_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 사업정보 테이블
-- =============================================
CREATE TABLE IF NOT EXISTS tb_project (
    proj_seq      INT          NOT NULL AUTO_INCREMENT,
    cust_seq      INT          NOT NULL,
    proj_name     VARCHAR(200) NOT NULL,
    contract_amt  BIGINT       DEFAULT 0,
    contract_start VARCHAR(10) DEFAULT NULL,
    contract_end   VARCHAR(10) DEFAULT NULL,
    status        VARCHAR(20)  DEFAULT 'ACTIVE',
    manager_name  VARCHAR(100) DEFAULT NULL,
    memo          TEXT         DEFAULT NULL,
    del_yn        CHAR(1)      DEFAULT 'N',
    reg_dt        DATETIME     DEFAULT NOW(),
    reg_user      VARCHAR(100) DEFAULT NULL,
    upd_dt        DATETIME     DEFAULT NULL ON UPDATE NOW(),
    upd_user      VARCHAR(100) DEFAULT NULL,
    PRIMARY KEY (proj_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 랙 테이블
-- =============================================
CREATE TABLE IF NOT EXISTS tb_rack (
    rack_seq    INT          NOT NULL AUTO_INCREMENT,
    cust_seq    INT          NOT NULL,
    rack_name   VARCHAR(100) NOT NULL,
    total_u     INT          DEFAULT 42,
    location    VARCHAR(200) DEFAULT NULL,
    memo        TEXT         DEFAULT NULL,
    del_yn      CHAR(1)      DEFAULT 'N',
    sort_order  INT          DEFAULT 0,
    reg_dt      DATETIME     DEFAULT NOW(),
    PRIMARY KEY (rack_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- 랙 유닛(슬롯) 테이블
-- =============================================
CREATE TABLE IF NOT EXISTS tb_rack_unit (
    unit_seq    INT          NOT NULL AUTO_INCREMENT,
    rack_seq    INT          NOT NULL,
    side        CHAR(1)      DEFAULT 'F',   -- F=전면, B=후면
    start_u     INT          NOT NULL,
    size_u      INT          DEFAULT 1,
    device_name VARCHAR(200) NOT NULL,
    device_type VARCHAR(50)  DEFAULT 'SERVER',
    ip_addr     TEXT         DEFAULT NULL,
    memo        TEXT         DEFAULT NULL,
    reg_dt      DATETIME     DEFAULT NOW(),
    PRIMARY KEY (unit_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =============================================
-- IT 자산 테이블
-- =============================================
CREATE TABLE IF NOT EXISTS tb_asset (
    asset_seq     INT          NOT NULL AUTO_INCREMENT,
    cust_seq      INT          NOT NULL,
    parent_seq    INT          DEFAULT NULL,  -- 부모 서버 seq (NULL=최상위)
    asset_type    VARCHAR(50)  NOT NULL,   -- SERVER / NETWORK / SECURITY / ETC
    asset_role    VARCHAR(20)  DEFAULT 'PHYSICAL', -- PHYSICAL/HYPERVISOR/VM/LDOM/ZONE/CONTAINER
    virt_type     VARCHAR(20)  DEFAULT NULL, -- VMWARE/KVM/LDOM/HYPERV/PROXMOX/XEN/CONTAINER
    asset_name    VARCHAR(200) NOT NULL,
    maker         VARCHAR(100) DEFAULT NULL,  -- 제조사
    model         VARCHAR(200) DEFAULT NULL,
    size_u        INT          DEFAULT NULL,  -- 랙 장착 크기 (1U, 2U 등), NULL=미적용
    hostname      VARCHAR(100) DEFAULT NULL,
    ip_addr       TEXT         DEFAULT NULL,
    disk          VARCHAR(200) DEFAULT NULL,
    cpu           VARCHAR(200) DEFAULT NULL,
    memory        VARCHAR(100) DEFAULT NULL,
    os_info       VARCHAR(100) DEFAULT NULL,
    location      VARCHAR(200) DEFAULT NULL,
    status        VARCHAR(20)  DEFAULT 'ACTIVE',
    purchase_dt   VARCHAR(10)  DEFAULT NULL,
    expire_dt     VARCHAR(10)  DEFAULT NULL,
    account_info  TEXT         DEFAULT NULL,  -- JSON: [{"username":"...","password":"..."}]
    memo          TEXT         DEFAULT NULL,
    del_yn        CHAR(1)      DEFAULT 'N',
    reg_dt        DATETIME     DEFAULT NOW(),
    reg_user      VARCHAR(100) DEFAULT NULL,
    upd_dt        DATETIME     DEFAULT NULL ON UPDATE NOW(),
    upd_user      VARCHAR(100) DEFAULT NULL,
    PRIMARY KEY (asset_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

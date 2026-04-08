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
-- IT 자산 테이블
-- =============================================
CREATE TABLE IF NOT EXISTS tb_asset (
    asset_seq     INT          NOT NULL AUTO_INCREMENT,
    cust_seq      INT          NOT NULL,
    asset_type    VARCHAR(50)  NOT NULL,   -- SERVER / NETWORK / SECURITY / ETC
    asset_name    VARCHAR(200) NOT NULL,
    model         VARCHAR(200) DEFAULT NULL,
    ip_addr       VARCHAR(50)  DEFAULT NULL,
    os_info       VARCHAR(100) DEFAULT NULL,
    location      VARCHAR(200) DEFAULT NULL,
    status        VARCHAR(20)  DEFAULT 'ACTIVE',
    purchase_dt   VARCHAR(10)  DEFAULT NULL,
    expire_dt     VARCHAR(10)  DEFAULT NULL,
    memo          TEXT         DEFAULT NULL,
    del_yn        CHAR(1)      DEFAULT 'N',
    reg_dt        DATETIME     DEFAULT NOW(),
    reg_user      VARCHAR(100) DEFAULT NULL,
    upd_dt        DATETIME     DEFAULT NULL ON UPDATE NOW(),
    upd_user      VARCHAR(100) DEFAULT NULL,
    PRIMARY KEY (asset_seq)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

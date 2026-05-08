package com.admin.servlet;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;

public class DBUtil {
    private static DataSource dataSource;

    public static Connection getConnection() throws SQLException {
        try {
            if (dataSource == null) {
                InitialContext ctx = new InitialContext();
                dataSource = (DataSource) ctx.lookup("java:comp/env/jdbc/adminDB");
            }
            return dataSource.getConnection();
        } catch (NamingException e) {
            throw new SQLException("JNDI DataSource 조회 실패: " + e.getMessage(), e);
        }
    }
}

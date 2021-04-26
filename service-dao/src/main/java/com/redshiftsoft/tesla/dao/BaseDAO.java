package com.redshiftsoft.tesla.dao;

import com.redshiftsoft.db.jdbc.SQLExceptions;
import kdw.common.string.StringTools;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceUtils;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import javax.sql.DataSource;
import java.sql.*;
import java.time.Instant;
import java.util.logging.Logger;

public abstract class BaseDAO {

    /**
     * Logger
     */
    protected static final Logger LOG = Logger.getLogger(BaseDAO.class.getName());

    @Autowired
    private JdbcTemplate jdbcTemplate;

    /**
     * Inject the datasource provider, rather than data source, because the data source can change at runtime.
     */
    @Autowired
    private DataSource dataSource;

    /**
     * Logs the given SQL exception and re-throws it as a unchecked runtime exception.
     */
    public static void logAndThrowUnchecked(final SQLException e) {
        SQLExceptions.logAndThrowUnchecked(e);
    }
    
    public static Instant getInstant(final ResultSet rs, int index) throws SQLException {
        Timestamp ts = rs.getTimestamp(index);
        if (ts == null) {
            return null;
        }
        return Instant.ofEpochMilli(ts.getTime());
    }

    /**
     * Execute an arbitrary query, with an arbitrary number of arguments. Returns the first column of the first row, which
     * must be an integer.
     *
     * @param query      this is the parametrized SQL query.
     * @param parameters zero or more parameters for the query.
     */
    public long getCount(final String query, final Object... parameters) {
        Long count = jdbcTemplate.queryForObject(query, Long.class, parameters);
        return count != null ? count : 0;
    }

    protected PreparedStatement getPreparedStatement(final String sql) {
        try {
            return getConnection().prepareStatement(sql);
        } catch (SQLException e) {
            logAndThrowUnchecked(e);
            return null;
        }
    }

    protected PreparedStatement getPreparedStatementWithKeys(final String sql) {
        try {
            return getConnection().prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS);
        } catch (SQLException e) {
            logAndThrowUnchecked(e);
            return null;
        }
    }

    protected Statement createStatement() throws SQLException {
        return getConnection().createStatement();
    }

    private Connection getConnection() {
        if (!TransactionSynchronizationManager.isSynchronizationActive()) {
            throw new IllegalStateException("No transaction for this thread: " + Thread.currentThread().getName());
        }
        return DataSourceUtils.getConnection(dataSource);
    }

    protected JdbcTemplate getJdbcTemplate() {
        return jdbcTemplate;
    }

    protected String trim(String in, int maxLength) {
        if (StringTools.isEmpty(in)) {
            return null;
        }
        in = in.trim();
        if (in.length() > maxLength) {
            in = in.substring(0, maxLength);
        }
        return in;
    }

}

@file:Suppress("SqlResolve")

package de.akquinet.ccsp.monitoring.test

import io.micrometer.core.instrument.simple.SimpleMeterRegistry
import org.hsqldb.jdbc.JDBCDataSource
import org.junit.jupiter.api.AfterEach

const val SQL_CREATE = "CREATE TABLE COMPANY(ID INT PRIMARY KEY, NAME VARCHAR(100))"
const val SQL_INSERT = "INSERT INTO COMPANY(ID, NAME) VALUES (?, ?)"
const val SQL_DELETE = "DELETE FROM COMPANY WHERE ID = 1"

const val JDBC_URL = "jdbc:hsqldb:mem:test"

private const val SHUTDOWN = "SHUTDOWN"

abstract class AbstractJDBCTest {
	protected val dataSource = JDBCDataSource().apply { setURL(JDBC_URL) }
	protected val registry = SimpleMeterRegistry()

	@AfterEach
	fun shutdown() {
		dataSource.connection.use {
			it.createStatement().execute(SHUTDOWN)
		}
	}
}
@file:Suppress("SqlResolve")

package de.akquinet.ccsp.monitoring.test

import de.akquinet.ccsp.monitoring.*
import de.akquinet.ccsp.monitoring.jdbc.hibernate.HibernateDriverMetrics
import de.akquinet.ccsp.monitoring.jdbc.wrapper.JDBCWrapper
import io.micrometer.core.instrument.Tags
import org.assertj.core.api.Assertions.assertThat
import org.hibernate.cfg.AvailableSettings.DRIVER
import org.hibernate.cfg.AvailableSettings.URL
import org.hibernate.engine.jdbc.connections.internal.DriverManagerConnectionProviderImpl
import org.hsqldb.jdbc.JDBCDriver
import org.junit.jupiter.api.Test
import java.util.concurrent.TimeUnit

class StatementMetricsTest : AbstractJDBCTest() {
	private val driverMetrics = HibernateDriverMetrics().apply {
		val provider = provider<DriverManagerConnectionProviderImpl>()
		provider.configure(mapOf(DRIVER to JDBCDriver::class.java.name, URL to JDBC_URL))
		bindTo(registry)
	}

	@Test
	fun `Count statements and executions`() {
		val sqlInsert1 = SQL_INSERT.replaceFirst("?", "1").replaceFirst("?", "'akquinet'")
		val sqlInsert2 = SQL_INSERT.replaceFirst("?", "2").replaceFirst("?", "'IBM'")

		driverMetrics.connection.use {
			it.createStatement().executeUpdate(SQL_CREATE)
			it.createStatement().executeUpdate(sqlInsert1)
			it.createStatement().executeUpdate(sqlInsert2)
			it.createStatement().executeUpdate(SQL_DELETE)
			it.createStatement().executeUpdate(sqlInsert1)
		}

		checkTimersAndCounters(sqlInsert1, sqlInsert2)
	}

	@Test
	fun `Count statements and executions with verbose name`() {
		val sqlInsert1 = SQL_INSERT.replaceFirst("?", "1").replaceFirst("?", "'akquinet'")
		val sqlInsert2 = SQL_INSERT.replaceFirst("?", "2").replaceFirst("?", "'IBM'")

		driverMetrics.connection.use {
			it.createStatement().executeUpdate(SQL_CREATE)

			val statement1 = it.createStatement()
			(statement1 as JDBCWrapper).name = "Insert values for akquinet"
			statement1.executeUpdate(sqlInsert1)

			val statement2 = it.createStatement()
			(statement2 as JDBCWrapper).name = "Insert values for IBM"
			statement2.executeUpdate(sqlInsert2)

			it.createStatement().executeUpdate(SQL_DELETE)

			val statement3 = it.createStatement()
			(statement3 as JDBCWrapper).name = "Insert values for akquinet"
			statement3.executeUpdate(sqlInsert1)
		}

		checkTimersAndCounters("Insert values for akquinet", "Insert values for IBM")
	}

	private fun checkTimersAndCounters(name1: String, name2: String) {
		assertThat(driverMetrics.registry().get(JDBC_STATEMENTS).functionCounter().count())
			.`as`("Number of statement instances").isEqualTo(5.0)
		assertThat(driverMetrics.functionCounterValue(JDBC_STATEMENTS).get())
			.`as`("Number of statement instances").isEqualTo(5)

		assertThat(statementCreations().tags(executionTags(name1)).functionCounter().count())
			.`as`("Executions of '$name1'").isEqualTo(2.0)
		assertThat(driverMetrics.functionCounterValue(JDBC_STATEMENTS_EXECUTE, executionTags(name1)).get())
			.`as`("Executions of '$name1'").isEqualTo(2)

		assertThat(statementCreations().tags(executionTags(name2)).functionCounter().count())
			.`as`("Executions of '$name2'").isEqualTo(1.0)
		assertThat(statementCreations().tags(executionTags(SQL_DELETE)).functionCounter().count())
			.`as`("Executions of '$SQL_DELETE'").isEqualTo(1.0)

		val timer = statementExecutions().tags(timerTags(name1)).timer()

		assertThat(timer.count()).`as`("Number of records for '$name1'").isEqualTo(2)
		assertThat(timer.totalTime(TimeUnit.MICROSECONDS)).`as`("Total time spent for '$name1'").isGreaterThan(0.0)
	}

	private fun executionTags(name: String) = Tags.of(TAG_STATEMENT_CREATION, name)
	private fun timerTags(name: String) = Tags.of(TAG_STATEMENT_EXECUTION, name)

	@Suppress("SameParameterValue")
	private fun statementCreations() = driverMetrics.registry().get(JDBC_STATEMENTS_EXECUTE)
	private fun statementExecutions() = driverMetrics.registry().get(JDBC_STATEMENT_TIMER)
}
@file:Suppress("SqlResolve")

package de.akquinet.ccsp.monitoring.test

import de.akquinet.ccsp.monitoring.*
import de.akquinet.ccsp.monitoring.jdbc.hibernate.HibernateDataSourceMetrics
import de.akquinet.ccsp.monitoring.jdbc.wrapper.JDBCWrapper
import io.micrometer.core.instrument.Tags
import org.assertj.core.api.Assertions.assertThat
import org.hibernate.cfg.Environment
import org.hibernate.engine.jdbc.connections.internal.DatasourceConnectionProviderImpl
import org.junit.jupiter.api.Test
import java.util.concurrent.TimeUnit

class PreparedStatementMetricsTest : AbstractJDBCTest() {
	private val dataSourceMetrics = HibernateDataSourceMetrics().apply {
		val provider = provider<DatasourceConnectionProviderImpl>()
		provider.dataSource = dataSource
		provider.configure(mapOf(Environment.DATASOURCE to dataSource))
		bindTo(registry)
	}

	@Test
	fun `Count prepared statements and executions`() {
		dataSourceMetrics.connection.use {
			it.prepareStatement(SQL_CREATE).execute()
			it.prepareStatement(SQL_INSERT).apply { setInt(1, 1); setString(2, "akquinet") }.executeUpdate()
			it.prepareStatement(SQL_INSERT).apply { setInt(1, 2); setString(2, "IBM") }.executeUpdate()
		}

		checkCountersAndTimers(SQL_CREATE, SQL_INSERT)
	}

	@Test
	fun `Prepared statements with verbose name`() {
		dataSourceMetrics.connection.use {
			val createStatement = it.prepareStatement(SQL_CREATE)

			// That's the canonical code
			if(createStatement.isWrapperFor(JDBCWrapper::class.java)) createStatement.unwrap(JDBCWrapper::class.java).name = "CREATE"
			createStatement.execute()

			// Since we know what we're doing, we can omit the check
			val statement1 = it.prepareStatement(SQL_INSERT)
			statement1.unwrap(JDBCWrapper::class.java).name = "INSERT"
			statement1.apply { setInt(1, 1); setString(2, "akquinet") }.executeUpdate()

			val statement2 = it.prepareStatement(SQL_INSERT)
			statement2.unwrap(JDBCWrapper::class.java).name = "INSERT"
			statement2.apply { setInt(1, 2); setString(2, "IBM") }.executeUpdate()
		}

		checkCountersAndTimers("CREATE", "INSERT")
	}

	private fun checkCountersAndTimers(createTag: String, insertTag: String) {
		assertThat(statementCreations().functionCounters().size).isEqualTo(2)
		assertThat(statementCreations().tags(callTags(createTag)).functionCounter().count())
			.`as`("Prepared statements for '$createTag'").isEqualTo(1.0)
		assertThat(statementCreations().tags(callTags(insertTag)).functionCounter().count())
			.`as`("Prepared statements for '$insertTag'").isEqualTo(2.0)

		val timer = statementExecutions().tags(executionTags(insertTag)).timer()

		assertThat(timer.count()).`as`("Number of records for '$insertTag'").isEqualTo(2)
		assertThat(timer.totalTime(TimeUnit.MICROSECONDS)).`as`("Total time spent for '$insertTag'").isGreaterThan(0.0)
	}

	@Test
	fun `Batched executions`() {
		dataSourceMetrics.connection.use {
			it.prepareStatement(SQL_CREATE).execute()
			val insertStatement = it.prepareStatement(SQL_INSERT)
			insertStatement.apply { setInt(1, 1); setString(2, "akquinet") }.addBatch()
			insertStatement.apply { setInt(1, 2); setString(2, "IBM") }.addBatch()
			insertStatement.executeBatch()
		}

		assertThat(statementCreations().functionCounters().size).isEqualTo(2)
		assertThat(statementCreations().tags(callTags(SQL_CREATE)).functionCounter().count())
			.`as`("Prepared statements for '$SQL_CREATE'").isEqualTo(1.0)
		assertThat(statementCreations().tags(callTags(SQL_INSERT)).functionCounter().count())
			.`as`("Prepared statements for '$SQL_INSERT'").isEqualTo(1.0)

		val batchedTimer = statementExecutions().tags(batchTags(SQL_INSERT)).timer()

		assertThat(batchedTimer.count()).`as`("Number of records for '$SQL_INSERT'").isEqualTo(1)
		assertThat(batchedTimer.totalTime(TimeUnit.MICROSECONDS)).`as`("Total time spent for '$SQL_INSERT'").isGreaterThan(0.0)
	}

	private fun callTags(sql: String) = Tags.of(TAG_PREPARED_STATEMENT_CREATION, sql)

	@Suppress("SameParameterValue")
	private fun executionTags(sql: String) = Tags.of(TAG_PREPARED_STATEMENT_EXECUTION, sql)
	@Suppress("SameParameterValue")
	private fun batchTags(sql: String) = Tags.of(TAG_PREPARED_STATEMENT_BATCHED_EXECUTION, sql)
	private fun statementCreations() = dataSourceMetrics.registry().get(JDBC_PREPARED_STATEMENTS)
	private fun statementExecutions() = dataSourceMetrics.registry().get(JDBC_PREPARED_STATEMENT_TIMER)
}
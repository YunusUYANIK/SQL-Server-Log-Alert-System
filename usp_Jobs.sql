﻿USE [DBA_DB]
GO
/****** Object:  StoredProcedure [dbo].[usp_Jobs]    Script Date: 7/19/2019 3:21:25 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.usp_Jobs') IS NULL
  EXEC ('CREATE PROCEDURE dbo.usp_Jobs AS RETURN 0;');
GO

ALTER PROCEDURE [dbo].[usp_Jobs]
			@OutputDatabaseName NVARCHAR(256) = NULL ,
			@OutputSchemaName NVARCHAR(256) = NULL ,
			@OutputTableName NVARCHAR(256) = NULL,
			@CleanupTime VARCHAR(3) = NULL,
			@LastTime INT = 1
		AS
		
	/*  If table not exists it created. */
	PRINT 'If table not exists it created.'

	DECLARE @StringToExecute VARCHAR(MAX)
	SET @StringToExecute = 'USE '
        + @OutputDatabaseName
        + '; IF EXISTS(SELECT * FROM '
        + @OutputDatabaseName
        + '.INFORMATION_SCHEMA.SCHEMATA WHERE QUOTENAME(SCHEMA_NAME) = '''
        + @OutputSchemaName
        + ''') AND NOT EXISTS (SELECT * FROM '
        + @OutputDatabaseName
        + '.INFORMATION_SCHEMA.TABLES WHERE QUOTENAME(TABLE_SCHEMA) = '''
        + @OutputSchemaName + ''' AND QUOTENAME(TABLE_NAME) = '''
        + @OutputTableName + ''') CREATE TABLE '
        + @OutputSchemaName + '.'
        + @OutputTableName
        + ' ([ID] [int] IDENTITY(1,1) NOT NULL,
			[check_date] [datetime] NULL,
			[sequence] int  NULL,
			[job_name] [varchar](3000) NULL,
			[step_name] [varchar](3000) NULL,
			[status] [varchar](100) NULL,
			[error_message] [varchar](max) NULL,
			[start_time] datetime NULL,
			[end_time] datetime NULL,
			[execution_time] [varchar](3000) NULL,
            PRIMARY KEY CLUSTERED (ID ASC))

			IF NOT EXISTS(SELECT * FROM sys.indexes WHERE object_id = object_id('''+@OutputTableName+''') AND NAME =''IX_SA_DBA_check_date'') 
		CREATE INDEX IX_SA_DBA_check_date ON '+@OutputTableName+' ([check_date]) WITH (FILLFACTOR=90);';
	

	EXEC(@StringToExecute);

	IF @CleanupTime IS NOT NULL
		BEGIN
			SET @StringToExecute = '
			DELETE FROM '+@OutputDatabaseName+'.'+@OutputSchemaName+'.'+@OutputTableName+' 
			WHERE check_date<GETDATE()-'+@CleanupTime+'';
			EXEC(@StringToExecute);
			
			/*  If @CleanupTime is not null. So, i clear it. */
			PRINT 'If @CleanupTime is not null. So, i clear it.'

		END


	DECLARE @checkdate datetime = GETDATE()
	DECLARE @MaxDate DATETIME
	IF @OutputDatabaseName IS NOT NULL AND @OutputSchemaName IS NOT NULL AND @OutputTableName IS NOT NULL
	BEGIN 
		SELECT @MaxDate=ISNULL((MAX(start_time)),GETDATE()-30) FROM Log_JobInfo
	END 
	ELSE BEGIN SET @MaxDate=GETDATE()-@LastTime END

	/*  I will import data on temp table. */
	PRINT 'I will import data on temp table.'

	IF OBJECT_ID('tempdb.dbo.#temp_job') IS NOT NULL
		DROP TABLE #temp_job

	CREATE TABLE #temp_job ([check_date] [datetime] NULL,
		[sequence] int  NULL,
		[job_name] [varchar](3000) NULL,
		[step_name] [varchar](3000) NULL,
		[status] [varchar](100) NULL,
		[error_message] [varchar](max) NULL,
		[start_time] datetime NULL,
		[end_time] datetime NULL,
		[execution_time] [varchar](3000) NULL)
		
		INSERT INTO #temp_job ([sequence],[check_date],[job_name],[step_name],[execution_time],[start_time],[status],[error_message])
			
			/*  I take fail jobs at this part. */
			SELECT
			[sequence] = 1
			,[check_date] = @checkdate
			,[job_name] = j.name
			,[step_name] = jh.step_name
			,[execution_time] = DATEADD(HOUR, (run_duration / 10000) % 100,
			DATEADD(MINUTE, (run_duration / 100) % 100,
			DATEADD(SECOND, (run_duration / 1) % 100, CAST('00:00:00' AS TIME(2)))))
			,msdb.dbo.agent_datetime(run_date, run_time) as [start_time]
			,[status] = CASE
			WHEN jh.run_status = 0 THEN 'Failed'
			WHEN jh.run_status = 1 THEN 'Succeded'
			WHEN jh.run_status = 2 THEN 'Retry'
			WHEN jh.run_status = 3 THEN 'Canceled'
			END
			,[error_message] = jh.message
			FROM msdb.dbo.sysjobhistory jh
			JOIN msdb.dbo.sysjobs j
			ON j.job_id = jh.job_id
				WHERE j.enabled = 1
				AND jh.run_status != 1
				AND jh.step_id!=0
				AND  msdb.dbo.agent_datetime(run_date, run_time)>= @MaxDate

			UNION
			/*  I take jobs that longer then other at this part. */
			SELECT
			[sequence] = 2
			,[check_date] = @checkdate
			,[job_name] = j.name
			,[step_name] = jh.step_name
			,[execution_time] = DATEADD(HOUR, (run_duration / 10000) % 100,
			DATEADD(MINUTE, (run_duration / 100) % 100,
			DATEADD(SECOND, (run_duration / 1) % 100, CAST('00:00:00' AS TIME(2)))))
			,msdb.dbo.agent_datetime(run_date, run_time) as [start_time]
			,[status] = CASE
			WHEN jh.run_status = 0 THEN 'Failed'
			WHEN jh.run_status = 1 THEN 'Succeded'
			WHEN jh.run_status = 2 THEN 'Retry'
			WHEN jh.run_status = 3 THEN 'Canceled'
			END
			,[error_message] = NULL
			FROM msdb.dbo.sysjobhistory jh
			JOIN msdb.dbo.sysjobs j
			ON j.job_id = jh.job_id
				WHERE j.enabled = 1
				AND jh.step_id = 0
				AND jh.run_status = 1
				AND jh.run_duration > 300
				AND  msdb.dbo.agent_datetime(run_date, run_time)>= @MaxDate

			UNION
			/*  I take other jobs that does not fail and not longer */
			SELECT
			[sequence] = 3
			,[check_date] = @checkdate
			,[job_name] = j.name
			,[step_name] = jh.step_name
			,[execution_time] = DATEADD(HOUR, (run_duration / 10000) % 100,
			DATEADD(MINUTE, (run_duration / 100) % 100,
			DATEADD(SECOND, (run_duration / 1) % 100, CAST('00:00:00' AS TIME(2)))))
			,msdb.dbo.agent_datetime(run_date, run_time) as [start_time]
			,[status] = CASE
			WHEN jh.run_status = 0 THEN 'Failed'
			WHEN jh.run_status = 1 THEN 'Succeded'
			WHEN jh.run_status = 2 THEN 'Retry'
			WHEN jh.run_status = 3 THEN 'Canceled'
			END
			,[error_message] = NULL
			FROM msdb.dbo.sysjobhistory jh
			JOIN msdb.dbo.sysjobs j
			ON j.job_id = jh.job_id
				WHERE j.enabled = 1
				AND jh.step_id = 0
				AND jh.run_status = 1
				AND jh.run_duration < 301
				--AND j.name NOT IN ('jobname')  
				--Listede gözükmesini istemediğin jobları buraya yazabilirsin
				AND  msdb.dbo.agent_datetime(run_date, run_time)>= @MaxDate

	IF @OutputDatabaseName IS NOT NULL AND @OutputSchemaName IS NOT NULL AND @OutputTableName IS NOT NULL
	BEGIN
		SET @StringToExecute = '
		INSERT INTO '+@OutputDatabaseName+'.'+@OutputSchemaName+'.'+@OutputTableName+' ([sequence],[check_date],[job_name],[step_name],[execution_time],[start_time],[status],[error_message])
		SELECT [sequence],[check_date],[job_name],[step_name],[execution_time],[start_time],[status],[error_message]
		FROM #temp_job';
		EXEC(@StringToExecute)

		/*  If you want move data to table, I will import on the live table. */
		PRINT 'If you want move data to table, I will import on the live table.'

	END

	IF @OutputDatabaseName IS NULL AND @OutputSchemaName IS NULL AND @OutputTableName IS NULL
	BEGIN
		SELECT * FROM #temp_job

		/*  If you want just see, I can show your data on the your results screen. */
		PRINT 'If you want just see, I can show your data on the your results screen.'

	END


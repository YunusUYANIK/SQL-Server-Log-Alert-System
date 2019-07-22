USE [DBA_DB]
GO

/****** Object:  Table [dbo].[ConfigThreshold]    Script Date: 7/19/2019 3:33:50 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[ConfigThreshold](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[customer_name] [varchar](255) NULL,
	[alert_group] [varchar](50) NULL,
	[is_active] [bit] NULL,
	[description] [varchar](500) NULL,
	[To] [varchar](50) NULL,
	[CC] [varchar](50) NULL,
	[BCC] [varchar](50) NULL,
	[profilename] [varchar](50) NULL,
	[value] [bigint] NULL,
	[last_check_date] [datetime] NULL,
	[last_mail_send] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO



DECLARE @customername varchar(100)=''
DECLARE @profilename varchar(100)=''
SET IDENTITY_INSERT ConfigThreshold ON
insert into ConfigThreshold (ID,customer_name,alert_group,is_active,[description],[To],CC,BCC,profilename,[value],last_check_date,last_mail_send)
VALUES
(1,@customername,'Job Failed',1,'Hata alan job.','dba@silikonakademi.com','','',@profilename,0,getdate()-1,getdate()-1),
(2,@customername,'Disk Size',1,'0-100 arasi deger alan free space disk orani.','dba@silikonakademi.com','','',@profilename,20,getdate()-1,getdate()-1),
(3,@customername,'CPU',1,'0-100 arasi deger alan cpu.','dba@silikonakademi.com','','',@profilename,80,getdate()-1,getdate()-1),
(4,@customername,'is_percent_growth',1,'bit deger alan is_percent_growth=0','dba@silikonakademi.com','','',@profilename,0,getdate()-1,getdate()-1),
(5,@customername,'TempDB Size MB',1,'KB deger alan tempdb size.','dba@silikonakademi.com','','',@profilename,350000,getdate()-1,getdate()-1),
(6,@customername,'AlwaysOn Latency',1,'Dakika deger alan AlwaysOn Latency.','dba@silikonakademi.com','','',@profilename,30,getdate()-1,getdate()-1),
(7,@customername,'Weekly Report',1,'Haftalik performans stats ve wait statistics raporlari.','dba@silikonakademi.com','','',@profilename,0,getdate()-1,getdate()-1),
(8,@customername,'Log File Size',1,'Log File büyüklügü Data File''in %75 veya üzeri ise.','dba@silikonakademi.com','','',@profilename,75,getdate()-1,getdate()-1)
SET IDENTITY_INSERT ConfigThreshold OFF

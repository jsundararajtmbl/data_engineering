USE [ODS]
GO
/****** Object:  StoredProcedure [dbo].[prc_load_equifax_file]    Script Date: 20/05/2025 10:55:35 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER   PROCEDURE [dbo].[prc_load_equifax_file]
	@filepath AS NVARCHAR(500)
AS
BEGIN

drop table if exists #XMLwithOpenXML

create table #XMLwithOpenXML(XMLData xml, LoadedDateTime DateTime)
declare @xml xml
declare @filename nvarchar(500)
declare @sql nvarchar(max)

--set  @filename ='\\devsam\Datawarehouse\Equifax_DP3\output\output.xml'
set  @filename = @filepath

set  @sql = 'INSERT INTO #XMLwithOpenXML(XMLData, LoadedDateTime) '
set  @sql = @sql +' SELECT CONVERT(XML, BulkColumn) AS BulkColumn, GETDATE() '
set  @sql = @sql +' FROM OPENROWSET(BULK ''' + @filename +''', SINGLE_BLOB) AS x;'

EXEC (@Sql)

SELECT @XML = XMLData FROM #XMLwithOpenXML

--SELECT @XML

DECLARE @XmlDocumentHandle int  
--DECLARE @xml XML
--SET @xml = (SELECT * FROM OPENROWSET (BULK '\\devsam\Datawarehouse\Equifax_DP3\output\output.xml', SINGLE_BLOB) as data)
-- --SET @xml = '(SELECT *  FROM OPENROWSET(BULK  ''' +  @filepath + '''  , SINGLE_BLOB) AS data)'
-- select @xml
 
EXEC sp_xml_preparedocument @XmlDocumentHandle OUTPUT, @xml 

truncate table dbo.ods_equifax_appln_details

insert into  dbo.ods_equifax_appln_details
([application_id],[final_decision],[application_status],[applicant_type],[title],[first_name],[surname],[marital_status],[gender]
,[dateOfBirth],[timeascustomer],[privacy_consent],[number_of_dependants],[number_of_ccards],[mobile_number],[email],[residential_status],[curr_property]
,[curr_property_suburb],[curr_property_postcode],[curr_property_state],[curr_property_timeat_address],[curr_property_unformatted_address],[pre_bs_score_card_name]
,[pre_bs_score],[post_bs_score_card_name],[post_bs_score],[vsa_score_card_id],[veda_score],[vsa_version],[vsa_type],[vsa_code],[vsa_value],[vsa_score_master_scale])

SELECT *  
FROM OPENXML (@XmlDocumentHandle, '/Applications/ConsumerTermBusinessDataExtract',2)  
WITH (ApplicationID     int         'applicationID'
		,final_decision VARCHAR(100) 'finalDecision'
		,application_status VARCHAR(100) 'status'
		,applicanttype varchar(50)         'applicants/applicant/applicantDetails/individualDetails/applicantType'
		,[title] [varchar](50)   'applicants/applicant/applicantDetails/individualDetails/title'
		,first_name VARCHAR(255)  'applicants/applicant/applicantDetails/individualDetails/firstName'
		----,middle_name VARCHAR(255) 
		,surname VARCHAR(255)  'applicants/applicant/applicantDetails/individualDetails/surname'	
		,marital_status VARCHAR(50) 'applicants/applicant/applicantDetails/individualDetails/maritalStatus'
		,gender VARCHAR(50) 'applicants/applicant/applicantDetails/individualDetails/gender',
		dateOfBirth DATE 'applicants/applicant/applicantDetails/individualDetails/dateOfBirth',
		timeascustomer INT 'applicants/applicant/applicantDetails/individualDetails/timeAsCustomer',
		privacy_consent varchar(10) 'applicants/applicant/applicantDetails/individualDetails/privacyConsent',
		number_of_dependants INT 'applicants/applicant/applicantDetails/individualDetails/numberOfDependants',
		number_of_ccards INT 'applicants/applicant/applicantDetails/individualDetails/numberOfCreditCards',
		mobile_number VARCHAR(50) 'applicants/applicant/applicantDetails/contactDetails/mobilePhone',
		email VARCHAR(255) 'applicants/applicant/applicantDetails/contactDetails/email',
		residential_status VARCHAR(100) 'applicants/applicant/applicantDetails/addressDetails/residentialStatus',
		curr_property VARCHAR(100) 'applicants/applicant/applicantDetails/addressDetails/currentAddress/property',
		curr_property_suburb VARCHAR(100) 'applicants/applicant/applicantDetails/addressDetails/currentAddress/suburb',
		curr_property_postcode VARCHAR(100) 'applicants/applicant/applicantDetails/addressDetails/currentAddress/postCode',
		curr_property_state VARCHAR(10) 'applicants/applicant/applicantDetails/addressDetails/currentAddress/state',
		curr_property_timeat_address int 'applicants/applicant/applicantDetails/addressDetails/currentAddress/timeAtAddress',
		curr_property_unformatted_address VARCHAR(500) 'applicants/applicant/applicantDetails/addressDetails/currentAddress/unformattedAddress',
		pre_bs_score_card_name VARCHAR(255) 'applicants/applicant/preBureauScoreResults/scorecardName',
		pre_bs_score VARCHAR(255) 'applicants/applicant/preBureauScoreResults/score',	
		post_bs_score_card_name VARCHAR(255) 'applicants/applicant/postBureauScoreResults/scorecardName',
		post_bs_score  VARCHAR(255) 'applicants/applicant/postBureauScoreResults/score',
		vsa_score_card_id VARCHAR(100) 'applicants/applicant/vsaScoreDetails/vsaScore/scorecardId',
		veda_score VARCHAR(100) 'applicants/applicant/vsaScoreDetails/vsaScore/name',
		vsa_version DECIMAL(10,2)'applicants/applicant/vsaScoreDetails/vsaScore/version',
		vsa_type VARCHAR(100) 'applicants/applicant/vsaScoreDetails/vsaScore/type',
		vsa_code VARCHAR(10)  'applicants/applicant/vsaScoreDetails/vsaScore/dataLevel/code',
		vsa_value VARCHAR(100) 'applicants/applicant/vsaScoreDetails/vsaScore/dataLevel/value',
		vsa_score_master_scale INT 'applicants/applicant/vsaScoreDetails/vsaScore/scoreMasterscale'
	  )  
EXEC sp_xml_removedocument @XmlDocumentHandle 

select * from dbo.ods_equifax_appln_details

END

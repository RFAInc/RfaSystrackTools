SELECT TRIM(cli.Company) Company
	,TRIM(l.name) LocationName
	,TRIM(c.name) ComputerName
    ,IF( /* If the number of apps found is 3, all apps are deployed */
		COUNT(c.computerid) = 3,
        'True',
        IF( /* If it's not 3, make sure it's less or throw a non-boolean error message */
			COUNT(c.computerid) < 3,
			'False',
            'Too Many Found'
		)
	) AS FullyDeployed
	,CONVERT(IF(c.OS like '%server%','Server',IF(c.BiosFlash like '%portable%','Laptop','WorkStation')) using utf8)  as AgentType
    ,c.Uptime UptimeInMins
	,( /* If the last bootup timestamp is greater than the most recent installed item, a reboot is NOT required */
		IF(
			DATE_SUB(NOW(), INTERVAL c.Uptime MINUTE) > 
            s.DateInstalled,
            'False','True'
        )
	) AS RequiresReboot
    ,DATE_SUB(NOW(), INTERVAL c.Uptime MINUTE) AS LastBootTime
    ,s.DateInstalled
    ,s.Name AS Software
	,c.LastUsername
	,c.OS
	,c.LastContact
	,l.locationid as LocationID
	,c.ComputerID
	,cli.clientid as ClientID -- */
FROM mastergroups AS mg
		LEFT JOIN subgroupwchildren AS sg ON mg.groupid=sg.groupid
			AND mg.fullname LIKE 'Software Deployment.SysTrack Cloud Agent.Deployed SysTrack'
		LEFT JOIN computers AS c ON sg.computerid=c.computerid
		LEFT JOIN clients AS cli ON c.clientid=cli.clientid
			AND cli.Company IS NOT NULL
		LEFT JOIN locations AS l ON c.locationid=l.locationid
JOIN software s ON c.computerid=s.computerid AND (
	s.Name = 'Systems Management Agent'
	OR 
    s.Name LIKE 'Microsoft Visual C++ 2015-2019 Redistributable%'
)
/* Only the most recently installed app is relevant */
GROUP BY c.computerid
/* Make sure the most recently installed item of 3 is being used for date comparison */
HAVING s.DateInstalled = MAX(s.DateInstalled)


#https://habr.com/ru/articles/171701/
param (
    $User,
    $Count = 1
 ) 
    $result = New-Object system.Data.DataTable "Locks"
    $col1 = New-Object system.Data.DataColumn Username,([string])
    $col2 = New-Object system.Data.DataColumn DCFrom,([string])
    $col3 = New-Object system.Data.DataColumn LockTime,([string])
    $col4 = New-Object system.Data.DataColumn eventID,([string])
    $col5 = New-Object system.Data.DataColumn SourceHost,([string])
    $col6 = New-Object system.Data.DataColumn LogonType,([string])
    $col7 = New-Object system.Data.DataColumn LogonProcessName,([string])
    $col8 = New-Object system.Data.DataColumn FalureTime,([string])
    $result.columns.add($col1)
    $result.columns.add($col2)
    $result.columns.add($col3)
    $result.columns.add($col4)
    $result.columns.add($col5)
    $result.columns.add($col6)
    $result.columns.add($col7)
    $result.columns.add($col8)
    
    $PDC = [string](Get-ADDomainController -Discover -Service PrimaryDC).Hostname
    $FilterHash = @{}
    $FilterHash.LogName = "Security"
    $FilterHash.ID = "4740"
    if ($User) {
        $FilterHash.data =$User
        $Count = 1
    }
    $FilterHash2 = @{}
    $FilterHash2.LogName = "Security"
    $FilterHash2.ID = @("4625", "4771")
    Get-WinEvent -Computername $PDC -FilterHashtable $FilterHash -MaxEvents $Count |  foreach {
        $Row = $result.NewRow()
        $Username = ([xml]$_.ToXml()).Event.EventData.Data | ? {$_.Name -eq “TargetUserName”} | %{$_."#text"}
        $DCFrom = ([xml]$_.ToXml()).Event.EventData.Data | ? {$_.Name -eq “TargetDomainName”} | %{$_."#text"}
        $LockTime = $_.TimeCreated
        $FilterHash2.data = $username
        Get-WinEvent -Computername $dcfrom -FilterHashtable $FilterHash2 -MaxEvents 3 | foreach {
            $Row = $result.NewRow()
            $Row.Username = $Username
            $Row.DCFrom = $DCFrom
            $Row.LockTime = $LockTime
            $Row.eventID = $_.ID
            $Row.SourceHost = ([xml]$_.ToXml()).Event.EventData.Data | ? {$_.Name -eq “IpAddress”} | %{$_."#text"}
            $Row.LogonType = ([xml]$_.ToXml()).Event.EventData.Data | ? {$_.Name -eq “LogonType”} | %{$_."#text"} 
            switch ($Row.LogonType)
            { 
             "2" {$Row.LogonType = "Interactive"}
             "3" {$Row.LogonType = "Network"}
             "4" {$Row.LogonType = "Batch"}
             "5" {$Row.LogonType = "Service"}
             "7" {$Row.LogonType = "Unlock"}
             "8" {$Row.LogonType = "NetworkCleartext"}
             "9" {$Row.LogonType = "NewCredentials"}
             "10" {$Row.LogonType = "RemoteInteractive"}
             "11" {$Row.LogonType = "CachedInteractive"}
            }
            $Row.LogonProcessName = ([xml]$_.ToXml()).Event.EventData.Data | ? {$_.Name -eq “LogonProcessName”} | %{$_."#text"}
            $Row.FalureTime = $_.TimeCreated            
            $result.Rows.Add($Row)            
        }
    }
  $result | Format-Table -AutoSize

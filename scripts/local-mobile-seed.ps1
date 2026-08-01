$ErrorActionPreference = 'Stop'

$conn = New-Object System.Data.Odbc.OdbcConnection('Driver={PostgreSQL ODBC Driver(UNICODE)};Server=localhost;Port=5432;Database=FloristERP;Uid=postgres;Pwd=postgres123;')
$conn.Open()

function Get-Scalar([string]$sql) {
    $c = $conn.CreateCommand()
    $c.CommandText = $sql
    $v = $c.ExecuteScalar()
    if ($null -eq $v -or $v -is [System.DBNull]) { return $null }
    return [string]$v
}

function Exec([string]$sql) {
    $c = $conn.CreateCommand()
    $c.CommandText = $sql
    [void]$c.ExecuteNonQuery()
}

$companyId = Get-Scalar 'SELECT "Id"::text FROM "Companies" ORDER BY "CreatedAtUtc" ASC LIMIT 1;'
if (-not $companyId) { throw 'No company found' }

$staffId = Get-Scalar 'SELECT "Id"::text FROM "AspNetUsers" WHERE "Email"=''staff@demoflorist.com'' LIMIT 1;'
if ($staffId) {
    Exec "UPDATE ""AspNetUsers"" SET ""CompanyId""=NULL WHERE ""Id""='$staffId'::uuid;"

    $platformRoleId = Get-Scalar 'SELECT "Id"::text FROM "AspNetRoles" WHERE "Name"=''PlatformSupport'' LIMIT 1;'
    if ($platformRoleId) {
        $exists = Get-Scalar "SELECT '1' FROM ""AspNetUserRoles"" WHERE ""UserId""='$staffId'::uuid AND ""RoleId""='$platformRoleId'::uuid LIMIT 1;"
        if (-not $exists) {
            Exec "INSERT INTO ""AspNetUserRoles""(""UserId"",""RoleId"") VALUES ('$staffId'::uuid, '$platformRoleId'::uuid);"
        }
    }
}

$planId = Get-Scalar 'SELECT "Id"::text FROM "SubscriptionPlans" WHERE "Code"=''MOBILE_TRIAL'' LIMIT 1;'
if (-not $planId) {
    $planId = [guid]::NewGuid().ToString()
    Exec "INSERT INTO ""SubscriptionPlans""(""Id"",""Code"",""Name"",""PlanType"",""MonthlyPrice"",""AnnualPrice"",""LifetimePrice"",""TrialDays"",""OfflineDays"",""GraceDays"",""MaximumDevices"",""MaximumStaff"",""IncludedModulesJson"",""IsActive"",""IsDeleted"",""CreatedAtUtc"",""RowVersion"") VALUES ('$planId'::uuid,'MOBILE_TRIAL','Mobile Trial','Basic',0,0,0,30,3,5,2,2,'[]',true,false,CURRENT_TIMESTAMP,E'\\x');"
}

$customerId = Get-Scalar "SELECT ""Id""::text FROM ""MobileCustomers"" WHERE ""CompanyId""='$companyId'::uuid AND ""Mobile""='+919999000111' LIMIT 1;"
if (-not $customerId) {
    $customerId = [guid]::NewGuid().ToString()
    Exec "INSERT INTO ""MobileCustomers""(""Id"",""CompanyId"",""BusinessName"",""OwnerName"",""Mobile"",""Email"",""City"",""State"",""Country"") VALUES ('$customerId'::uuid,'$companyId'::uuid,'Bloom Test Store','Riya Mehta','+919999000111','riya@bloomtest.com','Mumbai','Maharashtra','India');"
}

$mobileUserId = Get-Scalar "SELECT ""Id""::text FROM ""MobileUsers"" WHERE ""CompanyId""='$companyId'::uuid AND ""Mobile""='+919999000111' LIMIT 1;"
if (-not $mobileUserId) {
    $mobileUserId = [guid]::NewGuid().ToString()
    Exec "INSERT INTO ""MobileUsers""(""Id"",""CompanyId"",""MobileCustomerId"",""FullName"",""Mobile"",""Email"",""Status"",""PreferredLanguage"",""PreferredTheme"") VALUES ('$mobileUserId'::uuid,'$companyId'::uuid,'$customerId'::uuid,'Riya Mehta','+919999000111','riya@bloomtest.com','Active','en-IN','system');"
}

$subscriptionId = Get-Scalar "SELECT ""Id""::text FROM ""MobileSubscriptions"" WHERE ""MobileUserId""='$mobileUserId'::uuid LIMIT 1;"
if (-not $subscriptionId) {
    $subscriptionId = [guid]::NewGuid().ToString()
    Exec "INSERT INTO ""MobileSubscriptions""(""Id"",""CompanyId"",""MobileUserId"",""SubscriptionPlanId"",""Status"",""TrialStartUtc"",""TrialEndUtc"",""AutoRenew"") VALUES ('$subscriptionId'::uuid,'$companyId'::uuid,'$mobileUserId'::uuid,'$planId'::uuid,'Trial',CURRENT_TIMESTAMP - INTERVAL '2 days',CURRENT_TIMESTAMP + INTERVAL '28 days',false);"
}

$deviceId = Get-Scalar "SELECT ""Id""::text FROM ""MobileDevices"" WHERE ""CompanyId""='$companyId'::uuid AND ""MobileUserId""='$mobileUserId'::uuid AND ""DeviceId""='demo-device-001' LIMIT 1;"
if (-not $deviceId) {
    $deviceId = [guid]::NewGuid().ToString()
    Exec "INSERT INTO ""MobileDevices""(""Id"",""CompanyId"",""MobileUserId"",""DeviceId"",""Manufacturer"",""Model"",""Platform"",""OsVersion"",""AppVersion"",""Status"",""LastLoginAtUtc"",""LastHeartbeatAtUtc"",""LastSyncAtUtc"") VALUES ('$deviceId'::uuid,'$companyId'::uuid,'$mobileUserId'::uuid,'demo-device-001','Samsung','Galaxy A54','android','14','1.0.0','Active',CURRENT_TIMESTAMP - INTERVAL '1 hour',CURRENT_TIMESTAMP - INTERVAL '5 minutes',CURRENT_TIMESTAMP - INTERVAL '3 minutes');"
}

$licenseId = Get-Scalar "SELECT ""Id""::text FROM ""MobileLicenses"" WHERE ""MobileDeviceId""='$deviceId'::uuid LIMIT 1;"
if (-not $licenseId) {
    $licenseId = [guid]::NewGuid().ToString()
    Exec "INSERT INTO ""MobileLicenses""(""Id"",""CompanyId"",""MobileDeviceId"",""MobileSubscriptionId"",""Status"",""IssuedAtUtc"",""ExpiryUtc"") VALUES ('$licenseId'::uuid,'$companyId'::uuid,'$deviceId'::uuid,'$subscriptionId'::uuid,'Active',CURRENT_TIMESTAMP - INTERVAL '2 days',CURRENT_TIMESTAMP + INTERVAL '28 days');"
}

$conn.Close()
Write-Output "Seed complete. Company=$companyId Customer=$customerId Device=$deviceId License=$licenseId"

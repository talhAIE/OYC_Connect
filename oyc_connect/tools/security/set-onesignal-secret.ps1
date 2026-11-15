param(
    [string]$ProjectRef = 'jbjtrppxzbgwbqzcpcib',
    [string]$AppId = '4428e176-2a7f-4d7f-9c28-4ebec13b5001'
)
$ErrorActionPreference = 'Stop'
if (-not $IsWindows) { throw 'This helper uses Windows ACLs; use your server secret manager on other systems.' }
if ($ProjectRef -notmatch '^[a-z0-9]{20}$' -or $AppId -notmatch '^[0-9a-f-]{36}$') { throw 'Invalid project/app ID.' }
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$serverEnv = Join-Path $projectRoot 'supabase\.env.local'
$privateRoot = Join-Path $projectRoot 'supabase\.secrets'
$identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

function Set-PrivateAcl([string]$Path, [bool]$Directory = $false) {
    if ($Directory) {
        $acl = [System.Security.AccessControl.DirectorySecurity]::new()
        $rule = [System.Security.AccessControl.FileSystemAccessRule]::new($identity, 'FullControl', 'ContainerInherit,ObjectInherit', 'None', 'Allow')
    } else {
        $acl = [System.Security.AccessControl.FileSecurity]::new()
        $rule = [System.Security.AccessControl.FileSystemAccessRule]::new($identity, 'FullControl', 'Allow')
    }
    $acl.SetAccessRuleProtection($true, $false)
    $acl.AddAccessRule($rule)
    Set-Acl -LiteralPath $Path -AclObject $acl
}

$secureKey = Read-Host 'Replacement OneSignal APP REST key (hidden; never paste it in chat)' -AsSecureString
$keyPointer = [IntPtr]::Zero
$temporarySql = $null
try {
    $keyPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
    $replacementKey = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($keyPointer)
    if ($replacementKey -notmatch '^os_v2_app_[A-Za-z0-9_-]{20,}$') { throw 'Expected a OneSignal app REST key.' }
    # These are deliberately the only two fields in this server-only file.
    if (-not (Test-Path -LiteralPath $serverEnv)) { [IO.File]::WriteAllText($serverEnv, '') }
    Set-PrivateAcl $serverEnv
    [IO.File]::WriteAllText($serverEnv, "ONESIGNAL_APP_ID=$AppId`nONESIGNAL_API_KEY=$replacementKey`n")

    if (-not (Test-Path -LiteralPath $privateRoot)) { New-Item -ItemType Directory -Path $privateRoot | Out-Null }
    Set-PrivateAcl $privateRoot $true
    $temporarySql = Join-Path $privateRoot ([Guid]::NewGuid().ToString() + '.sql')
    [IO.File]::WriteAllText($temporarySql, '')
    Set-PrivateAcl $temporarySql
    # Input validation excludes quotes. Values never appear in argv or output.
    $sql = @"
begin;
do `$`$
declare secret_id uuid;
begin
  select id into secret_id from vault.secrets where name='oyc_onesignal_api_key';
  if secret_id is null then perform vault.create_secret('$replacementKey','oyc_onesignal_api_key');
  else perform vault.update_secret(secret_id,'$replacementKey'); end if;
  select id into secret_id from vault.secrets where name='oyc_onesignal_app_id';
  if secret_id is null then perform vault.create_secret('$AppId','oyc_onesignal_app_id');
  else perform vault.update_secret(secret_id,'$AppId'); end if;
end;
`$`$;
commit;
"@
    [IO.File]::WriteAllText($temporarySql, $sql)
    # Never echo CLI errors: an upstream SQL diagnostic could include SQL text.
    $vaultResult = & supabase db query --linked --project-ref $ProjectRef --file $temporarySql 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'Vault update failed. The protected local key is saved; retry without posting diagnostic output containing secrets.' }
    $edgeResult = & supabase secrets set --project-ref $ProjectRef --env-file $serverEnv 2>&1
    if ($LASTEXITCODE -ne 0) { throw 'Vault updated, but Edge secret synchronization failed. Retry the server secret import.' }
    Write-Host 'Replacement stored in the protected server-only environment file, Supabase Vault, and Edge secrets. No notification sent.'
    Write-Host 'Confirm the old key has been revoked in OneSignal. This helper does not revoke provider keys.'
} finally {
    if ($temporarySql -and (Test-Path -LiteralPath $temporarySql)) { Remove-Item -LiteralPath $temporarySql }
    if ($keyPointer -ne [IntPtr]::Zero) { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($keyPointer) }
    $replacementKey = $null; $sql = $null; $vaultResult = $null; $edgeResult = $null
    $secureKey.Dispose()
}

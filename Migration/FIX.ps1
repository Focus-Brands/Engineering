# Define the root key and the value to search for
Start-Transcript -path C:\migration\output.txt -append
$rootPath = "HKLM:\SOFTWARE\Microsoft\Enrollments"
$searchValueName = "AADTenantID"
$searchValueData = "c50d7be4-0394-4c66-b92e-b9c887be2082"

# Function to search for the key
function Search-RegistryKey {
    param (
        [string]$path
    )
    
    try {
        $subKeys = Get-ChildItem -Path $path -ErrorAction Stop
        foreach ($subKey in $subKeys) {
            $keyPath = $subKey.PSPath
            $key = Get-ItemProperty -Path $keyPath -ErrorAction Stop
            if ($key.$searchValueName -eq $searchValueData) {
                Write-Host "Found key: $keyPath"
                return $keyPath
            }
            # Recursively search subkeys
            $foundKey = Search-RegistryKey -path $keyPath
            if ($foundKey) {
                return $foundKey
            }
        }
    } catch {
        # Handle error if any
        Write-Error $_.Exception.Message
    }
}

# Function to delete the key
function Delete-RegistryKey {
    param (
        [string]$path
    )
    try {
        Remove-Item -Path $path -Recurse -ErrorAction Stop
        Write-Host "Registry key deleted successfully: $path"
    } catch {
        Write-Error "Failed to delete key: $path"
        Write-Error $_.Exception.Message
    }
}

# Start searching from the root path
$foundKey = Search-RegistryKey -path $rootPath

if ($foundKey) {
    $startParams = @{
    FilePath     = 'C:\Migration\Scripts\ccmclean\ccmclean.exe'
    ArgumentList = '/q'
    Wait         = $true
    PassThru     = $true
}
    $proc = Start-Process @startParams
    $proc.ExitCode
    Write-Host "Key found: $foundKey"
    Delete-RegistryKey -path $foundKey
    Delete-RegistryKey -path "HKLM:\SOFTWARE\Microsoft\DeviceManageabilityCSP"

} else {
    Write-Host "No matching key found."
}
Stop-Transcript

<#
    checks to see if a given path exists, if it doesn't then an error is thrown
#>
function Test-PicassioPath
{
    param (
        [string]
        $Path,

        [switch]
        $ThrowIfNotExists
    )

    $exists = (!(Test-PicassioEmpty $Path) -and (Test-Path $Path))

    if (!$exists -and $ThrowIfNotExists)
    {
        throw "The following path does not exist: $($Path)"
    }

    return $exists
}


<#
    checks to see if the passed value is empty.
    this value can be a string, array, hashtable or object
#>
function Test-PicassioEmpty
{
    param (
        $Value
    )

    # if it's already null, just return true
    if ($Value -eq $null)
    {
        return $true
    }

    # if it's a string, check if it's null/whitespace
    if ($Value.GetType().Name -ieq 'string')
    {
        return [string]::IsNullOrWhiteSpace($Value)
    }

    # quick switch logic for objects and arrays
    $type = $Value.GetType().BaseType.Name.ToLowerInvariant()
    switch ($type)
    {
        'valuetype'
            {
                return $false
            }

        'array'
            {
                return (($Value | Measure-Object).Count -eq 0 -or $Value.Count -eq 0)
            }
    }

    # final catch all for hashtables another other misc items
    return ([string]::IsNullOrWhiteSpace($Value) -or ($Value | Measure-Object).Count -eq 0 -or $Value.Count -eq 0)
}


<#
    checks to see whether a given ComputerName is the local machine
#>
function Test-PicassioLocalComputer
{
    param (
        [string]
        $ComputerName
    )

    # if null/whitespace or same as $env:COMPUTERNAME then return true
    if ((Test-PicassioEmpty $ComputerName) -or ($env:COMPUTERNAME -ieq $ComputerName))
    {
        return $true
    }

    # check array of possible local machine names
    $locals = @('localhost', 'local', '(local)', '(localhost)', 'home', 'this', '127.0.0.1', '::1')
    return ($locals -icontains $ComputerName)
}


<#
    tests whether the current shell is open in a 32-bit host
#>
function Test-PicassioWin32
{
    param (
        [switch]
        $ThrowError
    )

    $valid = [IntPtr]::Size -eq 4;

    if ($ThrowError -and !$valid)
    {
        throw 'Console needs to be running as a 32-bit host'
    }

    return $valid
}


<#
    tests whether the current shell is open in a 64-bit host
#>
function Test-PicassioWin64
{
    param (
        [switch]
        $ThrowError
    )

    $valid = [IntPtr]::Size -eq 8;

    if ($ThrowError -and !$valid)
    {
        throw 'Console needs to be running as a 64-bit host'
    }

    return $valid
}


<#
    checks to see if the file at passed path is a valid XML file
#>
function Test-PicassioXmlContent
{
    param (
        [string]
        $Path
    )

    # fail if the path doesn't exist
    if ((Test-Empty $Path) -or !(Test-PicassioPath $Path))
    {
        return $false
    }

    # ensure the content parses as xml
    try
    {
        [xml](Get-Content $Path) | Out-Null
        return $true
    }
    catch [exception]
    {
        return $false
    }
}


<#
    checks to see if the user has administrator priviledges
#>
function Test-PicassioAdminUser
{
    try
    {
        $principal = New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())

        if ($principal -eq $null)
        {
            return $false
        }

        return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch [exception]
    {
        Write-PicassioError 'Error checking user administrator priviledges'
        Write-PicassioException $_.Exception
        return $false
    }
}


<#
    checks to see if some application is installed
#>
function Test-PicassioSoftware
{
    param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Check,

        [string]
        $Name,

        [switch]
        $ThrowIfNotExists
    )

    try
    {
        Invoke-Expression -Command $Check | Out-Null
        return $true
    }
    catch
    {
        if ($ThrowIfNotExists)
        {
            throw "$($Name) is not installed on machine: $($env:COMPUTERNAME)"
        }

        return $false
    }
}


<#
#>
function Test-PicassioPathDirectory
{
    param (
        [string]
        $Path
    )

    if (!(Test-PicassioPath $Path))
    {
        return $false
    }

    return ((Get-Item $Path) -is [System.IO.DirectoryInfo])
}
<#Header#>
Set-StrictMode -Version "Latest"
$sut = $PSCommandPath.ToLower().Replace(".tests", "")
. $sut
. Join-Path (Split-Path $sut) "PSScript.ps1"
[string]$here=$PSScriptRoot;
<#EndHeader#>

if($PSVersionTable.PSVersion -gt "5.0") {
    class SampleDisposeObject {
        [bool]$IsDisposed = $false
        [void] Dispose() {
            $this.IsDisposed = $true
        }
    }
    Function Script:Get-SampleDisposeObject {
        return New-Object SampleDisposeObject
    }
}
else {
    Function Script:Get-SampleDisposeObject {
        $object = New-Object object
        $object | Add-Member -MemberType NoteProperty -Name IsDisposed -Value $false
        $object | Add-Member -MemberType ScriptMethod -Name Dispose -Value { 
            $this.IsDisposed = $true
        }
        return $object
    }
}

Describe "Regsiter-AutoDispose" {
    It "Verify that dispose is called" {
        $sampleDisposeObject = Get-SampleDisposeObject
        Register-AutoDispose ($sampleDisposeObject) {}
       $sampleDisposeObject.IsDisposed | Should Be $true
    }
}


Describe "Get-TempDirectory/Get-TempFile" {
    (Get-TempDirectory),(Get-TempFile) | %{
    It "Verify that the item has a Dispose member" {
        $tempItem = $null
        try {
            Write-Verbose ($_.Dispose)
            $tempItem = $_
            $tempItem.PSobject.Members.Name -match "Dispose" | Should Be $true
        }
        finally {
            Remove-Item $tempItem;
            Test-Path $tempItem | Should Be $false
        }
    }
    It "Verify that Dispose removes the folder" {
        $tempItem = $null
        try {
            $tempItem = Get-TempDirectory
            $tempItem.Dispose()
            Test-Path $tempItem | Should Be $false
        }
        finally {
            if(Test-Path $tempItem) {
                Remove-Item $tempItem;
                Test-Path $tempItem | Should Be $false
            }
        }
    }
    Function Debug-Temp {
                    return Get-TempDirectory
    }
    It "Verify dispose member is called by Register-AutoDispose" {
        $tempItem = $null
        try {
            $tempItem = Get-TempDirectory
            Register-AutoDispose $tempItem {}
            Test-Path $tempItem | Should Be $false
        }
        finally {
            if(Test-Path $tempItem) {
                Remove-Item $tempItem;
                Test-Path $tempItem | Should Be $false
            }
        }
    }
}
}

Describe "Get-TempFile" {
    It "Provide the full path (no name parameter)" {
        Register-AutoDispose ($tempFile = Get-TempFile) {} #Get the file but let is dispose automatically
        Test-Path $tempFile.FullName | Should Be $false
        Register-AutoDispose (Get-TempFile $tempFile.FullName) {
            Test-Path $tempFile.FullName | Should Be $true
        }
    }
    It "Provide the name but no path" {
        Register-AutoDispose ($tempFile = Get-TempFile) {} #Get the file but let is dispose automatically
        Test-Path $tempFile.FullName | Should Be $false
        Register-AutoDispose (Get-TempFile -name $tempFile.Name) {
            Test-Path $tempFile.FullName | Should Be $true
        }
    }
    It "Provide the path and the name" {
        Register-AutoDispose ($tempFile = Get-TempFile) {} #Get the file but let is dispose automatically
        Test-Path $tempFile.FullName | Should Be $false
        Register-AutoDispose (Get-TempFile $tempFile.Directory.FullName $tempFile.Name) {
            Test-Path $tempFile.FullName | Should Be $true
        }
    }
}
Function Get-TargetResource {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$AssemblyDLL, 

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]$Ensure
    )

    $CurrentAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies()

    $thisassembly = $CurrentAssemblies | where {$_.location -eq $AssemblyDLL}

    $presence = if ($thisassembly.GlobalAssemblyCache) {"Present"} else {"Absent"}

    return @{
        AssemblyDLL = $AssemblyDLL
        Ensure = $presence
    }
}

Function Test-TargetResource {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$AssemblyDLL, 

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]$Ensure
    )

    $CurrentAssemblies = [System.AppDomain]::CurrentDomain.GetAssemblies()

    $thisassembly = $CurrentAssemblies | where {$_.location -eq $AssemblyDLL}
    
    
switch ($ensure) {
    "Present" {
        return $ThisAssembly.GlobalAssemblyCache
        }
    "Absent" {
        if ($thisassembly.GlobalAssemblyCache) {
            return $false
        } else {
            return $true
        }
    }
}
}

Function Set-TargetResource {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$AssemblyDLL, 

        [Parameter()]
        [ValidateSet("Present", "Absent")]
        [String]$Ensure
    )

   if (!(Test-Path $assemblyDLL -type Leaf) ) {
        throw "The assembly '$assemblyDLL' does not exist."
   }

   if (!(Test-IsStronglySigned $AssemblyDLL)) {
        throw "$AssemblyDLL is not strongly signed"
   }

   if (([AppDomain]::CurrentDomain.GetAssemblies() |? { $_.FullName -eq "System.EnterpriseServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a" }) -eq $null ) {
        [System.Reflection.Assembly]::Load("System.EnterpriseServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a") | Out-Null
   }
   $publish = New-Object System.EnterpriseServices.Internal.Publish

   switch ($Ensure) {
        "Present" {     
            $publish.GacInstall($assemblyDLL)
        }
        "Absent" {
            $publish.GacRemove($assemblyDLL)     
        }
   }
}




Function Test-IsStronglySigned {
    param (
        $assembly
    )
     if ( [System.Reflection.Assembly]::LoadFile($assembly).GetName().GetPublicKey().Length -eq 0 ) {
        return $false
     } else {
        return $true
     }
}

Export-ModuleMember *-TargetResource
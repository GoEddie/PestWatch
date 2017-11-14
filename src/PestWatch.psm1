Import-Module -Name Pester

class ChangeSerializer {
    static [boolean]$listening = $false;
    static [boolean]$signalled = $false;
    
    static [int]$WatchInterval;
    static $PesterArguments;

    static WaitForSignal() {
        
        Write-Host "Waiting for changes..."
        while ($true) {            
        
            if (![ChangeSerializer]::signalled) {
                
                Start-Sleep -Seconds "$([ChangeSerializer]::WatchInterval)"
            }

            if ([ChangeSerializer]::signalled) {                
                [ChangeSerializer]::signalled = $false
                Write-Host "Invoke-Pester at $(Get-Date)"
                $pesterArgs = [ChangeSerializer]::PesterArguments

                Invoke-Pester @pesterArgs
            }
        }
    }
}

<#
.SYNOPSIS
Monitor a directory for changes, if a change occurs invoke pester

.DESCRIPTION
Monitor a directory for changes and then invoke pester.

.PARAMETER folder
The folder you want to monitor for changes

.PARAMETER * See Invoke-Pester -? for all arguments

.EXAMPLE
Invoke-PesterWatcher -folder .\

.NOTES
This runs forever, to exit do ctrl+c

#>
Function Invoke-PesterWatcher {
    [CmdLetBinding()]
    Param(
        [string]$watchFolder,
        $watchIntervalSeconds = 2,
        $Script,
        $TestName,
        $EnableExit,
        $OutputXml,
        $Tag,
        $ExcludeTag,
        $PassThru,
        $CodeCoverage,
        $Strict,
        $Quiet,
        $PesterOption,
        $OutputFile,
        $OutputFormat
    )
    #Original from https://gallery.technet.microsoft.com/scriptcenter/Powershell-FileSystemWatche-dfd7084b
    #By BigTeddy 05 September 2011 
        
    [ChangeSerializer]::PesterArguments = $PSBoundParameters
    [ChangeSerializer]::PesterArguments.Remove("watchFolder") | Out-Null
    [ChangeSerializer]::PesterArguments.Remove("watchIntervalSeconds") | Out-Null

    [ChangeSerializer]::WatchInterval = $watchIntervalSeconds
    
    $filter = '*.ps*1'  # You can enter a wildcard filter here. 
    
   
        # In the following line, you can change 'IncludeSubdirectories to $true if required.                           
        $fsw = New-Object IO.FileSystemWatcher $watchFolder, $filter -Property @{IncludeSubdirectories = $false; NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'} 
        
        Register-ObjectEvent $fsw Created -SourceIdentifier FileCreated -Action { 
        
            [ChangeSerializer]::signalled = $true
        
        } | Out-Null
            

        Register-ObjectEvent $fsw Changed -SourceIdentifier FileChanged -Action { 
        
            [ChangeSerializer]::signalled = $true
        
        }  | Out-Null


        if (![ChangeSerializer]::listening) {
            [ChangeSerializer]::listening = $true
            [ChangeSerializer]::WaitForSignal()
        }

    
}



Export-ModuleMember -Function Invoke-PesterWatcher
# To stop the monitoring, run the following commands: 
# Unregister-Event FileDeleted 
# Unregister-Event FileCreated 
# Unregister-Event FileChanged
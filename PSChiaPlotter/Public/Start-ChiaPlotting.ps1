function Start-ChiaPlotting {
    [CmdletBinding()]
    param(
        [ValidateRange(32,35)]
        [int]$KSize = 32,
    
        [ValidateRange(1,5000)]
        [int]$TotalPlots = 1,
    
        [int]$Buffer,

        [ValidateRange(1,256)]
        [int]$ThreadCount = 2,

        [switch]$DisableBitfield,
        [switch]$ExcludeFinalDirectory,
    
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$TempDirectoryPath,

        [Parameter()]
        [ValidateScript({Test-Path $_})]
        [string]$SecondTempDirecoryPath,

        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_})]
        [string]$FinalDirectoryPath,

        #$FarmerPublicKey,
        #$PoolPublicKey,

        $LogPathDirectory = "$ENV:USERPROFILE\.chia\mainnet\plotter"
    )

    if (-not$PSBoundParameters.ContainsKey("Buffer")){
        switch ($KSize){
            32 {$Buffer = 3390}
            33 {$Buffer = 7400}
            34 {$Buffer = 14800}
            35 {$Buffer = 29600}
        }
        Write-Information "Buffer set to: $Buffer"
    }

    $CurrentPlots = Get-Variable -Scope Global -Name CurrentChiaPlots -ErrorAction SilentlyContinue
    if ($CurrentPlots -eq $null){
        $Global:CurrentChiaPlots = New-Object System.Collections.Generic.List[Object]
    }

    #path to chia.exe
    $ChiaPath = (Get-Item -Path "$ENV:LOCALAPPDATA\chia-blockchain\app-*\resources\app.asar.unpacked\daemon\chia.exe").FullName

    $E = if ($DisableBitfield){"-e"}
    $X = if ($ExcludeFinalDirectory){"-x"}

    #remove any trailing '\' since chia.exe hates them
    $TempDirectoryPath = $TempDirectoryPath.TrimEnd('\')
    $FinalDirectoryPath = $FinalDirectoryPath.TrimEnd('\')
    if ($PSBoundParameters.ContainsKey($SecondTempDirecoryPath)){
        $SecondTempDirecoryPath = $SecondTempDirecoryPath.TrimEnd('\')
    }
    $TempDirectoryPath;$FinalDirectoryPath;$SecondTempDirecoryPath

    if (Test-Path $LogPathDirectory){
        $LogPath = Join-Path $LogPathDirectory ((Get-Date -Format yyyy_MM_dd_hh-mm-ss-tt_) + (New-Guid).Guid + ".log")
        #$ErrorPath = Join-Path $LogPathDirectory ("ErrorLogs_" + (Get-Date -Format yyyy_MM_dd_hh-mm-ss-tt_) + (New-Guid).Guid + ".log")
    }
    else{
        $Message = "The log path provided was not found: $LogPathDirectory"
        $ErrorRecord = [System.Management.Automation.ErrorRecord]::new(
                [System.IO.FileNotFoundException]::new($Message,$SErvicePath),
                'LogPathInvalid',
                [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                "$LogPathDirectory"
            )
            $PSCmdlet.ThrowTerminatingError($ErrorRecord)
        $PSCmdlet.ThrowTerminatingError("Invalid Log Path Directory: $LogPathDirectory")
    }

    Write-Host "Starting plot"
    if ($ChiaPath){
        #&$ChiaPath plots create -k $KSize -n $TotalPlots -b $Buffer -r $ThreadCount -t $TempDirectoryPath -d $FinalDirectoryPath $E $X
        $PlottingParam = @{
            FilePath = $ChiaPath
            ArgumentList = "plots create -k $KSize -n $TotalPlots -b $Buffer -r $ThreadCount -t `"$TempDirectoryPath`" -d `"$FinalDirectoryPath`" $E $X"
            RedirectStandardOutput = $LogPath
        }
        $PlottingProcess = Start-Process @PlottingParam -NoNewWindow -PassThru
        $CurrentChiaPlots.Add([PSCustomObject]@{
            KSize = $KSize
            Buffer = $Buffer
            Threads = $ThreadCount
            PID = $PlottingProcess.Id
            StartTime = $PlottingProcess.StartTime
            TempDir = $TempDirectoryPath
            FinalDir = $FinalDirectoryPath
            TempDir2 = $SecondTempDirecoryPath
            LogPath = $LogPathDirectory
            TotalPlotCount = $TotalPlots
            BitfieldEnabled = !$DisableBitfield.IsPresent
            ExcludeFinalDir = $ExcludeFinalDirectory.IsPresent
        })
        #$PlottingProcess = Start-Process -FilePath $ChiaPath -ArgumentList "plots create -k $KSize -n $TotalPlots -b $Buffer -r $ThreadCount -t `"$TempDirectoryPath`" -d `"$FinalDirectoryPath`" $E $X" -RedirectStandardOutput $LogPath -PassThru -RedirectStandardError $LogPath -NoNewWindow

        #$CurrentChiaPlots.Add([pscredential]@{

        #})
    } #if
}
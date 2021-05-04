function Get-CurrentChiaProcess{
    [CmdletBinding()]
    param()

    $ChiaPID = 10832
    $LogFile = 

    DO {
        $Performance = Get-CimInstance -Query "Select workingSetPrivate,PercentProcessorTime,IDProcess FROM Win32_PerfFormattedData_PerfProc_Process WHERE NAME='_Total' OR IDProcess=$ChiaPID" |
            sort IDProcess
        if ($Performance[1].PercentProcessorTime -ne 0){
            $CPUPer = ($Performance[1].PercentProcessorTime / $Performance[0].PercentProcessorTime) * 100
        }
        else{$CPUPer = 0}
        $CPUPer
        sleep 10
        $Processes = $null
        $Processes = Get-Process -Id $ChiaPID -ErrorAction SilentlyContinue
    }
    while ($Processes)
}
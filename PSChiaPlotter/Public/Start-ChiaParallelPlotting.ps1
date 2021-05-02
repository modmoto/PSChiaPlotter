function Start-ChiaParallelPlotting {
    [CmdletBinding()]
    param(
        [int]$MaxParallelCount,
        [int]$PlotCount,
        $KSize = "K32",
        [int]$DelayInMinutes
    )
    $Global:DataHash = [hashtable]::Synchronized(@{})
    $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $DataSync = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new("DataHash", $DataHash, $Null)
    $InitialSessionState.Variables.Add($DataSync)
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1,$MaxParallelCount,$InitialSessionState,$Host)
    $RunspacePool.ApartmentState = "STA"
    $RunspacePool.ThreadOptions = "ReuseThread"
    $RunspacePool.open()
    $DataHash.PlotCount = $PlotCount
    $DataHash.PlotsCompleted = 0
    $DataHash.CurrentPID = New-Object System.Collections.Generic.List[object]

    for ($i = 1; $i -le $MaxParallelCount; $i++){
        $PlottingRunspace = [powershell]::Create().AddScript{
            while (($DataHash.PlotsCompleted + $DataHash.CurrentPID.Count) -lt ($DataHash.PlotCount)){
                $np = Start-Process notepad -PassThru
                #$DataHash.CurrentPID.add("1")
                $DataHash.CurrentPID.add($np.Id)
                $np.WaitForExit()
                $DataHash.CurrentPID.remove($np.Id)
                $DataHash.PlotsCompleted++
            } #while
        } #runspace
        Write-Host "Adding $i runspace to pool"
        $PlottingRunspace.RunSpacePool = $RunspacePool
        $PlottingRunspace.BeginInvoke()
        Write-Host "Invoke $i runspace"
        sleep $DelayInMinutes
    } #for
}
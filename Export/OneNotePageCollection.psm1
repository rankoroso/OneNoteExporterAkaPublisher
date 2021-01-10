<#
    Child Module (parents needs to reference the dependent modules)
#>
function Export-OneNotePageCollection {
    <#
        Exports all pages in a page collection
    #>
    param(
        [Object]$Config,
        [System.Array]$PageCollection,
        [String]$Path,
        [Int]$Level
    )
    try {
        [array]$pages = Get-OneNoteEnrichPageCollection -PageCollection $PageCollection
        foreach ($page in $pages) {
            $paths = Get-OneNotePagePublishPaths -Config $Config -Path $Path -Page $page
            Write-Host "Exporting Page: " $page.Path $page.Name $page $paths $page.Id -BackgroundColor Green
            Invoke-OneNotePublish -ID ($page.Id) -Path $paths.docx -PublishFormat 'pfWord' -Overwrite $true
        }
    }
    catch {
        Write-Host $global:error -ForegroundColor Red
        Exit
    }
}

function Get-OneNotePagePublishPath {
    <#
        Helper for publish: returns an object with a certain path set
    #>
    param(
        [string]$ExportFormat,
        [object]$Paths
    )
    try {
        $ExportFormat = $ExportFormat.Trim()
        $Extension = $ExportFormat
        $Dir = $ExportFormat
        if ($ExportFormat -eq "markdown")
        {
            $Extension = "md"
            $Dir = "markdown"
        }
        $path = (Join-Path -Path $Paths.ExportRootPath -ChildPath $Dir | Join-Path -ChildPath $Paths.RelativeRoot | Join-Path -ChildPath $Paths.FullName) + "." + $Extension
        $Paths | Add-Member -Type NoteProperty -Name $ExportFormat -Value $path -Force
        New-Dir -Path ([IO.Path]::GetDirectoryName($path)) | Out-Null
        return $Paths
    }
    catch {
        Write-Host $global:error -ForegroundColor Red
        Exit
    }
}

function Get-OneNotePagePublishPaths {
    <#
        Helper Object to return paths for all export types, given a page as input to publish
        https://docs.microsoft.com/en-us/office/client-developer/onenote/enumerations-onenote-developer-reference#odc_PublishFormat
    #>
    param(
        [Object]$Config,
        [String]$Path,
        [Object]$Page
    )
    try {
        $paths = New-Object -TypeName PSObject
        $paths | Add-Member -Type NoteProperty -Name 'ExportRootPath' -Value ($Config.ExportRootPath) -Force
        $paths | Add-Member -Type NoteProperty -Name 'RelativeRoot' -Value $Path -Force
        $paths | Add-Member -Type NoteProperty -Name 'FullName' -Value $Page.FullName -Force
        $paths | Add-Member -Type NoteProperty -Name 'PageName' -Value $Page.Name  -Force
        # for all files types create helper"
        $exportFormats = $Config.ExportFormat -split ","
        # for each of the export objects specified:
        foreach($exportFormat in $exportFormats) {
            $paths = Get-OneNotePagePublishPath -ExportRootPath $Config.ExportRootPath -ExportFormat $exportFormat -Paths $paths -PageId ($Page.Id)
        }
        return $paths
    }
    catch {
        Write-Host $global:error -ForegroundColor Red
        Exit
    }
}
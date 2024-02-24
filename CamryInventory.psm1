$rawData = (Get-Content 'data.json' | ConvertFrom-Json)

$dealer = @{
    Name       = 'dealer'
    Expression = { $_.dealerMarketingName }
}

$model = @{
    Name       = 'model'
    Expression = { $_.model.marketingName }
}

$tsrp = @{
    Name       = 'tsrp'
    Expression = { $_.price.totalMsrp }
}

$markup = @{
    Name       = 'markup'
    Expression = {
        if ($_.price.advertizedPrice -gt $_.price.totalMsrp) {
            return $_.price.advertizedPrice - $_.price.totalMsrp
        }
        elseif ($_.price.sellingPrice -gt $_.price.totalMsrp) {
            return $_.price.sellingPrice - $_.price.totalMsrp
        }
        return $null
    }
}

$seating = @{
    Name       = 'seating'
    Expression = { $_.intColor.marketingName }
}

$color = @{
    Name       = 'color'
    Expression = { $_.extColor.marketingName }
}

$etaFrom = @{
    Name       = 'etaFrom'
    Expression = { $_.eta.currFromDate }
}

$etaTo = @{
    Name       = 'etaTo'
    Expression = { $_.eta.currToDate }
}

$age = @{
    Name       = 'age'
    Expression = {
        $eta = $_.eta.currToDate
        if ($eta) {
            return ((Get-Date).Date - (Get-Date $eta).Date).Days
        }
    }
}

$options = @{
    Name       = 'options'
    Expression = {
        $_.options | Sort-Object optionType | Select-Object optionType, optionCd, marketingName, marketingLongName
    }
}

$data = $rawData | Select-Object -Property vin, distance, $dealer, $tsrp, $markup, $model, $color, $seating, isPreSold, holdStatus, $age, $etaFrom, $etaTo, $options
$uniqueOptions = $data | ForEach-Object options | Select-Object -Unique * | Sort-Object optionType

function Get-DealerInventory {
    [CmdletBinding()]
    Param (
        [int]
        $dist,

        [System.Nullable[int]]
        $maxAge,

        [System.Nullable[int]]
        $minAge,

        [switch]
        $showOptions,

        [switch]
        $arrived,

        [switch]
        $transit,

        [switch]
        $building,

        [ValidateSet('Gray', 'Silver', 'Ice Edge', 'Ice Cap', 'Black', 'Blue', 'Red', 'Pearl')]
        [string[]]
        $color,

        [ValidateSet('LE', 'SE', 'Nightshade', 'XLE', 'XSE')]
        [string[]]
        $model,

        [ValidateSet('BD', 'CP', 'D5', 'EF', 'FE', 'RO', 'SR', 'UP', 'WL', '1T', '2T', 'MAX', 'S5', 'CY', '59', 'PC', 'NL', 'DK', 'MF', 'XPEL-PAINT-PROTECTION', 'WINDOW-TINT', 'DOOR-SILL-PROTECTOR', 'WHL-LOCKS', 'XPEL-PAINT-PROTECTION-DOOR-CUPS-DOOR-EDGE-GUARDS', 'XPEL-CERAMIC-EXPRESS', 'UM', 'CF', 'G4', 'TX', 'KAR', 'UDA', 'UDC', 'YY', '74', 'PURSUITALARM', '3MBASIC', 'TOO-PROTECTION', '9G', 'G0', 'CLEAR-GUARD-DOOR-EDGE-GUARDS', 'ELO-GPS-THEFT-PROTECTION', '3Z', 'GE', '7R', '3P', 'BK', 'VPP', 'IRVINE-PRE-LOAD-DENT', 'IRVINE-PRE-LOAD-APP', 'SCT-PROTECTION', 'GD', 'V1', 'FT-0001', 'AMU3', 'SURF-PT', 'SECURITY-GPS-SYSTEM', 'CLEARPRO-DOOR-PROTECTION', 'ANTI-THEFT-WHEEL-LOCKS', 'ENVIRONMENTAL-PKG', 'XZILON-CERAMIC-COATING', 'THEFT-PROTECTION', 'PROPAK', 'DA', 'HL', '2', 'WT')]
        [string[]]
        $options,

        [string[]]
        $dealer,

        [ValidateSet('age', 'color', 'dealer', 'dist', 'tsrp', 'markup')]
        [string[]]
        $sortBy = @('dist'),

        [ValidateSet('age', 'color', 'dealer')]
        [string]
        $groupBy
    )

    $expr = "`$data"

    if ($arrived) {
        $expr += " |`
        Where-Object age -ge 0"
    }

    if ($transit) {
        $expr += " |`
        Where-Object {`$_.age -and `$_.age -lt 0}"
    }

    if ($building) {
        $expr += " |`
        Where-Object age -eq `$null"
    }

    if ($color) {
        $expr += " |`
        Where-Object color -Match '\b$($color -join '\b|\b')\b'"
    }

    if ($model) {
        $expr += " |`
        Where-Object model -Match '\b$(($model | ForEach-Object {$_ -creplace '(E)$', '$1 Hybrid$'}) -join '\b|\b')\b'"
    }

    if ($dealer) {
        $expr += " |`
        Where-Object dealer -Match '\b$($dealer -join '\b|\b')\b'"
    }

    if ($dist) {
        $expr += " |`
        Where-Object distance -le $dist"
    }

    if ($maxAge -ne $null) {
        $expr += " |`
        Where-Object {`$_.age -le $maxAge}"
    }

    if ($minAge -ne $null) {
        $expr += " |`
        Where-Object {`$_.age -ge $minAge}"
    }

    if ($options) {
        $expr += " |`
        Where-Object {
            `$prefCDs = `$_.options.optionCd
            -not @(`"$($options -join '","')`").Where({
                `$_ -NotIn `$prefCDs
            })
        }"
    }
    
    if ($groupBy) {
        $groupByClause = "-GroupBy $($groupBy -join ',')"
        $sortBy = @($groupBy) + $sortBy
    }

    if ($sortBy) {
        $expr += " |`
        Sort-Object $($sortBy -replace 'dist', 'distance' -join ',')"
    }

    if ($PSCmdlet.MyInvocation.PipelineLength -eq $PSCmdlet.MyInvocation.PipelinePosition) {
        if ($showOptions) {
            $optionPref = @{
                Name       = 'P'
                Expression = { if ($_.optionCd -in $options) { "*" } }
            }
            $sortPref = @{
                Expression = { $_.P }
                Descending = $true
            }
            $expr += " |`
            ForEach-Object {
                `$_ | `
                    Select-Object * -ExcludeProperty options; 
                `$_.options |`
                    Select-Object `$optionPref, * |`
                    Sort-Object `$sortPref, optionType | `
                    Format-Table $groupByClause}"
        }
        else {
            $expr += " |`
            Select-Object * -ExcludeProperty options |`
            Format-Table $groupByClause *"
        }
    }

    Write-Debug $expr
    Invoke-Expression $expr
}

function Get-AvailableOptions {

    return $uniqueOptions | Format-Table -GroupBy optionType
}

Export-ModuleMember -Function Get-DealerInventory, Get-AvailableOptions
$rawData = (Get-Content 'data.json' | ConvertFrom-Json)

$dealer = @{
    Name = 'dealer'
    Expression = {$_.dealerMarketingName}
}

$model = @{
    Name = 'model'
    Expression = {$_.model.marketingName}
}

$tsrp = @{
    Name = 'tsrp'
    Expression = {$_.price.totalMsrp}
}

$markup = @{
    Name = 'markup'
    Expression = {
        if ($_.price.advertizedPrice -gt $_.price.totalMsrp) {
            return $_.price.advertizedPrice - $_.price.totalMsrp
        } elseif ($_.price.sellingPrice -gt $_.price.totalMsrp) {
            return $_.price.sellingPrice - $_.price.totalMsrp
        }
        return $null
    }
}

$seating = @{
    Name = 'seating'
    Expression = {$_.intColor.marketingName}
}

$color = @{
    Name = 'color'
    Expression = {$_.extColor.marketingName}
}

$etaFrom = @{
    Name = 'etaFrom'
    Expression = {$_.eta.currFromDate}
}

$etaTo = @{
    Name = 'etaTo'
    Expression = {$_.eta.currToDate}
}

$options = @{
    Name = 'options'
    Expression = {
        $_.options | Sort-Object optionType | Select-Object optionType, optionCd, marketingName, marketingLongName
    }
}

$data = $rawData | Select-Object -Property vin, distance, $dealer, $tsrp, $markup, $model, $color, $seating, isPreSold, holdStatus, $etaFrom, $etaTo, $options
$uniqueOptions = $data | ForEach-Object options | Select-Object -Unique * | Sort-Object optionType

function Get-DealerInventory {
    [CmdletBinding()]
    Param (
        [int]
        $dist,

        [switch]
        $showOptions,

        [ValidateSet('Gray', 'Silver', 'Ice Edge', 'Ice Cap', 'Black', 'Blue', 'Red', 'Pearl')]
        [string[]]
        $color,

        [ValidateSet('LE', 'SE', 'Nightshade', 'XLE', 'XSE')]
        [string[]]
        $model,

        [ValidateSet("BD","CP","D5","EF","FE","RO","SR","UP","WL","1T","2T","MAX","S5","CY","59","PC","NL","DK","MF","XPEL-PAINT-PROTECTION","WINDOW-TINT","DOOR-SILL-PROTECTOR","WHL-LOCKS","XPEL-PAINT-PROTECTION-DOOR-CUPS-DOOR-EDGE-GUARDS","XPEL-CERAMIC-EXPRESS","UM","CF","G4","TX","KAR","UDA","UDC","YY","74","PURSUITALARM","3MBASIC","TOO-PROTECTION","9G","G0","CLEAR-GUARD-DOOR-EDGE-GUARDS","ELO-GPS-THEFT-PROTECTION","3Z","GE","7R","3P","BK","VPP","IRVINE-PRE-LOAD-DENT","IRVINE-PRE-LOAD-APP","SCT-PROTECTION","GD","V1","FT-0001","AMU3","SURF-PT","SECURITY-GPS-SYSTEM","CLEARPRO-DOOR-PROTECTION","ANTI-THEFT-WHEEL-LOCKS","ENVIRONMENTAL-PKG","XZILON-CERAMIC-COATING","THEFT-PROTECTION","PROPAK","DA","HL","2","WT")]
        [string[]]
        $options,

        [string[]]
        $dealer
    )

    $expr = "`$data"

    if ($color) {
        $expr += " |`
        ? color -Match '\b$($color -join '\b|\b')\b'"
    }

    if ($model) {
        $expr += " |`
        ? model -Match '\b$(($model | ForEach-Object {$_ -creplace '(E)$', '$1 Hybrid$'}) -join '\b|\b')\b'
        "
    }

    if ($dealer) {
        $expr += " |`
        ? dealer -Match \b$($dealer -join '\b|\b')\b"
    }

    if ($dist) {
        $expr += " |`
        ? distance -le $dist"
    }

    if ($options) {
        $expr += " |
        ? {
            `$opts = (`$_.options | % optionCd)
            -not @(`"$($options -join '","')`").Where({
                `$_ -NotIn `$opts
            })
        }"
    }

    if ($PSCmdlet.MyInvocation.PipelineLength -eq $PSCmdlet.MyInvocation.PipelinePosition) {
        if ($showOptions) {
            $optionPref = @{
                Name = 'P'
                Expression = {if ($_.optionCd -in $options) {"*"}}
            }
            $sortPref = @{
                Expression = {$_.P}
                Descending = $true
            }
            $expr += " | % {`$_ | select * -ExcludeProperty options; `$_.options | select `$optionPref, * | sort `$sortPref, optionType | ft }"
        } else {
            $expr += " | select * -ExcludeProperty options | ft *"
        }
    }

    Write-Debug $expr
    Invoke-Expression $expr
}

function Get-AvailableOptions {

    return $uniqueOptions | Format-Table -GroupBy optionType
}

Export-ModuleMember -Function Get-DealerInventory, Get-AvailableOptions, Get-CarDetails
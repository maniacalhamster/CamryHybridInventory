## Requirements

Script to retrieve data requires `node` and `puppeteer`. 

Once node is installed, you can run `npm i` to let npm handle dependency installation.

## Setup

1. Run the script that retrieves data with `node script.mjs`.

2. Import the powershell module with `Import-Module .\CamryInventory.psm1`.

## Example Usage

```ps1
Get-DealerInventory -model SE -dealer Puente, Corona -color Gray, Silver -options BD, SR, UP

vin               distance dealer                         tsrp markup  model           color                     seating                     isPreSold holdStatus etaFrom    etaTo
---               -------- ------                         ---- ------  -----           -----                     -------                     --------- ---------- -------    -----
4T1S31AK9RU069129       15 Larry H. Miller Toyota Corona 34717         Camry SE Hybrid Celestial Silver Metallic Black SofTex® [softex] Trim     False            2023-12-14 2023-12-16
4T1S31AK3RU629145       20 Puente Hills Toyota           35442 3485.00 Camry SE Hybrid Predawn Gray Mica         Black SofTex® [softex] Trim      True DealerHold 2024-02-07 2024-02-24
4T1S31AK3RU10C016       20 Puente Hills Toyota           35072 5380.00 Camry SE Hybrid Predawn Gray Mica         Black SofTex® [softex] Trim     False Available  2024-03-13 2024-03-29
```

```ps1
Get-DealerInventory -model SE -dealer Corona -color Gray, Silver -options BD, SR, UP -showOptions

vin        : 4T1S31AK9RU069129
distance   : 15
dealer     : Larry H. Miller Toyota Corona
tsrp       : 34717
markup     : 
model      : Camry SE Hybrid
color      : Celestial Silver Metallic
seating    : Black SofTex┬«┬á[softex] Trim
isPreSold  : False
holdStatus : 
etaFrom    : 2023-12-14
etaTo      : 2023-12-16


P optionType optionCd marketingName                                   marketingLongName
- ---------- -------- -------------                                   -----------------
* F          BD       Blind Spot Monitor (BSM) [bsm]                  Blind Spot Monitor (BSM) [bsm] with Rear Cross-Traffic Alert (RCTA) [rcta]
* F          SR       Power tilt/slide moonroof                       Power tilt/slide moonroof
* F          UP       Audio Upgrade Package                           Audio Upgrade Package — includes Audio Plus, Qi-compatible smartphone charging [qi_wireless]
  F          CP       Convenience Package, Hybrid                     Convenience Package, Hybrid — includes HomeLink® [homelink] universal transceiver, auto-dimming rearview mirror
  F          FE       50 State Emissions                              50 State Emissions
  P          DK       Owner's Portfolio                               Owner's Portfolio
  P          EF       Rear Bumper Applique (Black)[installed_msrp]    Brings a sporty look and helps keep your rear bumper looking like new.<br>•Helps prevent scuffs and scrapes to your rear bumper<br>•Custom-ta… 
  P          RO       Dual USB Power Port (Rear Only)[installed_msrp] Power ports provide additional capability to your vehicle giving you access and power to charge your multimedia USB devices.<br>Includes:  <b… 
  P          1T
  P          2T       All-Weather Floor Liner Package[installed_msrp] All-Weather Floor Liner Package Includes: <br><ul><li>All-Weather Floor Liners</li><br><li>Cargo Tray</li></ul>
```

# Journey/Story

While perusing Toyota's inventory search site for a 2024 Camry Hybrid, I found the request made to get inventory data in a GraphQL query and was able to copy the data over in 2 parts to a data1.json and a data2.json file.

I later wrote a small powershell script that parses those files for relevant info (inventory data only, avoiding the pagination metadata) and combines them into a single data.json file.

Now, with the inventory data at hand, I was able to make use of Powershell's data manipulation commandlets to more easily filter and query by attributes than Toyota's website allowed (customer facing site felt a bit slow and cumbersome to me). I also took this as an opportunity to gain some practical experience applying the following commandlets:
- `Select-Object` (aliased as `select`): filtering to view specific attributes
- `Where-Object` (aliased as `?`): filtering out entries from data based off conditions imposed on specific attributes
- `ForEach-Object` (aliased as `%`): applying expressions to nested lists within entries, or for aggregating "list" attributes between entries
- `Sort-Object` (aliased as `sort`): for organizing results to prioritize certain characteristics in the results
- `Format-Table` (aliased as `ft`): for generating a clean visual for larger sets of data

At first, I was using just the commandlets and found a crude way of quickly "turning on and off" certian filters via the following pipelining + commenting strategy:

```ps1
$rawData |`
? color -Match 'Gray', 'Silver' |`
? dealer -Match 'Puente|Corona' |`
#? model -Match 'SE Hybrid$' |`
sort dealer, color |` 
ft -groupBy dealer
```

Realizing that some of the more complicated queries would take up a lot of screen space if I kept going at it this way, I opted to move towards a custom function that would take parameter and flags for queries instead. One such example is filtering by vehicles with a specific SET of options added on. 

The result is this powershell module that:
- parses the data.json file to extract specific attributes among the entries in the inventory dataset
- provides a function/command that can be used to filter by color, distance, dealership, model, and options
- auto formats as a table if not being pipelined into another process

> Batteries Not Included!
>
> Toyota's site had a disclaimer about how their data could be used. To be on the safe side, I avoided uploading the data that I found on their site. Thankfully, retrieving the data is pretty straightforward.
>
> ~~I might revisit to make a script that automate the process eventually~~
> Edit: Revisited and wrote a script using puppeteer

## TODO
- [x] Write a better setup/usage docs
- [ ] Provide documentation on how to use `Get-DealerInventory`
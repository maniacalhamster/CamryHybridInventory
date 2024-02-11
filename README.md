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
> Toyota's site had a disclaimer about how their data could be used. To be on the safe side, I avoided uploading the data that I found on their site. Thankfully it's a trivial process.
>
> I might revisit to make a script that automate the process eventually

TODO:
- [ ] Write a better README
- [ ] Provide documentation on how to use `Get-DealerInventory`
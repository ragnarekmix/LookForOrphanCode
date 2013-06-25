Param(
    [parameter(Mandatory=$true)]
    [alias("p")]
    $Path="Path",
	[switch]$clean=$false
	)
	
Write-Host "Options: -"
Write-Host "Path = $Path"
Write-Host "Clean = $clean"
Write-Host "==============================================================================="

$orphans = @()
$solutions = Get-ChildItem -Recurse -Include *.csproj $Path
	foreach($solution in $solutions)
	{
		$xml = [xml](Get-Content $solution)
		$dir = Split-Path $solution
		$files_from_csproj = $xml.project.itemgroup | 
		%{ $_.Compile } | 
		%{ $_.Include } |
		?{ $_ } | 
		%{ Join-Path $dir $_ } |
		Sort-Object
		
		$files_from_dir = Get-ChildItem $dir -Recurse -Filter *.cs |
		%{ $_.FullName } |
		Sort-Object
		
		if($files_from_dir -ne $null -and $files_from_csproj -ne $null)
		{
			$dif = Compare-Object -ReferenceObject $files_from_csproj -DifferenceObject $files_from_dir -IncludeEqual
			foreach($item in $dif)
			{
				if($item.sideindicator -eq "=>")
				{
					$orphans += $item.InputObject
				}
			}
		}
	}

Write-Host Orphan .cs files:
foreach($orphan in $orphans)
{
	Write-Host $orphan
	if($clean)
	{
		Remove-Item $orphan
	}
}
Write-Host "==============================================================================="
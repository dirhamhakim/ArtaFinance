$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$reviewRoot = 'D:\Aplikasi Keuangan\design\review-v2'
$entries = Get-Content -LiteralPath (Join-Path $reviewRoot 'index.json') -Raw -Encoding UTF8 | ConvertFrom-Json
for ($sheetIndex=0; $sheetIndex -lt [Math]::Ceiling($entries.Count/6); $sheetIndex++) {
 $canvas=New-Object System.Drawing.Bitmap (1260,1900)
 $g=[System.Drawing.Graphics]::FromImage($canvas)
 $g.Clear([System.Drawing.Color]::FromArgb(48,48,48))
 $font=New-Object System.Drawing.Font ('Arial',12)
 for($slot=0;$slot -lt 6;$slot++) {
  $entryIndex=$sheetIndex*6+$slot
  if($entryIndex -ge $entries.Count){break}
  $entry=$entries[$entryIndex]
  $sourceImage=[System.Drawing.Image]::FromFile((Join-Path $reviewRoot ($entry.route+'.png')))
  $cellX=($slot%3)*420
  $cellY=[Math]::Floor($slot/3)*950
  $g.DrawString(('{0:D2} / {1}' -f ($entryIndex+1),$entry.route),$font,[System.Drawing.Brushes]::White,$cellX+4,$cellY+4)
  $g.DrawImage($sourceImage,[int]($cellX+4),[int]($cellY+30),$sourceImage.Width,$sourceImage.Height)
  $sourceImage.Dispose()
 }
 $canvas.Save((Join-Path $reviewRoot ('contact-{0:D2}.jpg' -f ($sheetIndex+1))),[System.Drawing.Imaging.ImageFormat]::Jpeg)
 $font.Dispose();$g.Dispose();$canvas.Dispose()
}
Write-Output ('Reviewed export count: '+$entries.Count)

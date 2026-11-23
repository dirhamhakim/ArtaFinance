$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing,System.Core -TypeDefinition @'
using System;
using System.Drawing;
using System.Collections.Generic;
using System.Linq;
public static class ReferencePalette {
 public static string[] Measure(string path) {
  using (var b=new Bitmap(path)) {
   var colors=new Dictionary<int,int>();
   for(int y=0;y<b.Height;y+=4) for(int x=0;x<b.Width;x+=4) {
    var c=b.GetPixel(x,y); int rgb=((c.R/8)*8<<16)|((c.G/8)*8<<8)|((c.B/8)*8);
    if(!colors.ContainsKey(rgb)) colors[rgb]=0; colors[rgb]++;
   }
   return colors.OrderByDescending(p=>p.Value).Take(12).Select(p=>"#"+p.Key.ToString("X6")+":"+p.Value).ToArray();
  }
 }
}
'@
$referenceRoot = 'D:\Aplikasi Keuangan\design\refferences'
$analysisRoot = 'D:\Aplikasi Keuangan\design\reference-analysis'
$referenceFiles = @(Get-ChildItem -LiteralPath $referenceRoot -File | Sort-Object Name)
$palettes = @()
$segments = @()
for ($referenceIndex=0; $referenceIndex -lt $referenceFiles.Count; $referenceIndex++) {
 $referenceFile=$referenceFiles[$referenceIndex]
 $palettes += [pscustomobject]@{index=$referenceIndex+1;file=$referenceFile.Name;quantized8=[ReferencePalette]::Measure($referenceFile.FullName)}
 if (($referenceIndex+1) -in @(1,2,6,7,9,11,19,32)) {
  $sourceImage=[System.Drawing.Image]::FromFile($referenceFile.FullName)
  $scaledHeight=[int]($sourceImage.Height*412.0/$sourceImage.Width)
  $scaled=New-Object System.Drawing.Bitmap (412,$scaledHeight)
  $sg=[System.Drawing.Graphics]::FromImage($scaled)
  $sg.InterpolationMode=[System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $sg.DrawImage($sourceImage,0,0,412,$scaledHeight)
  $sg.Dispose(); $sourceImage.Dispose()
  for ($offset=0; $offset -lt $scaledHeight; $offset+=860) {
   $clipHeight=[Math]::Min(900,$scaledHeight-$offset)
   $clip=New-Object System.Drawing.Bitmap (412,900)
   $cg=[System.Drawing.Graphics]::FromImage($clip)
   $cg.Clear([System.Drawing.Color]::FromArgb(17,17,17))
   $cg.DrawImage($scaled,(New-Object System.Drawing.Rectangle (0,0,412,$clipHeight)),(New-Object System.Drawing.Rectangle (0,$offset,412,$clipHeight)),[System.Drawing.GraphicsUnit]::Pixel)
   $clipPath=Join-Path $analysisRoot ('detail-{0:D2}-{1:D2}.jpg' -f ($referenceIndex+1),[int]($offset/860+1))
   $clip.Save($clipPath,[System.Drawing.Imaging.ImageFormat]::Jpeg)
   $segments += [pscustomobject]@{path=$clipPath;label=('{0:D2} / y {1}' -f ($referenceIndex+1),$offset)}
   $cg.Dispose();$clip.Dispose()
  }
  $scaled.Dispose()
 }
}
$palettes | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $analysisRoot 'sampled-palette.json') -Encoding UTF8
for ($sheetIndex=0; $sheetIndex -lt [Math]::Ceiling($segments.Count/6); $sheetIndex++) {
 $canvas=New-Object System.Drawing.Bitmap (1260,1880)
 $g=[System.Drawing.Graphics]::FromImage($canvas);$g.Clear([System.Drawing.Color]::FromArgb(42,42,42))
 $font=New-Object System.Drawing.Font ('Arial',12)
 for($slot=0;$slot -lt 6;$slot++) {
  $segmentIndex=$sheetIndex*6+$slot;if($segmentIndex -ge $segments.Count){break}
  $segment=$segments[$segmentIndex];$sourceImage=[System.Drawing.Image]::FromFile($segment.path)
  $cellX=($slot%3)*420;$cellY=[Math]::Floor($slot/3)*940
  $g.DrawString($segment.label,$font,[System.Drawing.Brushes]::White,$cellX+4,$cellY+4)
  $g.DrawImage($sourceImage,[int]($cellX+4),[int]($cellY+30),412,900)
  $sourceImage.Dispose()
 }
 $canvas.Save((Join-Path $analysisRoot ('long-contact-{0:D2}.jpg' -f ($sheetIndex+1))),[System.Drawing.Imaging.ImageFormat]::Jpeg)
 $font.Dispose();$g.Dispose();$canvas.Dispose()
}
$palettes | Where-Object {$_.index -in @(15,22,30,38,41,51,56)} | ConvertTo-Json -Depth 4
Write-Output ('Long screenshot segments: '+$segments.Count)

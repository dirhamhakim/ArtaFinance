Add-Type -AssemblyName System.Drawing
$referenceRoot = 'D:\Aplikasi Keuangan\design\refferences'
$analysisRoot = 'D:\Aplikasi Keuangan\design\reference-analysis'
New-Item -ItemType Directory -Path $analysisRoot -Force | Out-Null
$referenceFiles = @(Get-ChildItem -LiteralPath $referenceRoot -File | Sort-Object Name)
$inventory = @()
$cellWidth = 400
$cellHeight = 960
for ($sheetIndex = 0; $sheetIndex -lt [Math]::Ceiling($referenceFiles.Count / 6); $sheetIndex++) {
    $canvas = New-Object System.Drawing.Bitmap (1200,1920)
    $graphics = [System.Drawing.Graphics]::FromImage($canvas)
    $graphics.Clear([System.Drawing.Color]::FromArgb(42,42,42))
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $captionFont = New-Object System.Drawing.Font ('Arial',12)
    for ($slot = 0; $slot -lt 6; $slot++) {
        $referenceIndex = $sheetIndex * 6 + $slot
        if ($referenceIndex -ge $referenceFiles.Count) { break }
        $referenceFile = $referenceFiles[$referenceIndex]
        $sourceImage = [System.Drawing.Image]::FromFile($referenceFile.FullName)
        $inventory += [pscustomobject]@{index=$referenceIndex+1;file=$referenceFile.Name;width=$sourceImage.Width;height=$sourceImage.Height}
        $cellX = ($slot % 3) * $cellWidth
        $cellY = [Math]::Floor($slot / 3) * $cellHeight
        $graphics.DrawString(('{0:D2} / {1}' -f ($referenceIndex+1),$referenceFile.BaseName.Replace('Screenshot_20261118_','').Replace('_Stockbit','')), $captionFont, [System.Drawing.Brushes]::White, $cellX+8, $cellY+6)
        $ratio = [Math]::Min(392.0/$sourceImage.Width, 920.0/$sourceImage.Height)
        $targetWidth = [int]($sourceImage.Width*$ratio)
        $targetHeight = [int]($sourceImage.Height*$ratio)
        $graphics.DrawImage($sourceImage, [int]($cellX+($cellWidth-$targetWidth)/2), [int]($cellY+32), $targetWidth, $targetHeight)
        $sourceImage.Dispose()
    }
    $outputPath = Join-Path $analysisRoot ('contact-{0:D2}.jpg' -f ($sheetIndex+1))
    $canvas.Save($outputPath,[System.Drawing.Imaging.ImageFormat]::Jpeg)
    $captionFont.Dispose()
    $graphics.Dispose()
    $canvas.Dispose()
}
$inventory | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $analysisRoot 'inventory.json') -Encoding UTF8
$inventory | Format-Table -AutoSize

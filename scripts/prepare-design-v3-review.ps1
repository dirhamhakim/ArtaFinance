$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$workspace = Split-Path -Parent $PSScriptRoot
$reviewDirectory = Join-Path $workspace 'design\review-v3'
$index = Get-Content -LiteralPath (Join-Path $reviewDirectory 'index.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$screens = @($index.screens)
$columns = 4
$perSheet = 12
$cellWidth = 230
$cellHeight = 490
$titleFont = [System.Drawing.Font]::new('Arial', 18, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$labelFont = [System.Drawing.Font]::new('Arial', 12, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
$greyBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(190, 190, 190))
try {
  for ($start = 0; $start -lt $screens.Count; $start += $perSheet) {
    $batch = @($screens | Select-Object -Skip $start -First $perSheet)
    $rows = [int][Math]::Ceiling($batch.Count / [double]$columns)
    $bitmap = [System.Drawing.Bitmap]::new(950, 64 + $rows * $cellHeight)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    try {
      $graphics.Clear([System.Drawing.Color]::FromArgb(36, 36, 36))
      $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
      $graphics.DrawString(('Arta v3 / review {0} / {1} screens' -f (1 + $start / $perSheet), $screens.Count), $titleFont, $whiteBrush, 20, 18)
      for ($i = 0; $i -lt $batch.Count; $i++) {
        $item = $batch[$i]
        $x = 20 + ($i % $columns) * $cellWidth
        $y = 64 + [Math]::Floor($i / $columns) * $cellHeight
        $sourceImage = [System.Drawing.Image]::FromFile($item.path)
        try {
          $graphics.DrawImage($sourceImage, [System.Drawing.Rectangle]::new($x, $y, 200, 444))
        } finally { $sourceImage.Dispose() }
        $label = '{0} / {1}' -f $item.id, $item.name
        if ($label.Length -gt 34) { $label = $label.Substring(0, 31) + '...' }
        $graphics.DrawString($label, $labelFont, $greyBrush, $x, $y + 450)
        $graphics.DrawString($item.theme, $labelFont, $greyBrush, $x, $y + 466)
      }
      $destination = Join-Path $reviewDirectory ('contact-{0:00}.png' -f (1 + $start / $perSheet))
      $bitmap.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
      Write-Output $destination
    } finally { $graphics.Dispose(); $bitmap.Dispose() }
  }
} finally {
  $titleFont.Dispose(); $labelFont.Dispose(); $whiteBrush.Dispose(); $greyBrush.Dispose()
}

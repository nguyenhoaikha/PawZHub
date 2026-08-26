$ErrorActionPreference = 'Stop'
$content = Get-Content "D:\App\Desktop\PawZHub\checkkey.lua" -Raw
$lines = $content -split "`n"
$depth = 0
$inMLStr = $false
$inLineStr = $false
$strChar = ''
$inLineComment = $false

for ($i = 0; $i -lt $lines.Count; $i++) {
  $line = $lines[$i]
  $j = 0
  while ($j -lt $line.Length) {
    $c = $line[$j]
    if ($inLineComment) { $j++; continue }
    if ($inMLStr) {
      if ($c -eq ']' -and $j + 1 -lt $line.Length -and $line[$j+1] -eq ']') {
        $inMLStr = $false; $j += 2; continue
      }
      $j++; continue
    }
    if ($inLineStr) {
      if ($c -eq '\\') { $j += 2; continue }
      if ($c -eq $strChar) { $inLineStr = $false }
      $j++; continue
    }
    if ($c -eq '-' -and $j + 1 -lt $line.Length -and $line[$j+1] -eq '-') {
      $inLineComment = $true; $j += 2; continue
    }
    if ($c -eq '"' -or $c -eq "'") {
      $inLineStr = $true; $strChar = $c; $j++; continue
    }
    if ($c -eq '[' -and $j + 1 -lt $line.Length -and $line[$j+1] -eq '[') {
      $inMLStr = $true; $j += 2; continue
    }
    if ($c -match '[a-zA-Z_]') {
      $start = $j
      while ($j -lt $line.Length -and $line[$j] -match '[a-zA-Z_0-9]') { $j++ }
      $word = $line.Substring($start, $j - $start)
      $before = if ($start -gt 0) { $line[$start - 1] } else { ' ' }
      $after = if ($j -lt $line.Length) { $line[$j] } else { ' ' }
      $isWord = ($before -notmatch '[a-zA-Z_0-9]') -and ($after -notmatch '[a-zA-Z_0-9]')
      if ($isWord -and ($word -in @('if','function','do','for','while'))) {
        $depth++
      } elseif ($isWord -and $word -eq 'end') {
        $depth--
        if ($depth -lt 0) { Write-Host "Line $($i+1): extra end (depth=$depth): $line"; $depth = 0 }
      }
      continue
    }
    $j++
  }
  $inLineComment = $false
}
Write-Host "Final depth: $depth (expected 0)"

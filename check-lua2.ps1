$ErrorActionPreference = 'Continue'
$content = Get-Content "D:\App\Desktop\PawZHub\checkkey.lua" -Raw
$lines = $content -split "`n"
$stack = New-Object System.Collections.Stack
$lineNum = 0
$inMLStr = $false
$inLineStr = $false
$strChar = ''
$inLineComment = $false

for ($i = 0; $i -lt $lines.Count; $i++) {
  $line = $lines[$i]
  $lineNum = $i + 1
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
      if ($c -eq '\') { $j += 2; continue }
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
      if ($isWord) {
        if ($word -in @('if','function','do','for','while')) {
          $stack.Push(@{ line = $lineNum; word = $word })
        } elseif ($word -eq 'end') {
          if ($stack.Count -eq 0) {
            Write-Host "Line $lineNum : extra 'end' (stack empty)"
          } else {
            $top = $stack.Pop()
          }
        }
      }
      continue
    }
    $j++
  }
  $inLineComment = $false
}
Write-Host "`n--- UNCLOSED BLOCKS ---"
if ($stack.Count -eq 0) {
  Write-Host "All blocks closed."
} else {
  while ($stack.Count -gt 0) {
    $b = $stack.Pop()
    Write-Host "Line $($b.line): unclosed $($b.word)"
  }
}

param(
  [string]$Dist = "dist",
  [string]$Base = "/sublime"
)

if (-not (Test-Path -LiteralPath $Dist)) {
  Write-Error "[postbuild] '$Dist' が見つかりません"
  exit 1
}

# /sublime/ の形に正規化
$prefix = ($Base.TrimEnd('/')) + '/'

# 正規表現パターン
$reAttr        = '=(["''])/(?!sublime/|/|https?:|data:)'
$reSrcset      = 'srcset=(["''])([^"'''']+)\1'
$reSrcsetInner = '(^|,\s*)/(?!sublime/|/|https?:|data:)'
$reCss         = 'url\(\s*/(?!sublime/|/|https?:|data:)'

function Rewrite-Html([string]$s) {
  # href="/..." src="/..." などを /sublime/ 付きに
  $s = [regex]::Replace(
    $s, $reAttr,
    { param($m) "=$($m.Groups[1].Value)$prefix" }
  )

  # srcset="..., /img.webp 2x, /img@3x.webp 3x" の各URLへも付与
  $s = [regex]::Replace(
    $s, $reSrcset,
    {
      param($m)
      $q   = $m.Groups[1].Value
      $val = $m.Groups[2].Value
      $nv  = [regex]::Replace(
        $val, $reSrcsetInner,
        { param($m2) $m2.Groups[1].Value + $prefix }
      )
      "srcset=$q$nv$q"
    }
  )
  return $s
}

function Rewrite-Css([string]$s) {
  # url(/...) -> url(/sublime/...)
  return [regex]::Replace($s, $reCss, "url($prefix")
}

# 対象ファイル列挙
$targets = Get-ChildItem -LiteralPath $Dist -Recurse -File |
  Where-Object { $_.Extension -in @('.html', '.htm', '.css') }

foreach ($f in $targets) {
  $txt = Get-Content -LiteralPath $f.FullName -Raw
  $new = if ($f.Extension -ieq '.css') { Rewrite-Css $txt } else { Rewrite-Html $txt }
  if ($new -ne $txt) {
    [IO.File]::WriteAllText($f.FullName, $new, [Text.UTF8Encoding]::new($false)) # UTF-8(BOMなし)
    Write-Host "fixed: $($f.FullName)"
  }
}

# 念のため .nojekyll を作成
$noj = Join-Path $Dist ".nojekyll"
if (-not (Test-Path -LiteralPath $noj)) {
  Set-Content -LiteralPath $noj -Value "" -NoNewline
  Write-Host "created: $noj"
}

$results = @()
$files = Get-ChildItem -Recurse -Filter '*.dart' lib\
foreach ($f in $files) {
    $file = $f.FullName
    $lines = Get-Content $file
    $lineCount = $lines.Count
    $inAsyncFn = $false
    $awaitSeen = $false
    $mountedSeen = $false
    $lastAwaitLine = 0
    $braceDepth = 0
    $fnBraceDepth = 0

    for ($i = 0; $i -lt $lineCount; $i++) {
        $line = $lines[$i]
        $opens = ([regex]::Matches($line, '\{')).Count
        $closes = ([regex]::Matches($line, '\}')).Count

        if ($line -match '\) async \{' -or $line -match '\) async =>') {
            $inAsyncFn = $true
            $awaitSeen = $false
            $mountedSeen = $false
            $fnBraceDepth = $braceDepth + $opens - $closes
        }

        $braceDepth += $opens - $closes

        if ($inAsyncFn) {
            if ($line -match '^\s*await ' -or $line -match '= await ') {
                $awaitSeen = $true
                $lastAwaitLine = $i + 1
                $mountedSeen = $false
            }
            if ($awaitSeen -and ($line -match '\bmounted\b')) {
                $mountedSeen = $true
            }
            if ($awaitSeen -and -not $mountedSeen -and $line -match 'setState\(') {
                $lineNum = $i + 1
                $msg = "${file}:L${lineNum}: setState without mounted check (last await at L${lastAwaitLine})"
                $results += $msg
            }
            if ($braceDepth -lt $fnBraceDepth) {
                $inAsyncFn = $false
                $awaitSeen = $false
                $mountedSeen = $false
            }
        }
    }
}

$results | ForEach-Object { Write-Output $_ }

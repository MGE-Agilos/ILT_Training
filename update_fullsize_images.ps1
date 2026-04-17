# update_fullsize_images.ps1
# Updates MCPopupThumbnailLink href to use full-size image when available.
# The img src (inline thumbnail) is intentionally kept as the small thumbnail.
# Only the popup (href) shows the full-size image.

$bases = @(
    'c:/Users/MGE/OneDrive - Agilos/Documents/Claude Code Projects/ILT Training/Qlik Sense Data Visualizations',
    'c:/Users/MGE/OneDrive - Agilos/Documents/Claude Code Projects/ILT Training/Qlik Sense Data Modeling'
)

$totalUpdated = 0

foreach ($base in $bases) {
    Get-ChildItem $base -Filter '*.html' | ForEach-Object {
        $path = $_.FullName
        $c = Get-Content $path -Raw -Encoding UTF8
        $orig = $c

        # Only update the href of MCPopupThumbnailLink, NOT the img src
        $c = [regex]::Replace($c,
            '(<a\s+class="MCPopupThumbnailLink[^"]*"[^>]*href=")(\./[^"]+)(")',
            {
                param($m)
                $dir = [System.IO.Path]::GetDirectoryName($path)
                $href = $m.Groups[2].Value

                $absHref = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($dir, $href))
                $hrefFilename = [System.IO.Path]::GetFileName($absHref)
                $hrefFolder = [System.IO.Path]::GetDirectoryName($absHref)

                # Strip _thumb_XXX_YYY to get base filename
                $baseName = [regex]::Replace($hrefFilename, '_thumb_\d+_\d+\.', '.')
                $fullSizePath = [System.IO.Path]::Combine($hrefFolder, $baseName)

                if ($baseName -ne $hrefFilename -and (Test-Path $fullSizePath)) {
                    $hrefDir = [System.IO.Path]::GetFileName($hrefFolder)
                    $newHref = './' + $hrefDir + '/' + $baseName
                    return $m.Groups[1].Value + $newHref + $m.Groups[3].Value
                }
                return $m.Value
            })

        if ($c -ne $orig) {
            Set-Content $path $c -Encoding UTF8 -NoNewline
            Write-Host "Updated: $($_.Name)"
            $totalUpdated++
        }
    }
}

Write-Host "`nTotal files updated: $totalUpdated"
Write-Host "Now run: git add . && git commit -m 'Use full-size images in popups' && git push origin main"

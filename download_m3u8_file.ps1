param (
    [string]$quality = "720"
)

# available quality
$availableQualities = @("1080", "720", "480", "360")

if (-not $availableQualities.Contains($quality)) {
    Write-Host "Quility unavailable"
    $quality = "720"
}

# path to ffmpeg (example ".\ffmpeg\bin\ffmpeg.exe")
$ffmpegPath = ""

$outputDirectory = ".\download_video"

# .m3u8 file dir
$m3u8Directory = ".\m3u8_file"
$m3u8Files = Get-ChildItem -Path $m3u8Directory -Filter "*.m3u8" -File
$m3u8Files = $m3u8Files | Sort-Object { [int]($_.Name -replace '\D', '') }

# hash table to store URL groups by resolution
$groupedUrlsByResolution = @{}

foreach ($file in $m3u8Files) {
    $content = Get-Content -Path $file.FullName

    foreach ($line in $content) {
        # line containing the resolution
        if ($line -match "RESOLUTION=((\d+)x(\d+))") {  
            $resolution = $matches[3]
			
            # look for the URL in the following line
            $nextLineIndex = [array]::IndexOf($content, $line) + 1
            if ($nextLineIndex -lt $content.Count) {
                $nextLine = $content[$nextLineIndex]
                if ($nextLine -match "https?://") {
                    $url = $nextLine

                    if (-not $groupedUrlsByResolution.ContainsKey($resolution)) {
                        $groupedUrlsByResolution[$resolution] = @()
                    }
                    $groupedUrlsByResolution[$resolution] += $url
					break
                }
            }
        }
    }
}
$sortedKeys = $groupedUrlsByResolution.Keys | Sort-Object { [int]$_ }
$count = 1
foreach ($url in $groupedUrlsByResolution[$quality]) {
	$filename = "lesson_$count"
	$outputFilePath = Join-Path -Path $outputDirectory -ChildPath "$($filename).mp4"
	
	Write-Host "download "${url}""
	 # ffmpeg
    $ffmpegCommand = "$ffmpegPath -loglevel 'repeat+level+quiet' -protocol_whitelist 'file,http,https,tcp,tls' -i `"$url`" `"$($filename).mp4`""
	
	# start ffmpeg
	Start-Process -FilePath $ffmpegPath -ArgumentList "-loglevel", "repeat+level+quiet", "-protocol_whitelist", "file,http,https,tcp,tls", "-i", `"$($url)`", `"$outputFilePath`" -Wait -NoNewWindow
	
	$count++
}




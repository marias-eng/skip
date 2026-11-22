$ErrorActionPreference = "Stop"

$containerName = "lab03-rollback-good"
$imageName = "lab03-rollback-good"
$port = 5000
$url = "http://localhost:$port/health"

Write-Host "Starting rollback..."

$startTime = Get-Date

$existing = docker ps -aq --filter "name=^/$containerName$"

if ($existing) {
    docker rm -f $containerName
}

docker run -d --name $containerName -p "${port}:5000" $imageName

$success = $false

for ($i = 0; $i -lt 15; $i++) {
    $response = curl.exe --silent --show-error --fail $url

    if ($LASTEXITCODE -eq 0) {
        $success = $true
        break
    }

    Start-Sleep -Seconds 1
}

$elapsed = (Get-Date) - $startTime

if ($success) {
    Write-Host "Rollback successful!"
    Write-Host "Response: $response"
    Write-Host ("Rollback time: {0:N2} seconds" -f $elapsed.TotalSeconds)
} else {
    Write-Host "Rollback failed!"
    docker logs $containerName
    exit 1
}

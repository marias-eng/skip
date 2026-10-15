
$BaseUrl = "https://localhost"

function Check-Status {
    param(
        [string]$Name,
        [string]$Url,
        [string]$Expected
    )

    $code = curl.exe -k -s -o NUL -w "%{http_code}" $Url

    if ($code -eq $Expected) {
        Write-Host "[PASS] $Name ($code)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $Name (expected $Expected, got $code)" -ForegroundColor Red
    }
}

Write-Host "`n=== NGINX LAB 1 CHECK ===" -ForegroundColor Cyan

# 1. HTTP -> HTTPS
$redirect = curl.exe -s -o NUL -w "%{http_code}" http://localhost/
if ($redirect -eq "301") {
    Write-Host "[PASS] HTTP -> HTTPS (301)" -ForegroundColor Green
} else {
    Write-Host "[FAIL] HTTP redirect ($redirect)" -ForegroundColor Red
}

# 2. HTTPS frontend
Check-Status "HTTPS frontend" "$BaseUrl/" "200"

# 3. API
Check-Status "API tasks" "$BaseUrl/api/tasks" "200"

# 4. Backend balancing
Write-Host "`nBackend instances:"
1..6 | ForEach-Object {
    $headers = curl.exe -k -s -D - -o NUL "$BaseUrl/api/tasks"
    $instance = $headers | Select-String "X-Backend-Instance:"
    Write-Host $instance
    Start-Sleep -Milliseconds 250
}

# 5. Virtual hosts
Check-Status "Daily virtual host" "https://daily.local/" "200"
Check-Status "Second virtual host" "https://second.local/" "200"

# 6. Alias
Check-Status "Docs alias" "$BaseUrl/docs/" "200"

# 7. Custom 404
Check-Status "Custom 404" "$BaseUrl/nonexistent-page" "404"

# 8. Basic Auth (without password)
Check-Status "Admin without auth" "$BaseUrl/admin" "401"

# 9. Rate limiting
Write-Host "`nTesting rate limiting..." -ForegroundColor Cyan

$jobs = 1..30 | ForEach-Object {
    Start-Job -ScriptBlock {
        curl.exe -k -s -o NUL -w "%{http_code}" https://localhost/api/tasks
    }
}

$results = @($jobs | Wait-Job | Receive-Job)
$jobs | Remove-Job

$rejected = @($results | Where-Object { $_ -eq "429" }).Count
Write-Host "429 responses: $rejected"

if ($rejected -gt 0) {
    Write-Host "[PASS] Rate limiting" -ForegroundColor Green
} else {
    Write-Host "[WARN] No 429 responses observed" -ForegroundColor Yellow
}

Write-Host "`n=== CHECK COMPLETE ===" -ForegroundColor Cyan

$port = 8080
$prefix = "http://127.0.0.1:$port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Output "HTTP Server listening on $prefix"

$rootDir = $PSScriptRoot
if (-not $rootDir) {
    $rootDir = "C:\Users\João\Downloads\kveld-showroom.aura.build\gibson-es335-site"
}

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $req = $context.Request
        $res = $context.Response

        $path = $req.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrWhiteSpace($path)) {
            $path = "index.html"
        }
        $path = $path -replace '/', '\'
        $fullPath = Join-Path $rootDir $path

        if (Test-Path $fullPath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($fullPath).ToLower()
            $contentType = switch ($ext) {
                ".html"  { "text/html; charset=utf-8" }
                ".css"   { "text/css; charset=utf-8" }
                ".js"    { "application/javascript; charset=utf-8" }
                ".webp"  { "image/webp" }
                ".jpg"   { "image/jpeg" }
                ".jpeg"  { "image/jpeg" }
                ".png"   { "image/png" }
                ".svg"   { "image/svg+xml" }
                ".woff2" { "font/woff2" }
                default  { "application/octet-stream" }
            }
            $res.ContentType = $contentType
            $bytes = [System.IO.File]::ReadAllBytes($fullPath)
            $res.ContentLength64 = $bytes.Length
            $res.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $res.StatusCode = 404
            $msg = [System.Text.Encoding]::UTF8.GetBytes("404 Not Found: $path")
            $res.ContentLength64 = $msg.Length
            $res.OutputStream.Write($msg, 0, $msg.Length)
        }
        $res.OutputStream.Close()
    }
} finally {
    $listener.Stop()
}

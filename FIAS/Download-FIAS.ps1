#Requires -Version 5.1
param (
    [ValidateSet('InternetExplorer', 'FireFox', 'Chrome', 'Opera', 'Safari')]
    [String]$UserAgent,
    [String]$Path = 'C:\TMP',
    [switch]$UseProxy = $false
)

# Указываем ссылку на скачивание файла
$url = "http://fias.nalog.ru/Public/Downloads/Actual/fias_xml.rar"

# Проверяем наличие каталога, в который будет скачиваться файл и
# при необходимости создаем его.
if (!(Test-Path $path)) {
    New-Item -Path $path -ItemType Directory | Out-Null
}

# Создаем объект .Net, который будет скачивать файл
$download = New-Object Net.WebClient

# Если необходимо, то НЕ стираем в объекте .Net значение прокси сервера,
# и тогда включаем авторизацию с текущим логином и паролем.
if (!$UseProxy) {
    $download.Proxy = $null
}
else {
    $download.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
}

# Опциоально добавляем в объект .Net свойтво User-Agent
if ($UserAgent) {
    $download.Headers['User-Agent'] = [Microsoft.PowerShell.Commands.PSUserAgent]::$UserAgent
}

function Get-FIAS {
    # Формируем имя скачиваемого файла
    $i = 1
    $date = Get-Date -Format { dd-MM-yyyy }
    do {
        $script:output = "$path\FIAS_$date`_$i.zip"
        $i++
    } until (!(Test-Path $output))
        
    # Запускаем метод объекта .Net для скачивания файла
    $download.DownloadFile($url, $output)
}

# Запускаем скачивание файла
Get-FIAS

# проверяем с помощью 7zip скачанный архив и если он битый, то запускаем скачиание заново
$7z = 'C:\Program Files\7-Zip\7z.exe'
& $7z t $output -r | Out-Null
if ($LASTEXITCODE -ne 0) {
    Remove-Item $output -Force
    Get-FIAS
}
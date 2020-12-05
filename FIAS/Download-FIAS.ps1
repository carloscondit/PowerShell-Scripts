#Requires -Version 5.1
[CmdletBinding()]
param (
    [ValidateSet('InternetExplorer', 'FireFox', 'Chrome', 'Opera', 'Safari')]
    [String]$UserAgent,
    [String]$Path = 'C:\TMP',
    [switch]$UseProxy = $false
    )
    
    Set-StrictMode -Version 2
    
    # Указываем ссылку на скачивание файла.
    $url = "http://fias.nalog.ru/Public/Downloads/Actual/fias_xml.rar"
    
    # Создаем функцию для скачивания файла
    function Get-FIAS {
        # Формируем имя скачиваемого файла.
        $i = 1
    $date = Get-Date -Format 'dd-MM-yyyy'
    do {
        $script:output = "$path\FIAS_$date`_$i.zip"
        $i++
    } until (!(Test-Path $output))
    Write-Verbose "Полный путь к скачиваемому файлу: ""$output""."    
    # Запускаем метод объекта .Net для скачивания файла.
    Write-Verbose "Запускаем скачивание файла."
    $download.DownloadFile($url, $output)
}

# Создаем функция для проверки скачанного архива.
$7z = "$env:ProgramFiles\7-Zip\7z.exe"
function Test-Archive {
    Write-Verbose "Запускаем проверку скачанного архива с помощью 7zip."
    & $7z t $output -r | Out-Null
}

# Проверяем наличие каталога, в который будет скачиваться файл и
# при необходимости создаем его. Если не удается, то прерываем работу скрипта.
Write-Verbose "Проверяем наличие каталога ""$path""."
if (!(Test-Path $path)) {
    Write-Verbose "Каталога ""$path"" не существует. Создаем его."
    New-Item -Path $path -ItemType Directory -ErrorAction Stop | Out-Null
}

# Создаем объект .Net, который будет скачивать файл.
$download = New-Object Net.WebClient

# Если необходимо, то НЕ стираем в объекте .Net значение прокси сервера,
# и тогда включаем авторизацию с текущим логином и паролем.
if (!$UseProxy) {
    Write-Verbose "Отключаем использование прокси."
    $download.Proxy = $null
}
else {
    Write-Verbose "Остаеляем прокси с указанием учетных данных текущего пользователя."
    $download.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
}

# Опциоально добавляем в объект .Net свойтво User-Agent.
if ($UserAgent) {
    Write-Verbose "Добавляем заголовок использования User-Agent со значением ""$UserAgent""."
    $download.Headers['User-Agent'] = [Microsoft.PowerShell.Commands.PSUserAgent]::$UserAgent
}


# Запускаем скачивание файла
Get-FIAS

# Запускаем проверку скачанного архива с помощью 7zip.
Test-Archive

# Если проверка завершиться ошибкой, то запускаем повторное скачивание и проверку архива.
while ($LASTEXITCODE -ne 0) {
    Write-Warning "Архив поврежден. Удаляем его и пробуем скачать заново."
    Remove-Item $output -Force
    Get-FIAS
    Test-Archive
}
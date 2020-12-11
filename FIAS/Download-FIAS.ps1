<#
.SYNOPSIS
Скрипт для скачивания полной БД ФИАС с сайта https://fias.nalog.ru
.DESCRIPTION
Этот скрипт скачивает архив с БД ФИАС по умолчанию в каталог "C:\TMP". Если такого каталога нет,
то он будет создан (при наличии прав, иначе работа скрипта будет завершена). После скачивания запускается
проверка архива с помощью 7zip. Если архив окажется битым, то он удалется и скачивание запускается
снова и так до тех пор, пока не скачается целый архив. Проверку можно отключить с помощью парамерта -NoTest.
С помощью параметра -NoProxy можно отключить использование прокси.
.EXAMPLE
PS C:\> .\Download-FIAS.ps1
Запуск скрипта без параметров. Архив будет скачан в каталог "C:\TMP" через прокси (при наличии).
.EXAMPLE
PS C:\> .\Download-FIAS.ps1 -Path 'C:\FIAS' -NoProxy
Скачивание будет запущено без прокси. Архив будет скачан в каталог "C:\FIAS".
.EXAMPLE
PS C:\> .\Download-FIAS.ps1 -NoProxy -Verbose
Скачивание будет запущено без прокси в каталог "C:\TMP" с подробным выводом информации.
.NOTES
11.12.2020
#>
#Requires -Version 5.1
[CmdletBinding()]
param (
    # Путь в каталог, в который будет скачиваться файл
    [String]$Path = 'C:\TMP',
    # Отключение прокси
    [switch]$NoProxy = $false,
    # Проверка скачанного архива
    [switch]$NoTest = $false
)
    
Set-StrictMode -Version 2
    
# Указываем ссылку на скачивание файла.
$url = "http://fias.nalog.ru/Public/Downloads/Actual/fias_xml.rar"

# Указываем путь до консольной программы 7zip
$7z = "$env:ProgramFiles\7-Zip\7z.exe"

# Проверяем наличие каталога, в который будет скачиваться файл и
# при необходимости создаем его. Если не удается, то прерываем работу скрипта.
Write-Verbose "Проверяем наличие каталога ""$path""."
if (!(Test-Path $path)) {
    Write-Verbose "Каталога ""$path"" не существует. Создаем его."
    New-Item -Path $path -ItemType Directory -ErrorAction Stop | Out-Null
} #if

# Создаем объект .Net, который будет скачивать файл.
$download = New-Object Net.WebClient

# Если необходимо, то НЕ стираем в объекте .Net значение прокси сервера,
# и тогда включаем авторизацию с текущим логином и паролем.
if ($NoProxy) {
    Write-Verbose "Отключаем использование прокси."
    $download.Proxy = $null
} #if
else {
    Write-Verbose "Добавляем учетные данные текущего пользователя в случае если используется прокси."
    $download.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials
} #else

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
} #function

# Запускаем функцию для скачивания файла
Get-FIAS

# Блок проверки скачанного архива
if (!$NoTest) {
    if (Test-Path $7z) {
        function Test-Archive {
            Write-Verbose "Запускаем проверку скачанного архива с помощью 7zip."
            & $7z t $output -r -bse0 -bso0
        } #function

        Test-Archive
        
        # Если проверка завершиться ошибкой, то удаляем скачанный файла и 
        # запускаем повторное скачивание и проверку архива.
        while ($LASTEXITCODE -ne 0) {
            Write-Warning "Архив поврежден. Удаляем его и пробуем скачать заново."
            Remove-Item $output -Force
            Get-FIAS
            Test-Archive
        } #while
    } #if
        
    else {
        Write-Warning 'Не найден каталог с ""7z.exe"". Проверка архива не была сделана.'
    } #else

} #if 

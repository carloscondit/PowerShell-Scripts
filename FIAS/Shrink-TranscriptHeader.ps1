param (
    [Parameter(Mandatory = $true,
        Position = 0,
        ValueFromPipeline = $true,
        HelpMessage = "Путь к одному или нескольким файлам с транскриптами")]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $Path  
)
    
begin {
    $MatchList = @('Начало записи сценария Windows PowerShell', 'Windows PowerShell transcript start')
}
    
process {
    foreach ($file in $path) {
        Write-Verbose "Начинаем обработку файла '$($File)'"
        $state = 0
        $ShrinkList = [System.Collections.ArrayList]@()
        $FullList = Get-Content -Path "$file"
        switch ($FullList) {
            { $_ -in $MatchList } {
                $state = 1
                [void]$ShrinkList.Add($_)            
                Continue
            }
            '**********************' {
                $state = 0
                [void]$ShrinkList.Add($_)            
                Continue
            }
            default {
                if ($state -eq 0) { [void]$ShrinkList.Add($_) }
                elseif ($state -eq 1) { [void]$ShrinkList.Add($_); $state++ }       
                elseif ($state -in (2..15)) { $state++ }
                elseif ($state -gt 15) {
                    Write-Warning "Заголовок одного из транскриптов в файле '$($File)' поврежден. Файл оставлен без изменений."
                    $ShrinkList = [System.Collections.ArrayList]@()
                    break
                }
                else { $state = 0; [void]$ShrinkList.Add($_) }
            }
        }
        if ($ShrinkList.Count -gt 0) {
            Set-Content -Path "$file" -Value $ShrinkList
        }
        Write-Verbose "Обработка файла '$($File)' завершена."
        
    }
}
    
end {



}




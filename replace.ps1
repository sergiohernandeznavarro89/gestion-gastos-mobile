$directory = "c:\proyectos\gestion-gastos-mobile\lib"
$importStatement = "import 'package:gestion_gastos/core/widgets/custom_spinner.dart';"

Get-ChildItem -Path $directory -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "CircularProgressIndicator") {
        $newContent = $content -replace "CircularProgressIndicator\(.*?\)", "CustomSpinner(size: 24, color: Colors.white)"
        $newContent = $newContent -replace "CircularProgressIndicator\(\)", "CustomSpinner()"
        
        if (-not ($newContent -match "custom_spinner.dart")) {
            $newContent = $newContent -replace "(?m)^(import .*?;)", "`$1`n$importStatement"
        }
        
        Set-Content -Path $_.FullName -Value $newContent -NoNewline
    }
}

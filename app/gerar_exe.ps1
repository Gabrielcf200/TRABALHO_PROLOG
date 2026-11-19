# Gera dist\SuperViaIA\SuperViaIA.exe (etapas/08-executavel.md).
# Uso, na raiz do projeto:  powershell -ExecutionPolicy Bypass -File app\gerar_exe.ps1
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot)

python -m pip install --quiet "pyinstaller>=6,<7"
python -m PyInstaller --noconfirm --windowed --name SuperViaIA `
    --collect-data customtkinter `
    --add-data "src;src" `
    app\main.py

# O usuário põe a chave aqui, ao lado do .exe.
Copy-Item app\.env.example dist\SuperViaIA\.env.example
if (Test-Path app\.env) { Write-Host "Seu app\.env NAO foi copiado. Copie para dist\SuperViaIA\.env se quiser." }
Write-Host "Pronto: dist\SuperViaIA\SuperViaIA.exe"

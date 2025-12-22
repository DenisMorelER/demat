
[CmdletBinding()]
param(
    [string]$SolutionName = "Dematerialisation_des_Processus",
    [string]$EnvironmentUrl,        # ex: https://org2cd222c0.crm4.dynamics.com (sans slash final)
    [string]$Output = ".\tmp",
    [string]$UnpackFolder = ".\src\solution",
    [switch]$ForceAuthCreate
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ("Demarrage - Export + Unpack de la solution '{0}'" -f $SolutionName) -ForegroundColor Cyan

# 0) Vérif pac
if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    throw "Power Platform CLI 'pac' introuvable. Installe-le (https://aka.ms/pac) ou ajoute son dossier au PATH."
}
Write-Host ("pac OK : {0}" -f (pac --version)) -ForegroundColor DarkGreen

# 1) Sélection org si fournie
if ($EnvironmentUrl) {
    $EnvironmentUrl = $EnvironmentUrl.TrimEnd('/')
    Write-Host ("Environnement cible: {0}" -f $EnvironmentUrl) -ForegroundColor Yellow
    if ($ForceAuthCreate) { pac auth create --url $EnvironmentUrl }
    pac org select -env $EnvironmentUrl
}

Write-Host "Organisation sélectionnée :" -ForegroundColor Cyan
pac org who

# 2) Vérif solution
Write-Host ("Vérification de la solution '{0}'..." -f $SolutionName) -ForegroundColor Cyan
$solutions = pac solution list
if (-not ($solutions | Select-String -Pattern ("^\s*{0}\b" -f [regex]::Escape($SolutionName)) -CaseSensitive:$false)) {
    Write-Host $solutions
    throw ("Solution '{0}' introuvable dans cet environnement. Vérifie 'pac solution list'." -f $SolutionName)
}

# 3) Dossiers
New-Item -ItemType Directory -Force -Path $Output | Out-Null
New-Item -ItemType Directory -Force -Path $UnpackFolder | Out-Null

$absOutDir = (Resolve-Path $Output).Path
$zipUnmanaged = Join-Path $absOutDir ("{0}_unmanaged.zip" -f $SolutionName)

# 4) Export unmanaged (logs visibles)
Write-Host ("Export (unmanaged) -> {0}" -f $zipUnmanaged) -ForegroundColor Cyan
pac solution export --name $SolutionName --outputFile "$zipUnmanaged" --managed false

if (-not (Test-Path "$zipUnmanaged")) {
    throw ("Export échoué: le fichier {0} est introuvable. Regarde le message ci-dessus." -f $zipUnmanaged)
}
Write-Host ("ZIP unmanaged exporté : {0}" -f $zipUnmanaged) -ForegroundColor DarkGreen

# 5) Unpack pour Git (sans --processCanvasApps car déprécié)
Write-Host ("Unpack vers '{0}'..." -f $UnpackFolder) -ForegroundColor Cyan
pac solution unpack --zipFile "$zipUnmanaged" --folder "$UnpackFolder" --allowDelete true

Write-Host "Terminé !" -ForegroundColor Green
Write-Host (" - ZIP exporté : {0}" -f $zipUnmanaged)
Write-Host (" - Contenu unpacké : {0}" -f $UnpackFolder)

Write-Host ""
Write-Host "Prochaines étapes :" -ForegroundColor Magenta
Write-Host "  1) Inspecte : git status / git diff"
Write-Host ("  2) Commit :  git add {0} ; git commit -m ""Unpack solution {1}""" -f $UnpackFolder, $SolutionName)
Write-Host "  3) Push vers ton repo / pipeline CI"

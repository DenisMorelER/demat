
[CmdletBinding()]
param(
    # Nom interne de la solution (Unique Name)
    [string]$SolutionName = "Dematerialisation_des_Processus",

    # Dossier source (unpack) dans la branche 'test'
    [string]$SourceFolder = ".\src\solution",

    # Dossier de sortie pour les ZIP
    [string]$Output = ".\tmp",

    # URL de l'environnement cible (Dataverse, sans slash final) ex: https://orgTEST.crm4.dynamics.com
    [Parameter(Mandatory = $true)]
    [string]$TargetEnvironmentUrl,

    # Auth Service Principal (Application User)
    [Parameter(Mandatory = $true)]
    [string]$TenantId,
    [Parameter(Mandatory = $true)]
    [string]$ClientId,
    [Parameter(Mandatory = $true)]
    [string]$ClientSecret,

    # Fichier settings (optionnel) pour connection references & environment variables
    [Parameter(Mandatory = $false)]
    [string]$SettingsFile = ".\pipelines\settings\Target.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host ("=== Déploiement depuis BRANCHE 'test' vers ENV cible - Solution '{0}' ===" -f $SolutionName) -ForegroundColor Cyan

# 0) Vérif 'pac'
if (-not (Get-Command pac -ErrorAction SilentlyContinue)) {
    throw "Power Platform CLI 'pac' introuvable. Installe-le (https://aka.ms/pac) ou ajoute son dossier au PATH."
}
Write-Host ("pac OK : {0}" -f (pac --version)) -ForegroundColor DarkGreen

# 1) Vérifier le dossier source
if (-not (Test-Path $SourceFolder)) {
    throw ("Le dossier source '{0}' est introuvable. Assure-toi que la branche 'test' contient l’unpack." -f $SourceFolder)
}

# 2) Préparer le dossier tmp
New-Item -ItemType Directory -Force -Path $Output | Out-Null
$absOutDir  = (Resolve-Path $Output).Path
$zipManaged = Join-Path $absOutDir ("{0}_managed.zip" -f $SolutionName)

# 3) PACK en Managed depuis src/solution
Write-Host ("Pack (managed) depuis '{0}' -> {1}" -f $SourceFolder, $zipManaged) -ForegroundColor Cyan
# Doc : pac solution pack --zipfile --folder --packagetype Managed
pac solution pack --zipfile "$zipManaged" --folder "$SourceFolder" --packagetype Managed

if (-not (Test-Path "$zipManaged")) {
    throw ("Pack managed échoué: {0} introuvable." -f $zipManaged)
}
Write-Host ("ZIP managed prêt : {0}" -f $zipManaged) -ForegroundColor DarkGreen

# 4) Auth vers l'ENV cible (Service Principal)
$TargetEnvironmentUrl = $TargetEnvironmentUrl.TrimEnd('/')
Write-Host ("Auth SPN vers ENV cible: {0}" -f $TargetEnvironmentUrl) -ForegroundColor Yellow
pac auth create --url $TargetEnvironmentUrl --tenant $TenantId --applicationId $ClientId --clientSecret $ClientSecret
pac org select -env $TargetEnvironmentUrl

Write-Host "Organisation sélectionnée :" -ForegroundColor Cyan
pac org who

# 5) Import du managed (+ publish + settings si fournis)
Write-Host ("Import managed vers ENV cible: {0}" -f $zipManaged) -ForegroundColor Cyan
if ($SettingsFile -and (Test-Path $SettingsFile)) {
    Write-Host ("Settings détecté: {0}" -f $SettingsFile) -ForegroundColor DarkYellow
    # Doc : pac solution import --path --publish-changes --settings-file
    pac solution import --path "$zipManaged" --publish-changes --settings-file "$SettingsFile"
} else {
    pac solution import --path "$zipManaged" --publish-changes
}

Write-Host "✅ Déploiement terminé." -ForegroundColor Green
Write-Host ("Artefact: {0}" -f $zipManaged)

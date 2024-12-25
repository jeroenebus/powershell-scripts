<#
.Synopsis
    Script to move file to another location and move the file to a processed folder
.DESCRIPTION
    The script will move all files to another folder, afterwards it will be moved to processed and all actions are being logged.
    All the files in the processed folder will be cleaned when they are older then 7 days.
.EXAMPLE
    Replace variables with sources and destinations of your choice
.NOTES
    Filename: MoveToFolder.ps1
    Author: Jeroen Ebus (https://manage-the.cloud) 
    Modified date: 2024-12-18
    Version 1.0 - Release notes/details
#>

# Define variables
$SourceDir = "C:\TEMP\IMPORT"  # Directory on Server X containing files to upload
$ProcessedDir = "C:\TEMP\IMPORT\Processed"  # Directory where processed files will be moved
$DestinationDir = "\\127.0.0.1\EXPORT"  # Destination directory on Server Y
$LogFile = "C:\TEMP\IMPORT\Logs\LogFile.log"  # Log file to record actions
$CleanupThresholdDays = 7  # Number of days to retain files in the ProcessedDir

# Ensure the directories exist
if (!(Test-Path -Path $ProcessedDir)) {
    New-Item -ItemType Directory -Path $ProcessedDir -Force
}

# Check if source directory exists
if (!(Test-Path -Path $SourceDir)) {
    Write-Output "[$(Get-Date)] ERROR: Source directory does not exist: $SourceDir" | Out-File -FilePath $LogFile -Append
    Exit 1
}

# Get list of files in the source directory
$Files = Get-ChildItem -Path $SourceDir -File

if ($Files.Count -eq 0) {
    Write-Output "[$(Get-Date)] INFO: No files to process in $SourceDir" | Out-File -FilePath $LogFile -Append
}
else {
    foreach ($File in $Files) {
        try {
            # Define source and destination file paths
            $SourceFile = $File.FullName
            $DestinationFile = Join-Path -Path $DestinationDir -ChildPath $File.Name

            # Copy the file to the destination
            Copy-Item -Path $SourceFile -Destination $DestinationFile -Force

            if (Test-Path -Path $DestinationFile) {
                # Move the file to the processed directory
                $ProcessedFile = Join-Path -Path $ProcessedDir -ChildPath $File.Name
                Move-Item -Path $SourceFile -Destination $ProcessedFile -Force
                Write-Output "[$(Get-Date)] SUCCESS: Uploaded and moved $($File.Name)" | Out-File -FilePath $LogFile -Append
            }
            else {
                Write-Output "[$(Get-Date)] ERROR: Failed to upload $($File.Name)" | Out-File -FilePath $LogFile -Append
            }
        }
        catch {
            Write-Output "[$(Get-Date)] ERROR: Exception occurred for $($File.Name) - $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append
        }
    }
}

# Cleanup processed files older than the defined threshold
try {
    $OldFiles = Get-ChildItem -Path $ProcessedDir -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$CleanupThresholdDays) }

    foreach ($OldFile in $OldFiles) {
        Remove-Item -Path $OldFile.FullName -Force
        Write-Output "[$(Get-Date)] CLEANUP: Deleted old file $($OldFile.Name)" | Out-File -FilePath $LogFile -Append
    }

    Write-Output "[$(Get-Date)] CLEANUP: Completed cleanup of files older than $CleanupThresholdDays days in $ProcessedDir" | Out-File -FilePath $LogFile -Append
}
catch {
    Write-Output "[$(Get-Date)] ERROR: Exception during cleanup - $($_.Exception.Message)" | Out-File -FilePath $LogFile -Append
}
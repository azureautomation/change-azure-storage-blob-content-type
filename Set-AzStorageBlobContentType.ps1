<#
.SYNOPSIS
Changing content type of storage account blobs.

.DESCRIPTION
Function which is meant to interrate over all blobs stored in the container withing the storage account and change their content type property based on the file extension.

.PARAMETER StorageAccount
Name of the Storage Account.

.PARAMETER Container
Name of the Container within the Storage Account.

.EXAMPLE
Set-AzStorageBlobContentType -StorageAccount nemanjajovicstorage -Container application-conf
#>
Function Set-AzStorageBlobContentType {
    [cmdletbinding()]
    param (
        # Name of the Storage Account
        [Parameter(Mandatory = $true,
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$StorageAccount,
        # Name of the Container within the Storage Account
        [Parameter(Mandatory = $true,
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$Container
    )
    process {
        $ErrorActionPreference = 'Stop'
        $CheckStorageAccount = (Get-AzStorageAccount | Where-Object { $_.StorageAccountName -eq $StorageAccount })
        if (-not $CheckStorageAccount) {
            Write-Error "Cannot find the storage account with the name $StorageAccount. Terminatting." -ErrorAction Stop
        }
        try {
            $StorageKey = (Get-AzStorageAccountKey -StorageAccountName $StorageAccount -ResourceGroupName $CheckStorageAccount.ResourceGroupName)[0].value
            $StorageContext = (New-AzStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $StorageKey)
            $FindContainer = (Get-AzStorageContainer -Context $StorageContext -Container $Container)
            $BlobList = (Get-AzStorageBlob -Context $StorageContext -Container $FindContainer.Name)
            foreach ($Blob in $BlobList) {
                $Extension = [io.path]::GetExtension($Blob.Name)
                switch ($Extension) {
                    '.json' { $ContentType = 'application/json' }
                    '.js' { $ContentType = 'application/javascript' }
                    '.svg' { $ContentType = 'image/svg+xml' }
                    '.png' { $ContentType = 'image/png' }
                    '.jpg' { $ContentType = 'image/jpg' }
                    '.css' { $ContentType = 'text/css' }
                    '.htm' { $ContentType = 'text/html' }
                    '.html' { $ContentType = 'text/html' }
                    '.xml' { $ContentType = 'text/xml' }
                    '.pdf' { $ContentType = 'application/pdf' }
                    Default { $ContentType = 'application/octet-stream' }
                }
                $Blob.ICloudBlob.properties.ContentType = $ContentType
                $Blob.ICloudBlob.SetProperties()
            }
        }
        catch {
            Write-Error "$_"
        }

    }
}
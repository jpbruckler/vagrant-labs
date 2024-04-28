$localPath = "C:\vagrant"
Import-Certificate -CertStoreLocation 'Cert:\LocalMachine\Root' -FilePath "$localPath\cert.der"
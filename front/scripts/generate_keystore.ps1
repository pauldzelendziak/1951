param(
  [Parameter(Mandatory = $true)]
  [string]$AppId
)

# This script mirrors your Bash script 1:1 in parameters and outputs:
# - keystore: "<AppId>.keystore"
# - certificate: "<AppId>.certificate.pem"
# - alias, storepass, keypass: <AppId>
# - validity: 9999
# - keyalg: RSA
# - dname: "CN=<AppId>, OU=ID, O=IBM, L=, S=, C="

$ErrorActionPreference = "Stop"

# Generate keystore
& keytool -genkey -noprompt `
  -alias $AppId `
  -dname "CN=$AppId, OU=ID, O=IBM, L=, S=, C=" `
  -keystore "$AppId.keystore" `
  -storepass $AppId `
  -keypass $AppId `
  -validity 9999 `
  -keyalg RSA

if ($LASTEXITCODE -ne 0) { throw "keytool -genkey failed with exit code $LASTEXITCODE" }

# Export certificate (PEM)
& keytool -export -rfc `
  -storepass $AppId `
  -alias $AppId `
  -file "$AppId.certificate.pem" `
  -keystore "$AppId.keystore"

if ($LASTEXITCODE -ne 0) { throw "keytool -export failed with exit code $LASTEXITCODE" }

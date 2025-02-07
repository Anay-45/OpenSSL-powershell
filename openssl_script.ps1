#getting details from command line arguments

param(
    [string]$jsonString = '{"email": "anaybhatkar35@gmail.com", "country": "IN", "state": "maharashtra","locality":"mumbai","orgUnit":"IT","org":"IDFC FIRST BANK","names":"test.idfcbank.com,testuat.idfcbank.com","ritm":"RITM010110"}'
)

$openssl_path = "C:\PROGRA~1\OpenSSL-Win64\bin\openssl.exe";

$jsonObject = ConvertFrom-Json $jsonString;

$email = $jsonObject.email;
$country = $jsonObject.country;
$state = $jsonObject.state;
$locality = $jsonObject.locality;
$orgUnit = $jsonObject.orgUnit;
$org = $jsonObject.org;
$name = $jsonObject.names;
$ritm = $jsonObject.ritm;

$names = $name.Split(",");

#set common_name

$subject_common_name = $names[0];

#Getting san names

$san_names = "";

for ($i = 1; $i -le $names.Length; $i++) {
    $san_name = $names[$i - 1];
    $san_names += "DNS.$i = $san_name`n"  
}

#Path to store the files
$path = 'D:\CSRs\'
if (-not (Test-Path -Path $path)) {
    New-Item -Path $path -ItemType Directory | Out-Null
}

$configFile = @"
# -------------- BEGIN CONFIG --------------
[ req ]
default_bits = 2048
default_keyfile = $subject_common_name.key
distinguished_name = req_distinguished_name
encrypt_key = no
prompt = no
string_mask = nombstr
req_extensions = v3_req
[ req_distinguished_name ]
C  = $country
ST = $state
L  = $locality
O  = $org
OU = $orgUnit
CN = $subject_common_name
emailAddress = $email
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName= @alt_names
[alt_names]
$san_names
# -------------- END CONFIG --------------
"@

if (-not (Test-Path -Path $path\$ritm)) {
    New-Item -Path $path -Name $ritm -ItemType Directory | Out-Null
}

$config_file_path = $path + "csrconf.cfg"; 
$configFile | Out-File -FilePath $config_file_path -Force -Encoding ascii


#Declare Directories
$files = $path + $ritm + "_" + $subject_common_name;
$CSR = $files + "\" + $subject_common_name + ".csr.txt";
$private_key1 = $files + "\" + $subject_common_name + ".key.txt";
$private_key2 = $files + "\" + $subject_common_name + "_WP.key.txt";
$zip_file_path = $path + $ritm + "_" + $subject_common_name + ".zip";

$command1 = $openssl_path + " req -new -nodes -out " + $CSR + " -keyout " + $private_key1 + " -config csrconf.cfg";
$command2 = $openssl_path + " rsa -in " + $private_key1 + " -out " + $private_key2 + " -traditional";

Invoke-Expression -Command $command1
Invoke-Expression -Command $command2
Invoke-Expression -Command "clear"


#Compress file

if (Test-Path -Path $path\$subject_common_name.zip) {
    #Compress-Archive -Path $files -DestinationPath $path$subject_common_name.zip
    Remove-Item $zip_file_path -Recurse -Force
}


$fileContent = Get-Content -Path $CSR -Raw

# Create an object with a key-value pair
$jsonObject = @{
    "CSR" = $fileContent
}

# Convert the object to JSON
$jsonContent = $jsonObject | ConvertTo-Json

$jsonContent | Write-Output

Remove-Item $files -Recurse -Force




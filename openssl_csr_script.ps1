param(
    [string]$jsonString = '{"email": "anaybhatkar35@gmail.com", "country": "IN", "state": "maharashtra","locality":"mumbai","orgUnit":"IT","org":"IDFC FIRST BANK","names":"snow.idfcbank.com,snowuat.idfcbank.com","ritm":"RITM010190"}'
)

#Creating config files and path to store all files
$create_config_file = {
    param($path, $jsonObject)
    $jsonObject = ConvertFrom-Json $jsonString;

    $email = $jsonObject.email;
    $country = $jsonObject.country;
    $state = $jsonObject.state;
    $locality = $jsonObject.locality;
    $orgUnit = $jsonObject.orgUnit;
    $org = $jsonObject.org;
    $name = $jsonObject.names;
    $ritm = $jsonObject.ritm;

    $result = & $get_names $name;
    $subject_common_name = $result['subject_common_name'];
    $san_names = $result['san_names'];

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

    $folder = $ritm + "_" + $subject_common_name
    if (-not (Test-Path -Path $path\$folder)) {
        New-Item -Path $path -Name $folder -ItemType Directory | Out-Null
    }

    $config_file_path = $path + "csrconf.cfg"; 
    $configFile | Out-File -FilePath $config_file_path -Force -Encoding ascii

    return @{
        config_file_path    = $config_file_path
        subject_common_name = $subject_common_name
        files               = $path + $folder
    }
}

$get_names = {
    param (
        $name
    )
    $names = $name.Split(",");
    $subject_common_name = $names[0];
    #Getting san names
    $san_names = "";

    for ($i = 1; $i -le $names.Length; $i++) {
        $san_name = $names[$i - 1];
        $san_names += "DNS.$i = $san_name`n"  
    }

    return @{
        subject_common_name = $subject_common_name
        san_names           = $san_names
    }
}

$create_csr_private_key = {
    param ($path, $jsonObject, $openssl_path)

    $result1 = &$create_config_file "D:\CSRs\" $jsonObject;

    $subject_common_name = $result1['subject_common_name'];
    $files = $result1['files'];
    $config_file_path = $result1['config_file_path'];
    $CSR = $files + "\" + $subject_common_name + ".csr.txt";
    $private_key1 = $files + "\" + $subject_common_name + ".key.txt";
    $private_key2 = $files + "\" + $subject_common_name + "_WP.key.txt";
    $zip_file_path = $path + $subject_common_name + ".zip";

    $command1 = $openssl_path + " req -new -nodes -out " + $CSR + " -keyout " + $private_key1 + " -config " + $config_file_path;
    $command2 = $openssl_path + " rsa -in " + $private_key1 + " -out " + $private_key2 + " -traditional";

    Invoke-Expression -Command $command1
    Invoke-Expression -Command $command2
    Invoke-Expression -Command "clear"

    if (Test-Path -Path $zip_file_path) {
        #Compress-Archive -Path $files -DestinationPath $path$subject_common_name.zip
        Remove-Item $zip_file_path -Recurse -Force
    }
    Compress-Archive -Path $files -DestinationPath $zip_file_path;

    $content = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($CSR))
    $jsonstring = @{
        file_name = [System.IO.Path]::GetFileName($CSR)
        content = $content
    } | ConvertTo-Json -Depth 10

    Remove-Item $files -Recurse -Force
    return @{
        zip_file_path = $zip_file_path
        CSR           = $CSR
        jsonstring = $jsonstring
    }
}

#$result = &$get_names "test.idfcbank.com,testuat.idfcbank.com,tesrr.idfcbank.com";

$openssl_path = "C:\PROGRA~1\OpenSSL-Win64\bin\openssl.exe";

$result1 = &$create_csr_private_key "D:\CSRs\" $jsonObject $openssl_path

Write-Host $result1['jsonstring']
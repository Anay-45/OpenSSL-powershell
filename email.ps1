#rrua chum gdmy cldy

$SMTP = "smtp.gmail.com"
$From = "anaybhatkar35@gmail.com"
$To = "anaybhatkar547@gmail.com"
$Subject = "Test Subject"
$Body = "This is a test message"
$Email = New-Object Net.Mail.SmtpClient($SMTP, 587)
$Email.EnableSsl = $true
$Email.Credentials = New-Object System.Net.NetworkCredential("anaybhatkar35@gmail.com", "rrua chum gdmy cldy");
$Email.Send($From, $To, $Subject, $Body)
Param([switch]$ignoreduplicates,[switch]$whatif,[switch]$hotp,[switch]$slot2,[switch]$totp)
<#
---YubiKey Batch Configuration Tool 0.10---
AUTHOR
    Chris Streeks

DESCRIPTION
    Allows you to program several YubiKeys in sequence with YubiOTP seeds (Default), 6 digit HOTP seeds, or 6 digit TOTP seeds.
 #>

 
#
## USER VARIABLES
#
    #You may need to modify this path if your installation path is different.
    $pathToYKman = 'C:\Program Files\Yubico\YubiKey Manager\ykman.exe'

#
## FUNCTIONS 
#

#Generates the CLI based UI the user sees as they program more YubiKeys in a given session
function Redraw-GUI {
    $numProgrammedYubiKeys  = $arrProgrammedYubiKeys.count
    
    #Calculating the number of trays configured thus far
    $numTrays = [Math]::Truncate($numProgrammedYubiKeys/50)


    clear-host 
    Write-host "Batch YubiKey Configuration Tool"
    if ($boolsetaccesscode -eq $True){
        write-host "Access Code: Set to Serial || YubiKeys Configured: $numProgrammedYubiKeys || Number of Trays Configured: $numTrays" 
    }
    else{
        write-host "Access Code: None || YubiKeys Configured: $numProgrammedYubiKeys || Number of Trays Configured: $numTrays"
    }

    write-host "`nCurrent Tray:"
    write-host $numKeysInGUI_Tray

    $numKeysInGUI_Tray = $numProgrammedYubiKeys % 50
    $TrayRows=0 #We use this variable to add extra blank rows, if needed, after the loop

    #We loop over the tray sized modulus (50 keys) of the total number of keys and for every row of 10 we represent how many keys are in that row using this switch condition
    while ($numKeysInGUI_Tray -gt 0){
        Switch ($numKeysInGUI_Tray) { 
            0 {write-host "|-||-||-||-||-||-||-||-||-||-|"; break}
            1 {write-host "|Y||-||-||-||-||-||-||-||-||-|"; break}
            2 {write-host "|Y||Y||-||-||-||-||-||-||-||-|"; break}
            3 {write-host "|Y||Y||Y||-||-||-||-||-||-||-|"; break}
            4 {write-host "|Y||Y||Y||Y||-||-||-||-||-||-|"; break}
            5 {write-host "|Y||Y||Y||Y||Y||-||-||-||-||-|"; break}
            6 {write-host "|Y||Y||Y||Y||Y||Y||-||-||-||-|"; break}
            7 {write-host "|Y||Y||Y||Y||Y||Y||Y||-||-||-|"; break}
            8 {write-host "|Y||Y||Y||Y||Y||Y||Y||Y||-||-|"; break}
            9 {write-host "|Y||Y||Y||Y||Y||Y||Y||Y||Y||-|"; break}
            10 {write-host "|Y||Y||Y||Y||Y||Y||Y||Y||Y||Y|"; break}
            default {"|Y||Y||Y||Y||Y||Y||Y||Y||Y||Y|"; break}
        }
        $numKeysInGUI_Tray = $numKeysInGUI_Tray - 10
        $TrayRows++ #We track how many rows we iterated through so we know how many empty rows to generate
    }
    #Adds the empty tray rows to the GUI
    for ($i=$TrayRows; $i -lt 5; $i++){
        write-host "|-||-||-||-||-||-||-||-||-||-|"
    }

    if ($arrProgrammedYubiKeys.count -gt 0){
        $mostrecentyk = $arrProgrammedYubiKeys[($arrProgrammedYubiKeys.Count)-1]
        write-host "`nStatus:"
        write-host "$devicetype (#$mostrecentyk) programmed successfully."
        write-host "Please insert next YubiKey..."
    }

}



function Program-YubiKey{

    #First check to see if we've already programmed this YubiKey this session by grabbing info about this key
    $arg1 = 'info'
    $ykmanoutput = & $pathtoykman $arg1 2>$null
   
    #Parsing out both the serial number and the YubiKey series type from the ykman output.
    #We put this in a condition just to avoid situations where the user pulled the YubiKey at just the right time
    #and the script tries to perform operations despite there being nothing to compare
    if ($null -ne $ykmanoutput){
        $serialnum = $ykmanoutput | select-string -Pattern "Serial Number: "
        $serialnum = $serialnum.tostring().Split(' ')[-1]
        $devicetype = $ykmanoutput | select-string -Pattern "Device Type: "
        $devicetype = $devicetype.tostring().Split(':')[-1].trim()
    }
 
    #If this array has something in it, and the current YubiKey's serial number is in that array AND it's not the YubiKey we JUST programmed AND the ignore dupes flag isn't set, alert the user as we have discovered a dupe
    if (($arrProgrammedYubiKeys.count -gt 0) -and ($arrProgrammedYubiKeys.contains($serialnum)) -and ($arrProgrammedYubiKeys[($arrProgrammedYubiKeys.Count)-1] -ne $serialnum) -and ($ignoreduplicates.IsPresent -ne $true)){
        read-host "`nDuplicate Warning:`nThis YubiKey (#$serialnum) has already been configured during this session.`nPlease insert the next YubiKey, then press [Enter] to continue"
    }
    #If this array has something in it, and the current YubiKey's serial number is in that array and it IS the YubiKey we just programmed, just pause for a sec before returning back to the script that called the function
    elseif (($arrProgrammedYubiKeys.count -gt 0) -and ($arrProgrammedYubiKeys.contains($serialnum)) -and ($arrProgrammedYubiKeys[($arrProgrammedYubiKeys.Count)-1] -eq $serialnum)){
        Start-Sleep -s .5 
    }
    #This is a new Yubikey to us (or we were told to ignore dupes), so let's work with it
    else{
  
        #If the user passed a "WhatIf" flag and the HOTP flag is present, we will avoid programming the Yubikey and generate some dummy data to write to the CSV
        if($whatif.IsPresent -and $hotp.IsPresent){
            $ykmanoutput = "serialnumberwhatif,722E6953707804F682654C69726C328636C9085D"
        }     

        #If the user passed a "WhatIf" flag and the TOTP flag is present, we will avoid programming the YubiKey and generate some dummy date to write to the CSV
        elseif($whatif.IsPresent -and $totp.IsPresent){
            $ykmanoutput = "$issuername,serialnumberwhatif,722E6953707804F682654C69726C328636C9085D,30,YubiKey,YK5NFC"
        }

        #If the user passed a "WhatIf flag, we will avoid programming the YubiKey and generate some dummy data to write to the CSV
        elseif($whatif.IsPresent){
            $timestamp = get-date -format "yyyy-M-ddThh:mm:ss"
            $ykmanoutput = "0000001,ccccccWHATIF,000000000001,00000000000000000000000000000001,000000000000,$timestamp,"
        }

        elseif($totp.IsPresent){

            #Generating a Base 32 random string. 
            #Crypto copied from https://support.yubico.com/hc/en-us/articles/360015668699-Generating-Base32-string-examples   
            $RNG = [Security.Cryptography.RNGCryptoServiceProvider]::Create()
            [Byte[]]$x=1
            for($secretkey=''; $secretkey.length -lt 64){$RNG.GetBytes($x); if([char]$x[0] -clike '[2-7A-Z]'){$secretkey+=[char]$x[0]}}
          
                
            #YKman commands for adding TOTP to the OATH module of the YubiKey. User will need to use Yubico Authenticator to use this credential
            $arg1 = 'oath' #Required part of ykman command
            $arg2 = 'add' #Adding a new OATH credential
            $arg3 = '-i' #Required part of ykman command
            $arg4 = '-f' #Force the command, avoid the confirmation prompt
            $arg5 = $IssuerName #IssuerName value as defined by the administrator. Etc "Azure"
            $arg6 = $secretkey #Cryptographic seed for the TOTP

            #Configuring the YubiKey with TOTP values to the OATH module
            $ykmanoutput = & $pathtoykman $arg1 $arg2 $arg3 $arg4 $arg5 
            }
        
        elseif($hotp.IsPresent){

            #Generating a Base 32 random string.    
            #Crypto copied from https://support.yubico.com/hc/en-us/articles/360015668699-Generating-Base32-string-examples   
            $RNG = [Security.Cryptography.RNGCryptoServiceProvider]::Create()
            [Byte[]]$x=1
            for($secretkey=''; $secretkey.length -lt 64){$RNG.GetBytes($x); if([char]$x[0] -clike '[2-7A-Z]'){$secretkey+=[char]$x[0]}}
        
            
            #YKman commands for HOTP 
            $arg1 = 'otp' #Required part of ykman command
            $arg2 = 'hotp' #Required part of ykman command
            $arg3 = '-d6' #YubiKey will emit 6 digit HOTPs
            $arg4 = '-f' #Force the command, avoid the confirmation prompt
            $arg5 = $secretkey #Seed
            $arg6 = $SlotToProgram #Configure all of this in a particular slot

            #Configuring the YubiKey with HOTP values
            $ykmanoutput = & $pathtoykman $arg1 $arg2 $arg3 $arg4 $arg5 $arg6
        }

       
        else{
            #YKman commands for YubiOTP
            $arg1 = 'otp' #Required part of ykman command
            $arg2 = 'yubiotp' #Required part of ykman command
            $arg3 = '-S' #Use the serial number of the YubiKey as the public ID
            $arg4 = '-g' #Generate a random private ID (6 bytes)
            $arg5 = '-G' #Generate a random seed key (16 bytes of hex)
            $arg6 = '-f' #Force the command, avoid the confirmation prompt
            $arg7 = $SlotToProgram #Configure all of this in a particular slot

            #Configuring the YubiKey with OTP values
            $ykmanoutput = & $pathtoykman $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7
        }

        #Being extra cautious...if the serial number is null for any reason, don't bother iterating the array of programmed YubiKeys.
        if ($null -ne $serialnum){
            #Add this serial number to our array so we can track which YubiKeys have been programmed this session
            $arrProgrammedYubiKeys.Add($serialnum) > $null


            #CSV files for YubiOTP, TOTP and HOTP differ, so if a particular flag is set, we'll handle the CSV output a bit differently.
            #Handling HOTP CSV
            if($hotp.IsPresent){
                "$serialnum,$secretkey"| out-file -filepath $pathToCSV -Append
                
                #If the user also wants an access code with HOTP, we write it to the separate file they've defined.
                if ($boolsetaccesscode -eq $True){
                    "$serialnum,$accesscode"| out-file -filepath $pathToHOTPAccessCodeCSV -Append
                }
            }
            #Handling TOTP CSV
            elseif ($totp.IsPresent){
                "$issuername,$serialnum,$secretkey,30,YubiKey,YK5NFC"| out-file -filepath $pathToCSV -Append
            }
            #Handling YubiOTP CSV
            else{
                #Taking the output of what we just wrote to the YubiKey and splitting it out into variables.
                $a,$currentpublicid,$b,$currentprivateID,$c,$currentsecret = $ykmanoutput.split(':')
                
                #Padding the serial number with 0s to align with access code requirements
                $accesscode = ([string]$serialnum).PadLeft(12,'0')
    
                #Write to the CSV file using the YubiOTP CSV format, writing the access code to the file if set to configure the YubiKey with one.
                $timestamp = get-date -format "yyyy-M-ddThh:mm:ss"
    
                if ($boolsetaccesscode -eq $True){
                    "$serialnum,$currentpublicid,$currentprivateid,$currentsecret,$accesscode,$timestamp,"| out-file -filepath $pathToCSV -Append
                }
                else{
                    "$serialnum,$currentpublicid,$currentprivateid,$currentsecret,000000000000,$timestamp,"| out-file -filepath $pathToCSV -Append
                }
            }
    
    
            #Setting an access code for YubiOTP and HOTP if this was defined during initial configuration and the WhatIf parameter isn't enabled
            if (($boolsetaccesscode -eq $true) -and ($whatif.IsPresent -eq $false) -and !($totp.IsPresent)){
                $arg1 = "otp"
                $arg2 = "settings"
                $arg3 = "-A"
                $arg4 = $accesscode
                $arg5 = $SlotToProgram
            
                $ykmanoutput = & $pathtoykman $arg1 $arg2 $arg3 $arg4 $arg5
            }
    
            #Calling the GUI function so the user sees this update
            Redraw-GUI
        }
    }
}

###
### CORE SCRIPT
###

clear-host;

#Before we get started, if the user has started this script with both TOTP and HOTP, just exit
if($totp.IsPresent -and $hotp.IsPresent){
    Read-Host "You've started this script with both the -TOTP and -HOTP flags. Only one of these flags can be enabled at once.`nPress [Enter] to exit"
    exit
}


##Test to ensure the ykman executable exists
if (!(test-path $pathtoykman)){
    Write-host "ERROR: ykman.exe does not exist at the defined path: $pathtoykman" 
    read-host "- Please make sure the official YubiKey Manager tool is installed.`n  Visit www.yubico.com for download links. `n`n- If you did install YubiKey Manager but not to the path defined above,`n  please edit the pathToYkman variable in the 'User Variables' section of this .ps1 script. `nPress [Enter] to exit..." -ForegroundColor Red
    exit;
}

#Setting the slot we will be programming
if ($slot2.IsPresent){$SlotToProgram = '2'}
else{$SlotToProgram = '1'}

Write-host "  .-------.     "
Write-host "  |   O   |     "
Write-host "  |       |     "
Write-host "  |  ...  |   YubiKey Batch Configuration Tool"
Write-host "  | .   . |                   By Chris Streeks"
Write-host "  |  ...  |     ,--------------.____."
Write-host "  |       |     |      ...     |    |"
Write-host "  |_______|     | O   .   .    |    |"
write-host "   |     |      |      ...     |____|"
write-host "   |_____|       --------------"
write-host "-----------------------------------------------"
write-host "1.) Seed File Settings"
write-host "We need to define a path to a CSV file for storing all seed file data from this batch programming session."
read-host "Press [Enter] to select an output path for the OTP seed values (.CSV)"

#Something to hold our serial numbers in. Powershell arrays are immutable so I'm using a .NET ArrayList instead.
$arrProgrammedYubiKeys = New-Object System.Collections.ArrayList

## Using the Windows GUI to attain the CSV file path from the user
Add-Type -AssemblyName System.Windows.Forms
$pathToCSV = New-Object System.Windows.Forms.SaveFileDialog
$pathToCSV.Filter = "CSV Files (*.csv)|*.csv|Text Files (*.txt)|*.txt|Excel Worksheet (*.xls)|*.xls|All Files (*.*)|*.*"
$pathToCSV.SupportMultiDottedExtensions = $true;

if($pathToCSV.ShowDialog() -eq 'Ok'){
    $pathToCSV = $($pathToCSV.filename)
    New-Item -ItemType "file" -Path $pathToCSV -Force | out-null

    Write-host "OK, this script will save your CSV file to:`n$pathToCSV"
}
else{
    exit;
}
## Quick logic to see if user wants to set an access code during programming. Only applicable for YubiOTP and HOTP.
if(!($totp.IsPresent)){
    write-host "`n2.) Access Code Settings"
    write-host "To prevent users from manipulating the YubiKey and adding their own OTP configuration,`nan administrative access code equal to the serial number of the YubiKey can be set."
    $Readhost = Read-Host "`nWould you like to set an access code? [Y/N]"
    Switch ($ReadHost) 
    { 
        Y {Write-host "OK, an access code will be set.";$boolsetaccesscode=$true}
        Yes {Write-host "OK, an access code will be set.";$boolsetaccesscode=$true}  
        N {Write-Host "OK, an access code will not be set.";$boolsetaccesscode=$false} 
        No {Write-Host "OK, an access code will not be set.";$boolsetaccesscode=$false}
        Default {Write-Host "Hmm...didn't quite understand that. Defaulting to 'No access code configuration'"; $boolsetaccesscode=$false} 
    } 
}
if($hotp.IsPresent){
    write-host "2a.) As you are programming HOTP seeds, these access codes must be stored in a separate file alongside their associated YubiKey serial numbers."
    read-host "Press [Enter] to select an output path for the HOTP Access codes. (.CSV)"

    ## Using the Windows GUI to attain the CSV file path for access codes from the user
    Add-Type -AssemblyName System.Windows.Forms
    $pathToHOTPAccessCodeCSV = New-Object System.Windows.Forms.SaveFileDialog
    $pathToHOTPAccessCodeCSV.Filter = "CSV Files (*.csv)|*.csv|Text Files (*.txt)|*.txt|Excel Worksheet (*.xls)|*.xls|All Files (*.*)|*.*"
    $pathToHOTPAccessCodeCSV.SupportMultiDottedExtensions = $true;

    if($pathToHOTPAccessCodeCSV.ShowDialog() -eq 'Ok'){
        $pathToHOTPAccessCodeCSV = $($pathToHOTPAccessCodeCSV.filename)
        New-Item -ItemType "file" -Path $pathToHOTPAccessCodeCSV -Force | out-null

        Write-host "OK, this script will save your CSV file for access codes to:`n$pathToHOTPAccessCodeCSV"
    }
    else{
        exit;
    }
    
}
##Specific to TOTP, we need to get an Issuer name from the admin.
elseif($totp.IsPresent){
    write-host "2a.) As you are programming TOTP seeds, we need to define a issuer name.`nThis label lets the user know who the TOTP is for. (An example might be 'Azure AD')"
    $IssuerName = read-host "Please enter an issuer name"
    if ($IssuerName = ""){
        Write-Host "No Issuer was defined, defaulting to 'UndefinedIssuer'"
        $IssuerName = "UndefinedIssuer"
    }
}

write-host "`n# Step 3: Batch Programming"
if ($ignoreduplicates.IsPresent){write-host "- 'Ignore Duplicates' mode enabled: Script will not alert on YubiKeys that have already been configured this session "}
if ($whatif.IsPresent){write-host "- 'WhatIf' mode enabled: Dummy data will be written to the CSV file and YubiKeys will not be configured."}
if ($hotp.IsPresent){write-host "- 'HOTP' mode enabled: HOTP seeds will be written to the YubiKey."}
if ($totp.IsPresent){write-host "- 'TOTP' mode enabled: TOTP seeds will be written to the YubiKey's OATH module."}
if ($slot2.IsPresent -and !($totp.IsPresent)){write-host "- 'Slot 2' mode enabled: YubiKeys will be configured with YubiOTP/HOTP seeds in their second slot."}
   
read-host "`nPlease insert the first YubiKey and press [Enter] to begin"
while($true){
    $YubiKeyWasFound = $false
    $arg1 = "info"

    while ($YubiKeyWasFound -eq $false)
    { 
        #Triggering the command 'ykman.exe info'. If it returns without an error code (return 0) we know there's a YubiKey inserted.
        & $pathtoykman $arg1 2> $null | out-null
        if ($LastExitCode -eq 0){ 
            $YubiKeyWasFound = $true

            #We found a YubiKey, so let's head to the Program-YubiKey function for next steps
            Program-YubiKey
        }
        else{
            #No YubiKey found! To avoid having this process go too wild, let's sleep for a bit before looking for a YubiKey again
            Start-Sleep -s .5
        }
    }
}

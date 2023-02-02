 <h1 align="center">PS Batch YubiKey Config</h1>


**PS Batch YubiKey Config** is a YubiKey batch configuration tool for the YubiKey Manager, written in Powershell. 


* Quickly program entire *trays* worth of YubiKeys with **YubiOTP**, **HOTP** or **TOTP** seeds
* Script [exports a well configured CSV file full of seed values](Images/seed_file.PNG) for easy import into Okta/Duo/Azure/etc.
* Script is completely **offline** and relies on **no dependancies** other than Yubico's own YubiKey Manager software.
* Friendly command line UI to [shows you how many YubiKeys you've programmed](Images/batch_programming_screen.PNG) during your batch programming session
* Full support for defining an administrative **access code** for each YubiKey, preventing users from reprogramming their devices

![](/Images/main_window.PNG)
## 💻 Requirements
- Any popular operating system capable of running Powershell (Windows, Linux, macOS)
- Latest version of the [YubiKey Manager](https://www.yubico.com/products/services-software/download/yubikey-manager/) 

## 🐻 Security Notes
- As a general rule of thumb, **never** run Powershell scripts that you do not understand. 
This script is open source and the code is well documented for a reason! Please free to review my script for yourself and/or ask questions in the form of a [GitHub Issue](https://github.com/chris-streeks/PS_Batch_YubiKey_Config/issues)

- Given that you'll be generating OTP seed values for a large quantity of YubiKeys into a cleartext CSV file, it is recommended that you run this script on an offline machine, taking care to delete the CSV file once you are done uploading it. This script does **not** require network access.

- For clarity on Powershell's default script execution policies, [please review the Microsoft documentation](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-7)
.

## 📖 How to Use (YubiOTP)
1. Ensure the YubiKey Manager is installed. 
2. Launch `PS_Batch_YubiKey_Config.ps1`
3. Click Enter on the keyboard when prompted to select a location for the CSV file which will hold the OTP seeds.
4. Choose whether or not to set an access code to the YubiKeys. (If Yes, The access code will be set to the serial number of the YubiKeys.)
5. Insert the first YubiKey to program and press the [Enter] key to begin batch programming.
6. To finish programming, simply press Control + C or close the Powershell window. Throughout the session, the script will append to the CSV file that you defined.
7. Upload the CSV file to the desired platform, delete the CSV file from your machine.

## 📖 How to Use (HOTP)
1. Ensure the YubiKey Manager is installed.
2. Launch the .ps1 file with the hotp flag attached. `PS_Batch_YubiKey_Config.ps1 -hotp`
3. Click Enter on the keyboard when prompted to select a location for the CSV file which will hold the OTP seeds.
4. Choose whether or not to set an access code to the YubiKeys. The access code will be set to the serial number of the YubiKeys.
5. If you choose to set an access code, you will be additionally prompted to set a location to store those access codes.
6. Insert the first YubiKey to program and press the [Enter] key to begin batch programming.
6. To finish programming, simply press Control + C or close the Powershell window. Throughout the session, the script will append to the CSV file that you defined.
7. Upload the CSV file to the desired platform, delete the CSV file from your machine.

## 📖 How to Use (TOTP)
1. Ensure the YubiKey Manager is installed.
2. Launch the .ps1 file with the totp flag attached. `PS_Batch_YubiKey_Config.ps1 -totp`
3. Click Enter on the keyboard when prompted to select a location for the CSV file which will hold the OTP seeds.
4. Define the issuer name. As an example, if these are being set up for Microsoft Office 365, "Office 365" might be a good issuer name.
5. Insert the first YubiKey to program and press the [Enter] key to begin batch programming.
6. To finish programming, simply press Control + C or close the Powershell window. Throughout the session, the script will append to the CSV file that you defined.
7. Upload the CSV file to the desired platform, delete the CSV file from your machine.

## 📖 Microsoft Azure Additional Notes
1. After programming the YubiKeys, the CSV file will still lack your user's UPN information. Proceed accordingly.


## 🚩 Optional Flags 
**`slot2`** - YubiKeys will be programmed in their second slot rather than the default slot 1. 

**`hotp`** - YubiKeys will be programmed with HOTP seeds rather than the default YubiOTP

**`totp`** - YubiKeys will be programmed with TOTP seeds. (User must use [Yubico Authenticator](https://www.yubico.com/products/yubico-authenticator/) app to generate TOTPs!)

**`ignoreduplicates`** - Script will not check if a YubiKey has already been programmed during the session

**`whatif`** - Script will not program YubiKeys and will instead write to the defined CSV file with dummy data. 


$Version="1.4"
$CheckVersion = $null
$grouptag = $null
$selection = $null
#$workingDirectory = Get-Location | select -expand path
# Get a list of all filer volumes
$scriptPath = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Path)

##### CHECK TPM IS ENABLED
Write-Host ""
Write-Host "Checking Hardware Requirements"
$check = $true

$TPMEnabled = wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get IsEnabled_InitialValue
if("TRUE" -in $TPMEnabled.Trim()){
    Write-Host "  TPM Enabled  " -BackgroundColor Green -ForegroundColor Black
}else{
    Write-Host "  TPM Disabled. Enabled TPM in BIOS  " -BackgroundColor Red -ForegroundColor White
    $check = $false
}

##### CHECK TPM VERSION

$SpecVersionArray = (wmic /namespace:\\root\cimv2\security\microsofttpm path win32_tpm get SpecVersion)
$SpecVersionTxt = ""
foreach($SpecVersion in $SpecVersionArray){
    if($SpecVersion.Trim() -ne "SpecVersion" -and $SpecVersion.Trim() -ne ""){
        $SpecVersionTxt = $SpecVersion.Trim();
    }
}
if($SpecVersionTxt -ne "" -and $SpecVersionTxt.IndexOf('2.0') -gt -1){
    Write-Host "  $($SpecVersionTxt)  " -BackgroundColor Green -ForegroundColor Black
}else{
    Write-Host "  $($SpecVersionTxt) - Investigate if TPM can be upgraded to 2.0  " -BackgroundColor Yellow -ForegroundColor Black
	$check = $false
}

##### CHECK CPU VENDOR

$captionArray = Wmic cpu get caption
$captionTxt = ""
foreach($caption in $captionArray){
    if($caption.Trim() -ne "Caption" -and $caption.Trim() -ne ""){
        $captionTxt = $caption.Trim()
    }
}
if($captionTxt -ne ""){
    Write-Host "  $($captionTxt)  " -BackgroundColor Green -ForegroundColor Black
}else{
    Write-Host "  Caption missing  " -BackgroundColor Red -ForegroundColor White
    #$check = $false
}

##### CHECK VIRTUALIZATION IS ENABLED

#$virtualization = systeminfo
#$virtualizationTxt = $virtualization.Trim() | ? { $_ -like "*hypervisor has been detected*" }
    $_vmmExtension = $(gwmi -Class Win32_processor).VMMonitorModeExtensions
    $_vmFirmwareExtension = $(gwmi -Class Win32_processor).VirtualizationFirmwareEnabled
    $_vmHyperVPresent =  (gcim -Class Win32_ComputerSystem).HypervisorPresent

    #success if either processor supports and enabled or if hyper-v is present
    if(($_vmmExtension -and $_vmFirmwareExtension) -or $_vmHyperVPresent ) {
        Write-Host "  Virtualization is ENABLED  " -BackgroundColor Green -ForegroundColor Black
    } else {
        Write-Host "  Virtualization firmware check failed."  -BackgroundColor Red -ForegroundColor White
        Write-Host "  Enable hardware virtualization (Intel Virtualization Technology, Intel VT-x, Virtualization Extensions, or similar) in the BIOS and run the script again."  -BackgroundColor Red -ForegroundColor White
		$check = $false
    }

##### CHECK Secure BOOT and UEFI is ENABLED

$uefi = (Confirm-SecureBootUEFI)
if($uefi){
    Write-Host "  Secure Boot and UEFI is ENABLED  " -BackgroundColor Green -ForegroundColor Black
}else{
    Write-Host "  Secure Boot and UEFI is DISABLED. Enable UEFI and Secure Boot in BIOS  " -BackgroundColor Red -ForegroundColor White
    $check = $false
}

if ($check) {
    #$check 
	Write-Host "You can now proceed with the systemreset" -BackgroundColor Green -ForegroundColor Black
} else {
    #$check 
    Write-Host ""
    Write-Host "Please make sure that you change the settings in the BIOS as highlighted. Otherwise the computer will not meet the compliance policies and cannot access company resources " -BackgroundColor Magenta -ForegroundColor White
	Write-Host "You can now proceed with the systemreset, but make sure that you change the settings in the BIOS as soon as the computer reboots" -BackgroundColor Magenta -ForegroundColor White
	Write-Host "The window will close automatically in 200 seconds"
    Start-Sleep 200
    Exit
######################################
}
 
# Function to return the name of the selected Item from the second DropDown box
function DropDownSelection {
$script:Choice = $DropDown1.SelectedItem.ToString()
$Form.Close()
}
 
 
function SelectLocation{
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
    
    # Set the size of your form
    $Form = New-Object System.Windows.Forms.Form
    $Form.width = 500
    $Form.height = 200
    $Form.Text = "Please select your location"
 
    # Set the font of the text to be used within the form
    $Font = New-Object System.Drawing.Font("Times New Roman",12)
    $Form.Font = $Font
    
    <#$RadioButton1 = New-Object System.Windows.Forms.RadioButton
    $RadioButton1.Location = '70,70'
    $RadioButton1.size = '200,20'
    $RadioButton1.Checked = $true 
    $RadioButton1.Text = "Personal User Device"
    $form.Controls.Add($RadioButton1)

    $RadioButton2 = New-Object System.Windows.Forms.RadioButton
    $RadioButton2.Location = '300,70'
    $RadioButton2.size = '200,20'
    $RadioButton2.Checked = $false
    $RadioButton2.Text = "Shared Device"
    $form.Controls.Add($RadioButton2)#>

    $DropDown1 = new-object System.Windows.Forms.ComboBox
    $DropDown1.Location = new-object System.Drawing.Size(105,20)
    $DropDown1.Size = new-object System.Drawing.Size(280,40)
  
    $Button = new-object System.Windows.Forms.Button
    $Button.Location = new-object System.Drawing.Size(130,100)
    $Button.Size = new-object System.Drawing.Size(100,40)
    $Button.Text = "OK"
    $Button.Add_Click({DropDownSelection})
    $form.Controls.Add($Button)
 
    $CancelButton = new-object System.Windows.Forms.Button
    $CancelButton.Location = new-object System.Drawing.Size(255,100)
    $CancelButton.Size = new-object System.Drawing.Size(100,40)
    $CancelButton.Text = "Cancel"
    $CancelButton.Add_Click({$Form.Close()})
    $form.Controls.Add($CancelButton)
 
    ForEach ($Item in $MyDropDownList1) {
        [void] $DropDown1.Items.Add($Item)
        }
 
    $Form.Controls.Add($DropDown1)      
    $Form.Add_Shown({$Form.Activate()})
    [void] $Form.ShowDialog()
    
    if ($script:choice -eq $Null) {
        Write-Host "Script canceled by user"
        exit
    } 
    
   <# if ($RadioButton1.Checked -and (!($RadioButton2.Checked))) {
        $Sel = ""
    } elseif ($RadioButton2.Checked -and (!($RadioButton1.Checked))) {
        $Sel = "-S"
    } else {
        Write-Host "Something went wrong - please contact Julian Wirth"
    }#>
    $Sel1Temp = $script:choice
    #$Sel1Temp
    $Sel1 = $Sel1Temp.Substring($Sel1Temp.IndexOf("(")+1,2)
    $result =  $Sel1 + $sel
    return $result
}



$MyDropDownList1 = Get-Content -Path $scriptPath\locations.txt

# call the function
#$option = @()
Write-Host ""
$selection = SelectLocation
$grouptag = $selection 
if ([string]::IsNullOrEmpty($grouptag)) {
	Write-Host "Error in script. Please contact Julian Wirth" -BackgroundColor Red -ForegroundColor White
	Start-Sleep 30
    exit 1
} else {
	Write-Host "Group tag / Device tag is: $($grouptag)" -ForegroundColor Magenta
}
Write-Host ""


######################################
PowerShell.exe -ExecutionPolicy Bypass -command "& '$($scriptPath)\get-windowsautopilotinfo.ps1' -grouptag $($grouptag) -online"

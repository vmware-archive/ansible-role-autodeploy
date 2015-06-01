$productName = "vSphere PowerCLI"
$productShortName = "PowerCLI"
$windowTitle = "VMware $productName"
$host.ui.RawUI.WindowTitle = "$windowTitle"
$CustomInitScriptName = "Initialize-PowerCLIEnvironment_Custom.ps1"
$currentDir = Split-Path $MyInvocation.MyCommand.Path
$CustomInitScript = Join-Path $currentDir $CustomInitScriptName

#returns the version of Powershell
# Note: When using, make sure to surround Get-PSVersion with parentheses to force value comparison
function Get-PSVersion {
    if (test-path variable:psversiontable) {
		$psversiontable.psversion
	} else {
		[version]"1.0.0.0"
	}
}

# Returns the path (with trailing backslash) to the directory where PowerCLI is installed.
function Get-InstallPath {
   $regKeys = Get-ItemProperty "hklm:\software\VMware, Inc.\VMware vSphere PowerCLI" -ErrorAction SilentlyContinue

   #64bit os fix
   if($regKeys -eq $null){
      $regKeys = Get-ItemProperty "hklm:\software\wow6432node\VMware, Inc.\VMware vSphere PowerCLI"  -ErrorAction SilentlyContinue
   }

   return $regKeys.InstallPath
}

# Loads additional snapins and their init scripts
function LoadSnapins(){
   $snapinList = @( "VMware.VimAutomation.Core", "VMware.VimAutomation.License", "VMware.DeployAutomation", "VMware.ImageBuilder", "VMware.VimAutomation.Cloud")

   $loaded = Get-PSSnapin -Name $snapinList -ErrorAction SilentlyContinue | % {$_.Name}
   $registered = Get-PSSnapin -Name $snapinList -Registered -ErrorAction SilentlyContinue  | % {$_.Name}
   $notLoaded = $registered | ? {$loaded -notcontains $_}

   foreach ($snapin in $registered) {
      if ($loaded -notcontains $snapin) {
         Add-PSSnapin $snapin
      }

      # Load the Intitialize-<snapin_name_with_underscores>.ps1 file
      # File lookup is based on install path instead of script folder because the PowerCLI
      # shortuts load this script through dot-sourcing and script path is not available.
      $filePath = "{0}Scripts\Initialize-{1}.ps1" -f (Get-InstallPath), $snapin.ToString().Replace(".", "_")
      if (Test-Path $filePath) {
         & $filePath
      }
   }
}
LoadSnapins

# Update PowerCLI version after snap-in load
$version = Get-PowerCLIVersion
$windowTitle = "VMware $productName {0}.{1} Release {2}" -f $version.Major, $version.Minor, ($version.Revision + 1)
$host.ui.RawUI.WindowTitle = "$windowTitle"

function global:Get-VICommand([string] $Name = "*") {
  get-command -pssnapin VMware.* -Name $Name
}

function global:Get-LicensingCommand([string] $Name = "*") {
  get-command -pssnapin VMware.VimAutomation.License -Name $Name
}

function global:Get-ImageBuilderCommand([string] $Name = "*") {
  get-command -pssnapin VMware.ImageBuilder -Name $Name
}

function global:Get-AutoDeployCommand([string] $Name = "*") {
  get-command -pssnapin VMware.DeployAutomation -Name $Name
}

# Error message to update to version 2.0 of PowerShell
# Note: Make sure to surround Get-PSVersion with parentheses to force value comparison
if((Get-PSVersion) -lt "2.0"){
    $psVersion = Get-PSVersion
    Write-Error "$productShortName requires Powershell 2.0! The version of Powershell installed on this computer is $psVersion." -Category NotInstalled
}

# Modify the prompt function to change the console prompt.
# Save the previous function, to allow restoring it back.
$originalPromptFunction = $function:prompt
function global:prompt{

    # change prompt text
    Write-Host "$productShortName " -NoNewLine -foregroundcolor Green
    Write-Host ((Get-location).Path + ">") -NoNewLine
    return " "
}

# Tab Expansion for parameters of enum types.
# This functionality requires powershell 2.0
# Note: Make sure to surround Get-PSVersion with parentheses to force value comparison
if((Get-PSVersion) -ge "2.0"){

    #modify the tab expansion function to support enum parameter expansion
    $global:originalTabExpansionFunction = $function:TabExpansion

    function global:TabExpansion {
       param($line, $lastWord)

       $originalResult = & $global:originalTabExpansionFunction $line $lastWord

       if ($originalResult) {
          return $originalResult
       }
       #ignore parsing errors. if there are errors in the syntax, try anyway
       $tokens = [System.Management.Automation.PSParser]::Tokenize($line, [ref] $null)

       if ($tokens)
       {
           $lastToken = $tokens[$tokens.count - 1]

           $startsWith = ""

           # locate the last parameter token, which value is to be expanded
           switch($lastToken.Type){
               'CommandParameter' {
                    #... -Parameter<space>

                    $paramToken = $lastToken
               }
               'CommandArgument' {
                    #if the last token is argument, that can be a partially spelled value
                    if($lastWord){
                        #... -Parameter Argument  <<< partially spelled argument, $lastWord == Argument
                        #... -Parameter Argument Argument

                        $startsWith = $lastWord

                        $prevToken = $tokens[$tokens.count - 2]
                        #if the argument is not preceeded by a paramter, then it is a value for a positional parameter.
                        if ($prevToken.Type -eq 'CommandParameter') {
                            $paramToken = $prevToken
                        }
                    }
                    #else handles "... -Parameter Argument<space>" and "... -Parameter Argument Argument<space>" >>> which means the argument is entirely spelled
               }
           }

           # if a parameter is found for the argument that is tab-expanded
           if ($paramToken) {
               #locates the 'command' token, that this parameter belongs to
               [int]$groupLevel = 0
               for($i=$tokens.Count-1; $i -ge 0; $i--) {
                   $currentToken = $tokens[$i]
                   if ( ($currentToken.Type -eq 'Command') -and ($groupLevel -eq 0) ) {
                      $cmdletToken = $currentToken
                      break;
                   }

                   if ($currentToken.Type -eq 'GroupEnd') {
                      $groupLevel += 1
                   }
                   if ($currentToken.Type -eq 'GroupStart') {
                      $groupLevel -= 1
                   }
               }

               if ($cmdletToken) {
                   # getting command object
                   $cmdlet = Get-Command $cmdletToken.Content
                   # gettint parameter information
                   $parameter = $cmdlet.Parameters[$paramToken.Content.Replace('-','')]

                   # getting the data type of the parameter
                   $parameterType = $parameter.ParameterType

                   if ($parameterType.IsEnum) {
                      # if the type is Enum then the values are the enum values
                      $values = [System.Enum]::GetValues($parameterType)
                   } elseif($parameterType.IsArray) {
                      $elementType = $parameterType.GetElementType()

                      if($elementType.IsEnum) {
                        # if the type is an array of Enum then values are the enum values
                        $values = [System.Enum]::GetValues($elementType)
                      }
                   }

                   if($values) {
                      if ($startsWith) {
                          return ($values | where { $_ -like "${startsWith}*" })
                      } else {
                          return $values
                      }
                   }
               }
           }
       }
    }
}

# Opens documentation file
function global:Get-PowerCLIHelp{
   $ChmFilePath = Join-Path (Get-InstallPath) "VICore Documentation\$productName Cmdlets Reference.chm"
   $docProcess = [System.Diagnostics.Process]::Start($ChmFilePath)
}

# Opens toolkit community url with default browser
function global:Get-PowerCLICommunity{
    $link = "http://communities.vmware.com/community/vmtn/vsphere/automationtools/windows_toolkit"
    $browserProcess = [System.Diagnostics.Process]::Start($link)
}

# Find and execute custom initialization file
$existsCustomInitScript = Test-Path $CustomInitScript
if($existsCustomInitScript) {
   & $CustomInitScript
}

Connect-VIServer -Server {{ vcenter_host }} -Protocol https -User {{ vcenter_user }} -Password {{ vcenter_password }}
Add-EsxSoftwareDepot -DepotUrl C:\ps\{{ esxi_depot_zip }}

$HostProfile = Get-VMHostProfile {{ esxi_host_profile }}
$ImageProfile = Get-EsxImageProfile -Name "{{ esxi_img }}"

{% for cluster in datacenter['clusters'] %}
  {% for host in cluster['hosts'] %}
$Cluster = Get-Cluster {{ cluster['name'] }}
New-DeployRule -Name "DemoRule_{{ cluster['name'] }}_{{ loop.index }}" -Item $HostProfile,$ImageProfile,$Cluster -Pattern {{ host['ip'] }}
Set-DeployRuleSet -DeployRule "DemoRule{{ cluster['name'] }}_{{ loop.index }}"
  {% endfor %}
{% endfor %}

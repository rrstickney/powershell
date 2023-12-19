function devenvctl {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateSet("start", "stop", "reboot", "destroy", "build")]
        [string]$Action
    )

    DynamicParam {
        if ($Action -eq "build") {
            $countParam = @{
                Name = 'Count'
                Alias = 'c'
                ParameterSetName = "build"
                Mandatory = $true
                ValueFromPipelineByPropertyName = $false
                Position = 1
                HelpMessage = 'Number of VMs to be built'
            }

            $attrCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
            $attrCollection.Add((New-Object System.Management.Automation.ParameterAttribute -ArgumentList $countParam))
            $attrCollection.Add((New-Object System.Management.Automation.ValidateRangeAttribute -ArgumentList 1, [int]::MaxValue))

            $dynParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Count', [int], $attrCollection)
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('Count', $dynParam)

            return $paramDictionary
        }
    }

    begin {
        # Only set if 'build' action is used
        if ($Action -eq "build") {
            $Count = $PSBoundParameters['Count']
        }
    }

    process {
        # Function to get the list of VMs
        $vmlist = vboxmanage list vms | ForEach-Object {
            if ($_ -match '\{([^\}]+)\}') {
                $matches[1]
            }
        }

        switch ($Action) {
            "start" {
                foreach ($vm in $vmlist) {
                    vboxmanage startvm $vm --type headless
                }
            }
            "stop" {
                foreach ($vm in $vmlist) {
                    vboxmanage controlvm $vm acpipowerbutton
                }
            }
            "reboot" {
                foreach ($vm in $vmlist) {
                    vboxmanage controlvm $vm reboot
                }
            }
            "destroy" {
                foreach ($vm in $vmlist) {
                    vboxmanage unregistervm $vm --delete
                }
            }
            "build" {
                foreach ($num in 1..$Count) {
                    $ubuntu_src = "C:\opt\virtualbox\virtualbox_base_images\ubuntu_base.ova"
                    $centos_src = "C:\opt\virtualbox\virtualbox_base_images\centos_base.ova"
                    vboxmanage import $ubuntu_src --vsys 0 --vmname "ubuntu-00$num"
                    vboxmanage import $cents_src --vsys 0 --vmname "centos-00$num"
                }
            }
            Default {
                Write-Host "Unknown action: $Action"
            }
        }
    }
}
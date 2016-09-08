#!powershell
# This file is part of Ansible
#
# David Woerner
#
# Ansible is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Ansible is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Ansible.  If not, see <http://www.gnu.org/licenses/>.

# WANT_JSON
# POWERSHELL_COMMON

# win_services module (create/update Windows service)

$params = Parse-Args $args;

$result = New-Object PSObject;
Set-Attr $result "changed" $false;

try
{
    $name = Get-Attr $params "name" -failifempty $true -resultobj $result;
    $path = Get-Attr $params "path" -failifempty $false -resultobj $result;
    $start = Get-Attr $params "start" -failifempty $true -resultobj $result;
    $withFail = Get-Attr $params "withfail" -failifempty $false -resultobj $result;
    $action = Get-Attr $params "action" -failifempty $false -resultobj $result;

    if ($start -ne "boot" -and $start -ne "system" -and $start -ne "auto" -and $start -ne "demand" -and $start -ne "disabled")
    {
        Fail-Json $result "Invalid start param. Must be one of: boot, system, auto, demand, disabled"
    }
    elseif ($action -ne "create" -and $action -ne "update")
    {
        Fail-Json $result "Invalid action param. Must be one of: create, update"
    }

    if ($action -eq "create")
    {
        $argListCreate = 'create {0} start= {1} binPath= "{2}"' -f $name, $start, $path
        Start-Process "sc.exe" -ArgumentList $argListCreate -Wait
    }
    elseif ($action -eq "update")
    {
        $argListUpdate = 'config {0} start= {1}' -f $name, $start

        if ($path -ne $null)
        {
            $argListUpdate = '{0} binPath= "{1}"' -f $argListUpdate, $path
        }

        Start-Process "sc.exe" -ArgumentList $argListUpdate -Wait
    }

    if ($withFail -eq "true")
    {
        $argListFail = 'failure {0} reset= 0 actions= restart/60000' -f $name
        Start-Process "sc.exe" -ArgumentList $argListFail -Wait
    }

    $result.changed = $true

    Exit-Json $result
}
catch
{
    Fail-Json $result $_.Exception.Message
}

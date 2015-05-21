Connect-VIServer -Server {{ vcenter_ip }}  -Protocol https -User {{ vcenter_user }} -Password {{ vcenter_password }}

$HostProfile = Get-VMHostProfile {{ esxi_host_profile }}
$ImageProfile = Get-EsxImageProfile -Name "{{ esxi_depot }}-standard"

{% for cluster in datacenter['clusters'] %}
  {% for host in cluster['hosts'] %}
    New-DeployRule -Name DemoDeploy_{{ loop.index }} -Item $HostProfile,$ImageProfile,{{ cluster['name'] }} -Pattern {{ host['ip'] }}
    Set-DeployRuleSet -DeployRule Deploy{{ cluster['name'] }}_{{ loop.index }}
  {% endfor %}
{% endfor %}

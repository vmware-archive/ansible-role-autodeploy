Connect-VIServer -Server {{ vcenter_ip }}  -Protocol https -User {{ vcenter_user }} -Password {{ vcenter_password }}
Add-EsxSoftwareDepot -DepotUrl C:\{{ esxi_depot_zip }}

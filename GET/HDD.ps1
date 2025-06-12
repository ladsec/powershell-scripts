#volny misto na hdd
(([wmi]"root\cimv2:Win32_logicalDisk.DeviceID='C:'").FreeSpace/1GB).ToString("N2")+"GB"

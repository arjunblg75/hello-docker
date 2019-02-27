FROM microsoft/windowsservercore:ltsc2016

ENV AuthMode _

RUN mkdir C:\PortalWindowsService
RUN mkdir C:\PortalWeb

SHELL ["powershell"]

RUN Install-WindowsFeature NET-Framework-45-ASPNET ; \  
    Install-WindowsFeature Web-Asp-Net45

RUN Install-WindowsFeature Print-Server ; \
    Set-Service spooler -StartupType Automatic ; \
    Start-Service spooler ; \
    Get-Service spooler ; \
    Get-Printer

RUN powershell -Command Add-WindowsFeature Web-Server

ENV chocolateyUseWindowsCompression=false
RUN iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex; Install-PackageProvider -Name chocolatey -Force

RUN choco install Office365Business -y

COPY Content/AppPatch Windows/AppPatch
COPY Content/SysWOW64 Windows/SysWOW64
COPY Content/System32 Windows/System32

RUN Regsvr32 /s "C:\Windows\SysWOW64\hhctrl.ocx"

RUN mkdir -Force C:\Windows\SysWOW64\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache ; \
    mkdir -Force C:\Windows\SysWOW64\config\systemprofile\AppData\Local\Microsoft\Windows\INetCacheContent ; \
    mkdir -Force C:\Windows\SysWOW64\config\systemprofile\AppData\Local\Microsoft\Windows\INetCacheContent.Word ; \
    mkdir -Force C:\Windows\SysWOW64\config\systemprofile\AppData\Local\Microsoft\Windows\INetCookies ; \
    mkdir -Force C:\Windows\SysWOW64\config\systemprofile\Documents ; \
    mkdir -Force C:\Windows\SysWOW64\config\systemprofile\Desktop ; \
    mkdir -Force C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache ; \
    mkdir -Force C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCacheContent ; \
    mkdir -Force C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCacheContent.Word ; \
    mkdir -Force C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCookies ; \
    mkdir -Force C:\Windows\System32\config\systemprofile\Documents ; \
    mkdir -Force C:\Windows\System32\config\systemprofile\Desktop


WORKDIR /

# Copy the web bits and configure the web site.
COPY Xpertdoc.Portal.Web PortalWeb

RUN Remove-WebSite -Name 'Default Web Site'
RUN Import-Module ServerManager ; \
    Add-WindowsFeature Web-Scripting-Tools ; \
    Import-Module WebAdministration ; \
    Set-ItemProperty 'IIS:\AppPools\.NET v4.5' -name processModel -value @{identityType=0}
RUN New-WebSite -Name 'Xpertdoc Portal' -Port 80 \
    -PhysicalPath 'C:\PortalWeb' -ApplicationPool '.NET v4.5'

EXPOSE 80

# Copy the windows service bits.
COPY Xpertdoc.Portal.WindowsService PortalWindowsService

COPY PortalStart.ps1 /

ENTRYPOINT .\PortalStart -AuthMode $env:AuthMode -Verbose
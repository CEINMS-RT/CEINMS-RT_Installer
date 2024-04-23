#Requires -RunAsAdministrator
#===============================================================
# Gets script directory
#===============================================================
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#===============================================================
# Installs CMake
#===============================================================

Start-Process -Wait .\cmake-3.23.0-rc1-windows-x86_64.msi -ArgumentList "/passive"
# Current user path variables for CMake
if ($env:PATH -notcontains "$env:PROGRAMFILES\CMake\bin") { 
    $UserPath  = [System.Environment]::GetEnvironmentVariable("Path","User")
    [Environment]::SetEnvironmentVariable('PATH', "$UserPath;$env:PROGRAMFILES\CMake\bin",'User');
}
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

#===============================================================
# Installs git
#===============================================================

Start-Process -Wait .\Git-2.35.1.2-64-bit.exe -ArgumentList "/SILENT /NORESTART"
if ($env:PATH -notcontains "$env:PROGRAMFILES\Git\bin") { 
    $UserPath  = [System.Environment]::GetEnvironmentVariable("Path","User")
    [Environment]::SetEnvironmentVariable('PATH', "$UserPath;$env:PROGRAMFILES\Git\bin",'User');
}
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

#===============================================================
# Installs boost
#===============================================================

Start-Process -Wait .\boost_1_75_0-msvc-14.2-64.exe -ArgumentList "/sp- /silent /suppressmsgboxes /norestart"

#===============================================================
# Installs visual studio 2019 and visual studio build tools 2019
# Installs the visual studio community version
#===============================================================

Start-Process -Wait .\vs_Community.exe -ArgumentList "--productId Microsoft.VisualStudio.Product.Community --add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended --passive"
Start-Process -Wait .\vs_Community.exe -ArgumentList "--productId Microsoft.VisualStudio.Product.BuildTools --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --passive"

#===============================================================
# Installs XSD
#===============================================================
Start-Process -Wait .\xsd-4.0.msi -ArgumentList "/passive"
Copy-Item ".\serialization.txx" "${env:ProgramFiles(x86)}\CodeSynthesis XSD 4.0\include\xsd\cxx\tree\serialization.txx" -force

if (!${env:PATH}.Contains("${env:ProgramFiles(x86)}\CodeSynthesis XSD 4.0\bin64")) {
    $UserPath  = [System.Environment]::GetEnvironmentVariable("Path","User")
    [Environment]::SetEnvironmentVariable('PATH', "$UserPath;${env:ProgramFiles(x86)}\CodeSynthesis XSD 4.0\bin64",'User');
}
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 


#===============================================================
# Installs Qt
#===============================================================
# Version 5152 does not seem to include a package option for MSVC2019. 5.15 seems to support it, untested. For now, this seems to be working 
# xcopy /d qtaccount.ini $env:appdata\Qt\
Get-Content qtCredentials.txt | Foreach-Object{
    $var = $_.Split('=')
    New-Variable -Name $var[0] -Value $var[1]
 }
Start-Process -Wait .\qt-unified-windows-x64-4.4.1-online.exe -ArgumentList "--email $qtemail --pw $qtpassword --accept-licenses --default-answer --confirm-command --confirm-command --accept-obligations install qt.qt5.5152.win64_msvc2019_64 qt.qt5.5152.qtcharts qt.qt5.5152.qtdatavis3d"
$QtBinPath = "Qt\5.15.2\msvc2019_64\bin";
if (!${env:PATH}.Contains("${env:SYSTEMDRIVE}\$QtBinPath")) {
    $UserPath  = [System.Environment]::GetEnvironmentVariable("Path","User")
    [Environment]::SetEnvironmentVariable('PATH', "$UserPath;${env:SYSTEMDRIVE}\$QtBinPath",'User');
}
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 


#===============================================================
# Installs Glew
#===============================================================
Expand-Archive .\glew-2.1.0-win32.zip -DestinationPath "${env:PROGRAMFILES(X86)}/" -Force
if (!${env:PATH}.Contains("${env:ProgramFiles(x86)}\glew-2.1.0\bin\Release\x64")) {
    $UserPath  = [System.Environment]::GetEnvironmentVariable("Path","User")
    [Environment]::SetEnvironmentVariable('PATH', "$UserPath;${env:ProgramFiles(x86)}\glew-2.1.0\bin\Release\x64",'User');
}
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

#===============================================================
# Installs Opensim core
#===============================================================
# Clones, compiles and installs opensim and dependencies
$currFolder = Get-Location
git clone -b Branch_4.1 https://github.com/opensim-org/opensim-core.git

cd .\opensim-core

cd dependencies
(Get-Content "CMakeLists.txt") -Replace 'Simbody-3.7', '768dc1596c4290ca51aa0894f78b92fef3dd9b2e' | Set-Content "CMakeLists.txt" # Changes simbody version to specific commit, so that it is compatible with this branch of OpenSim
New-Item -Force -Name "build" -ItemType "directory"
New-Item -Force -Name "install" -ItemType "directory"
cd build

# Compiles Opensim dependencies
cmake .. -G "Visual Studio 16 2019" -A x64 -DCMAKE_INSTALL_PREFIX="${currFolder}/opensim-core/dependencies/install"
cmake --build . --target all_build --config Debug
cd ..\..\


# Finally installs OpenSim
#(Get-Content "CMakeLists.txt") -Replace 'SIMBODY_VERSION_TO_USE 3.7', 'SIMBODY_VERSION_TO_USE 3.8' | Set-Content "CMakeLists.txt" # Changes simbody version to specific commit, so that it is compatible with this branch of OpenSim
New-Item -Force -Name "build" -ItemType "directory"
# cmake -S . -B ./build -G "Visual Studio 16 2019" -A x64 -DOPENSIM_DEPENDENCIES_DIR="${currFolder}/opensim-core/dependencies/install" -DCMAKE_INSTALL_PREFIX="${env:ProgramFiles}/opensim-core" -DOPENSIM_WITH_CASADI=OFF -DOPENSIM_WITH_TROPTER=OFF
cmake -S . -B ./build -G "Visual Studio 16 2019" -A x64 -DOPENSIM_DEPENDENCIES_DIR="${currFolder}/opensim-core/dependencies/install" -DCMAKE_INSTALL_PREFIX="${env:ProgramFiles}/opensim-core" -DSIMBODY_HOME="${currFolder}/opensim-core/dependencies/install/simbody" -DBUILD_TESTING=OFF

# OpenSim does not support two simultaneous installations of debug and release, which is a problem. If you need release, you will have to change it here and install again
# This will overwrite the previous debug installation
cmake --build build --target install --config Debug
cd ..
if (!${env:PATH}.Contains("${env:ProgramFiles}\opensim-core\bin")) {
    $UserPath  = [System.Environment]::GetEnvironmentVariable("Path","User")
    [Environment]::SetEnvironmentVariable('PATH', "$UserPath;${env:ProgramFiles}\opensim-core\bin",'User');
}
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

#===============================================================
# Installs Eigen - Optional, required by Pagmo2
#===============================================================

# git clone https://gitlab.com/libeigen/eigen.git
# cd eigen
# New-Item -Force -Name "build" -ItemType "directory"
# cd build
# cmake .. -G "Visual Studio 16 2019" -A x64
# cmake --build . --target install
# cd ..\..\


#===============================================================
# Installs TBB - Optional, required by Pagmo2
#===============================================================

# git clone https://github.com/oneapi-src/oneTBB.git
# cd oneTBB
# git checkout fb8ae3b97db8856b273eaa84ca8bcd22110ea48d 
# New-Item -Force -Name "build" -ItemType "directory"
# cd build
# cmake .. -G "Visual Studio 16 2019" -A x64 -DTBB_TEST=OFF
# cmake --build . --target install --config Debug
# cmake --build . --target install --config Release
# cd ..\..\

# if (!${env:PATH}.Contains("${env:ProgramFiles}\TBB\bin")) {
#     $UserPath  = [System.Environment]::GetEnvironmentVariable("Path","User")
#     [Environment]::SetEnvironmentVariable('PATH', "$UserPath;${env:ProgramFiles}\TBB\bin",'User');
# }
# $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

#===============================================================
# Installs Pagmo2 - Optional
#===============================================================

# git clone https://github.com/esa/pagmo2.git
# Copy-Item ".\YACMACompilerLinkerSettings.cmake" ".\pagmo2\cmake_modules\yacma\YACMACompilerLinkerSettings.cmake" -force
# cd pagmo2
# New-Item -Force -Name "build" -ItemType "directory"
# cd build 
# cmake .. -G "Visual Studio 16 2019" -A x64 -DPAGMO_WITH_EIGEN3=ON -DCMAKE_BUILD_TYPE=Debug -DPAGMO_BUILD_STATIC_LIBRARY=ON
# cmake --build . --target install --config Debug
# cd ..\..\

#===============================================================
# Installs simbody !!! ALREADY ISNTALLED BY OPENSIM !!!
#===============================================================

# git clone https://github.com/simbody/simbody.git
# cd simbody
# mkdir build
# cd build 
# cmake .. -G "Visual Studio 16 2019" -A x64
# cmake --build . --target install --config Debug
# cd ..\..\

#===============================================================
# Installs Concurrency - Optional
#===============================================================

# git clone https://github.com/RealTimeBiomechanics/Concurrency.git
# # For alex repo:
# # git clone https://github.com/lavancig/Concurrency_rtosim_joint_reaction.git Concurrency

# cd Concurrency
# git switch master
# New-Item -Force -Name "build" -ItemType "directory"
# cd build 
# cmake .. -G "Visual Studio 16 2019" -A x64
# cmake --build . --target install --config Debug
# cd ..\..\

#===============================================================
# Installs Filter - Optional
#===============================================================

# git clone https://github.com/RealTimeBiomechanics/Filter.git
# cd Filter
# New-Item -Force -Name "build" -ItemType "directory"
# cd build 
# cmake .. -G "Visual Studio 16 2019" -A x64
# cmake --build . --target install --config Debug
# cd ..\..\


#===============================================================
# Installs Qualisys cpp SDK - Optional
#===============================================================

# git clone https://github.com/qualisys/qualisys_cpp_sdk.git
# git clone https://github.com/lavancig/qualisys_cpp_sdk.git
# cd qualisys_cpp_sdk
# git switch bugfix/vs2019_install_include_path
# New-Item -Force -Name "build" -ItemType "directory"
# cd build 
# cmake .. -G "Visual Studio 16 2019" -A x64
# cmake --build . --target install --config Debug
# cd ..\..\


#===============================================================
# Installs RTOSIM - Optional
#===============================================================

# git clone git@bitbucket.org:ctw-bw/rtosim.git
# cd rtosim
# git switch bugfix/qualisys_sdk_linking
# # For Alex joint reactions:
# # git switch feature/joint_reactions
# New-Item -Force -Name "build" -ItemType "directory"
# cd build 
# cmake .. -G "Visual Studio 16 2019" -A x64 -DCMAKE_PREFIX_PATH="${env:PROGRAMFILES\qualisys_cpp_sdk}" -DCMAKE_PREFIX_PATH="${env:ProgramFiles(x86)}\CodeSynthesis XSD 4.0"

# cmake --build . --target install --config Debug
# cd ..\..\

#===============================================================
# Select a folder for cloning CEINMS, clones it and compiles 
# it in the Dev branch
#===============================================================

$repoFolder = ""

Add-Type -AssemblyName System.Windows.Forms
$FolderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
$FolderBrowser.Description = 'Select the folder where CEINMS-RT will be cloned'
$result = $FolderBrowser.ShowDialog((New-Object System.Windows.Forms.Form -Property @{TopMost = $true }))
if ($result -eq [Windows.Forms.DialogResult]::OK){
$repoFolder = $FolderBrowser.SelectedPath
} else {
exit
}

# Reloads all environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

mkdir $repoFolder'\ceinms-rt'
git clone git@bitbucket.org:ctw-bw/ceinms_rt.git $repoFolder'\ceinms-rt'
cd $repoFolder'\ceinms-rt'
git switch Development
New-Item -Force -Name "build" -ItemType "directory"
cd build 
cmake .. -G "Visual Studio 16 2019" -A x64 -DCOMPILE_PLUGIN=OFF -DCMAKE_PREFIX_PATH="${env:SYSTEMDRIVE}\Qt\5.15.2\msvc2019_64;${env:ProgramFiles(x86)}\glew-2.1.0;${env:ProgramFiles(x86)}\CodeSynthesis XSD 4.0"
cmake --build . --config Debug

# Copies msvcr dll
cd $scriptPath
Copy-Item ".\msvcr120d.dll" "${env:SYSTEMDRIVE}\Windows\System32\msvcr120d.dll" -force


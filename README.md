This repository contains dependencies to allow for the execution of CEINMS-RT. It is recommended to clone this repository, as it will install all CEINMS-RT dependencies from scratch, including git.
A script installs all required software and finally compiles CEINMS, and it requires no input from the user other than the selection of the folder to install CEINMS-RT.

Before Starting, follow the steps:

1 - Open a powershell terminal with administrator rights (CMD will not work) and run the following command. This will allow for the unrestricted execution of powershell scripts. 

`set-executionpolicy Unrestricted`

2 - Enable ssh client on Windows.

 Instructions can be found in [this](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse?tabs=gui) page, in the "Install OpenSSH for Windows" section

3 - Create an ssh key. For that, open a terminal and type 

`ssh-keygen`

Press enter several times to accept the default options, or choose your preferred options based on [this](https://docs.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement) page

4 - Setup your ssh key on GitHub.

You can find instruction in Step 3 of [this](https://support.atlassian.com/bitbucket-cloud/docs/set-up-an-ssh-key/) page. The resulting keys can be found in the ~/.ssh folder

6 - Create a Qt Account

CEINMS uses Qt for its GUI. Qt requires an account for installation. Go to Qt Website and [create an account](https://www.qt.io/).
Once the account is created, modify the file qtCredentials.txt with your password and e-mail.

5 - Make sure you have at least 25GB of disk space before you start. Then open a powershell terminal as administrator, move to the main folder of this repository and run the automated installation script as follows:

`.\installCEINMS.ps1`

You might have to still allow the script to run by answering R. You will be prompted after several minutes to choose a folder where CEINMS-RT will be cloned to.

The script will install the following software:
<ul>
  <li>CMake 3.31.8</li>
  <li>git 2.35.1.2</li>
  <li>boost 1.75 for msvc-14.2 x64</li>
  <li>Visual studio 2019 community</li>
  <li>Visual studio build tools 2019 community</li>
  <li>XSD 4.0</li>
  <li>Qt 5.12.11</li>
  <li>Glew 2.1.0</li>
  <li>Opensim core 4.1</li>
  <li>Eigen</li>
  <li>TBB</li>
  <li>Pagmo2</li>
  <li>CEINMS-RT</li>
</ul> 






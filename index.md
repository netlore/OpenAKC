## OpenAKC downloads.

You can find the [source code for the project on GitHub](https://github.com/netlore/OpenAKC/) if you are interested in contributing to the code, reporting issues, or helping with documentation etc, but to simply make use of the project to support your users, please use the repo's below.

If you don't see a package for the distributuion you are using, please feel free to open an issue in the GitHub page above, if at all possible I will assist.  It may simply be that I need someone with access to that platform to test packages, and in cases where a specific OS package cannot be created, I will endevour to create an install script. If you can assist with testing, or packaging for a particular platform, please make yourself known!.

### Repo's

#### Debian / Ubuntu based distros

Download and add the repository key:

```markdown
wget -nc https://raw.githubusercontent.com/netlore/OpenAKC/master/resources/openakc.key
sudo apt-key add openakc.key
```

Add the repository: 


| OS Version                         | Add Repo      |
|------------------------------------|:-------------:|
| Ubuntu/PopOS 18.04+<br>Mint 19.x   |echo "deb https://netlore.github.io/OpenAKC/repos/ubuntu/18.04 ./" &#124; sudo tee /etc/apt/sources.list.d/openakc.list|
| Ubuntu/PopOS 20.04+<br>Mint 20.x   |echo "deb https://netlore.github.io/OpenAKC/repos/ubuntu/18.04 ./" &#124; sudo tee /etc/apt/sources.list.d/openakc.list|
| Debian 10(buster)                  | Coming Soon                                                                                                           |

Update packages:

```markdown
sudo apt update
```

Install one of the following:

| Host Type              | Install Package             |
|------------------------------------|-------------|
| OpenAKC Security Server            | sudo apt install openakc-server |
| OpenAKC Client                     | sudo apt install openakc        |
| OpenAKC Remote Management Host     | sudo apt install openakc        |

#### Redhat / Fedora based distros

DNF based distros may need to install the DNF config manager module:

```markdown
sudo dnf install 'dnf-command(config-manager)'
```

Add the repository: 

| OS Version                         | Add Repo      |
|------------------------------------|---------------|
| Redhat Enterprise 7<br>Centos 7<br>Oracle Linux 7  |wget -O - https://netlore.github.io/OpenAKC/repos/openakc-el7.repo &#124; sudo tee /etc/yum.repos.d/openakc.repo|
| Redhat Enterprise 8<br>Centos 8<br>Oracle Linux 8  |dnf config-manager --add-repo https://netlore.github.io/OpenAKC/repos/openakc-el8.repo                          |
| Fedora 31                                          |dnf config-manager --add-repo https://netlore.github.io/OpenAKC/repos/openakc-fedora31.repo                     |
| Fedora 32                                          |dnf config-manager --add-repo https://netlore.github.io/OpenAKC/repos/openakc-fedora32.repo                     |

Note that it is likely that the "openakc-el7.repo" will work on any Fedora version from 19 onwards, and the "openakc-el8.repo" will work on any Fedora 28 onwards, but this has not been explicitly tested.  Your feedback is welcomed.

#### OpenSuSE/SuSE Enterprise based distros

| OS Version                         | Add Repo      |
|------------------------------------|---------------|
| OpenSuSE 15  |wget -O - https://netlore.github.io/OpenAKC/repos/openakc-opensuse15.repo &#124; sudo tee /etc/zypp/repos.d/openakc.repo|


### Basic Setup

For a simple setup using a single security server with either no users or where the users are using the security server itself as a jump point, the only configuration required is to ensure that the file on the **client** machine _/etc/openakc/openakc.conf_ correctly defines the server(s).   The file is pre-configured with the unqualified names "openakc01" and "openakc02" already populated, so you could simply add these names to your DNS and potentially no extra configuration would be required at the clients.

### Support or Contact

Having trouble with OpenAKC? Check out our [documentation](https://github.com/netlore/OpenAKC/raw/master/docs/OpenAKC%20Admin%20Guide.pdf) or [contact](openakc@default.co.uk) and we’ll help you sort it out.

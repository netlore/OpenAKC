# OpenAKC (Download site [Available HERE][download])

<img src="https://raw.githubusercontent.com/netlore/OpenAKC/master/docs/resources/AKCKeys.jpg">

#### OpenAKC provides SSH "Self Service SSH key management for users", "Centralised SSH Key Management for static trust" and can offer advanced features for tracking, auditing and controlling what users (and sysadmins) do.

* Centrally control all of your SSH trust.

* Stop users from altering or adding trust relationships.

* Control when, and how keys can be used.

* Meet security best practice requirements related to logging privilage escalation without needing to roll out a directory such as AD or LDAP across your entire estate.

* Allow users to manage their own SSH key pairs and use those keys to access role accounts based on rules you define.

* Centrally manage static trust without having to deal with "authorized_keys" files spread across your estate.

* Instantly update or remove a key across an entire estate, without even having to log in to the servers in question.

* Define rules for access to servers that are not yet configured

* Creative use of the interface to "Linux Capabilities" allows you to apply controls other systems can only dream of. Protect critical system files, or user data from junior sysadmins and oportunistic developers alike.... the possibilities are endless.


OpenAKC is a building block which can be used as a stand alone tool or as part of an integrated "Privilaged Access Management" tool if combined with a system for approving access, either via a directory such as AD / LDAP or direcetly via the API, perhaps from a web application.

With a client server model, you are free to completely disable local ssh authentication methods your users might leverage to bypass access control!  Confound your troublesome users, or hackers with ssh configuration like this:-

```
AuthorizedKeysFile /dev/null
PasswordAuthentication no
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
```

Allow users to create and register thier own ssh key pair with the system without involving admin while enforcing the use of pass phrases to encrypt private keys, even segregate security administrators so that they cannot easily grant access to themselves, and not without leaving an audit trail.

Combined Security Server|Separate Security Server
---|---
<a href="https://github.com/netlore/OpenAKC/blob/master/docs/OpenAKC%20Combined%20Bastion%20Host%20%26%20Security%20Server%20Diagram.pdf" target="_blank"><img src="https://raw.githubusercontent.com/netlore/OpenAKC/master/docs/resources/OpenAKC%20Combined%20Bastion%20Host%20%26%20Security%20Server%20Diagram.svg"></a>|<a href="https://github.com/netlore/OpenAKC/blob/master/docs/OpenAKC%20Separate%20Bastion%20Host%20%26%20Security%20Server%20Diagram.pdf" target="_blank"><img src="https://raw.githubusercontent.com/netlore/OpenAKC/master/docs/resources/OpenAKC%20Separate%20Bastion%20Host%20%26%20Security%20Server%20Diagram.svg"></a>

Examples:

1. Do you have lots of systems which have a few application accounts, or perhaps just a root account... you don't want to join them all to a directory, and have to deal with maintaining user home folders, and user access control only via a directory that may be run by another team entirely?

2. Do you need to meet security best practice which states that users must log in first with their own account and escalate privilage, but you don't want users to have their own accounts which take up space and need managing?

3. Do you sometimes need to grant privilaged access either to less experienced support staff, or 3rd party support staff and wish you could see exactly what they did (even if the server died as a result).

4. Do you wish you could impose restrictions on exactly when SSH keys could be used to gain access (perhaps to stop access during critical processing), where from... or what users of those keys can do?

5. Do you sometimes have to give "root" access, but wish there was a way to protect certain configuration or settings?


##### OpenAKC is far from a traditional key manager

1. It allows all static trust which would normally be configured in an "authorized_keys" file to be centrally managed.  Public keys are uploaded to the system, and associated with particular hosts/accounts all via an API (or "crontab -e" style rule editor)

2. Logs show exactly which user logged in and from where, even if they logged in directly to a privilaged user.

3. Session recording is achieved (when enabled) via an encrypted stream set up with the security server when an interactive session is opened using OpenAKC authentication.  This allows an almost real time log of the users session.

4. Users can also be presented with a prompt asking them to provide brief details of their reason for access, perhaps a change number etc.

5. Many restrictions applied, over and above what SSH normally provides.  You can provide access within a date range, only on certain days, or at certain times. You can override the users shell, or deny them access to a shell entirely, and even specify what commands they can execute remotely.

6. The option to drop kernel capabilities from the process tree created by a login, will allow you to block certain OS functions from a user, even if they log in as root, use "sudo", or run a "SUID" binary.  Common uses would include, making it impossible to alter immutable files (even for root), or blocking the loading of kernel modules etc.  Details can be found here [Capabilities Man Page][caps]

7. Additional capabilities are added for "scp" functionality, including file transfer logging, and chroot.

You no-longer have to require users to log in to servers with personal accounts and escalate privilages just to ensure complete logging.  OpenAKC relieves you from managing user permissions, home folders, and authentication across large numbers of machines while ensuring detailed records showing which users accessed which servers, and what they did!

**WARNING: This is pre-release software and although it is functional, plenty of work remains to ensure it is robust and secure.**

Documentation is still being created, but you may like to see an [Demo Video][demo], I won't be offended if you want to play this at double speed.

Any contributions of in regard to documentation, code or suggestions would be greatly appreciated.

Please note that most of this tool is created using shell code, I hope this makes it approachable for sysadmins (as the likely users), to contribute.



[demo]: https://youtu.be/58i_cknmzvc
[caps]: https://man7.org/linux/man-pages/man7/capabilities.7.html
[download]: https://netlore.github.io/OpenAKC/download/

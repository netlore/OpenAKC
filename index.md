
<img src="https://raw.githubusercontent.com/netlore/OpenAKC/master/docs/resources/AKCKeys-short.jpg">


### What is OpenAKC?

OpenAKC consists of 3 parts, listed below.

#### Self Service Authentication Gateway for SSH

What this means in practice, is that users needing to log in using "application" or "role" accounts on various machines in an estate, can be supported in a way that is familiar, and standard from their perspective, while the systems administrators can utilise a central directory such as AD or LDAP to control that access.

It allows the user to interact with SSH, in a completely normal way, by creating a personal key pair and using that to access hosts (after a self service process to "register" that key).

The administrator on the other hand is able to refer to users, or groups of users from their directory, while creating rules that apply to the hosts.... the plugin installed on the client will identify the user by the SSH key fingerprint, and then look up the associated rules, and directory information before seamlessly passing their public key to the SSH Daemon on the target key if they are permitted to log in.

From a security perspective, even tho the user used a personal SSH key to log in directly to an applicattion or role user (or even root), the logs will should the privilage escalation process in a way that should satisfy security best practice. OpenAKC can even write "fake" sudo logs for the benefit of SIEM systems which are expecting users to escalate privilage after initially logging in with a personal user, (no one wants to manage personal user accounts on servers).

#### Dynamic SSH key manager.

Using the same rule system as the self service key manager, OpenAKC allows the administrator to centrally manage "static trust", which would normally be controlled locally to each account, on each host using an "authorized_keys" file, which is easily modified by the user once they log in.

OpenAKC effectively allows the administrator to control all the public keys in use across the entire estate from a single location.  If someone wants to set up a trust relationship, they pass the public key to the OpenAKC administrator, who submits it to the system, and then creates rules referring to that key, in the same way as they would refer to a user or group to grant access.

Each key is allocated an ID, so that they can be rotated without even updating the rules.  A key could be changed in 1 command via the API, and be effective instantly across hundreds of systems.

#### Privileged access manager

OpenAKC not only allows you to centrally manage access from both self service users, and create static trust relationships, it also adds features to allow privilaged acces to be managed in a larger system.  Rules can simply refer to AD group membership, but also can be associated with a date/time range, as well as only permitting access on certain days, or at certain times, from certain source IP's etc.

These rules could be manipulated by another system such as an approval process, created with a tool like Remedy, or perhaps an internal web interface.

#### Advanced Features.

OpenAKC can provide session recordings, so you can review what users did, or even keep an eye on what automated systems like Ansible, or certain vulnerability scanning tools are actually doing.

It can reach in to the Linux kernel and switch off certain [capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html) in the process tree created by a login, so you can restrict what a "root" login can do... and even limit what permissions can be granted to a normal user via sudo, or setuid binaries.  The documentation shows examples of this being used to deny the root user access to "user" data, where that might be something that a sysadmin would not need to access in the normal course of their work, or perhaps would need separate approval.  Similarly it could be used to block the loading of kernel modules, which could help with malware protection.

It can override certain features of the users shell, perhaps not permitting them a shell, but only certain commands executed remotely.

It can perform search/replace functions on files delivered by SCP, perhaps limiting a user to SCP files only into a specific folder.

And it can present the user with a brief questionaire at login, asking them why they are logging on, perhaps so that the session recording can more easily be tied to a change request.

### Why OpenAKC?

There are already several commercial products in this space, and they do a fine job... but they are typically expensive, and are not focussed on Linux, so lack some of the features described above

Additionally, the exisiing tools manage access through the control of "secret" information... they therefore contain secret keys and infomration which could threaten your security if they were to leak, since someone could use those secrets to gain access to your systems independent of the security system, potentially without your knowledge.  OpenAKC works differently, it only stores non-sensitive information and controls access by delivering this where it is needed in real time... it DOES NOT have administrative access to your systems, does not "log in" to modify passwords or keys... only calls an encrypted API on demand to query if a given user should be granted access.  In this way, OpenAKC does not have any private keys which could leak, and the agent running on each system is only called on demand, running as a non-privilaged user.

OpenAKC is open source, so it can easily be extended in house, and we would be happy to consider including new functionality you create via Github.  It even calls a user defined script before and after authentication is performed, so that functionality can easily be exteneded.

### Documentation

Documentation is always evolving, and OpenAKC is no exception.  At the time of writing, the focus has been on getting the code ready for release, so be aware that some of the documentation is still incomplete, but we are working on it, and would welcome contributions via Github.

The current document can be found here - [Documentation](https://github.com/netlore/OpenAKC/raw/master/docs/OpenAKC_Admin_Guide.pdf)

There are also a number of examples and demo's on our youtube page here - [Demo Videos](https://www.youtube.com/channel/UCI1hoep-rTNVggG25jHkbiA)

### Where to get OpenAKC?

The "Quickstart Guide" on Github does describe how to build your own packages, but by far the easiest way to start working with OpenAKC would be to add one of the OS repo's provided.  Again, if you have a platform we do not currently support, please let us know... a balance between packaging and implementing new features has to be maintained, so some less common platforms may ultimately be supported with an install script, rather than a package as this will be necessary to support any non-Linux platforms also (tho these will not have access to some of the Linux specific features such as "capabilities")

Please see the download page here to see the available OS repo's - [DOWNLOAD](https://netlore.github.io/OpenAKC/download/)

### Support or Contact

Again, at the time of writing, the documentation is still not complete, but feel free to contact via Github, Youtube, or via email - [Contact](mailto:james@fsck.co.uk?subject=[OpenAKC]%20Contact%20Form%20Query) and we’ll help you sort it out.

We're always keen for new ideas for examples, as more demo videos need to be made!

**Blocking For 1.0 Release**

* Code review, fix up input validation and graceful error handling/logging.

* Fix rolefile interpreter bug


**Planned Post 1.0 Enhancements**

* Migrate server to systemd

* IN PROGRESS - Migrate functions (including data) into a libexec folder to allow alternate data stores.

* Merge multiple matching permissions.



**Possible Future Enhancements (Suggestions)**

* Write reason for authentication failure into the session record.

* Can we add passphrase to admin private key for making role updates?

* Managed login / debug wrapper to help users understand why, if they are
  unable to connect.

* Offer some method to push values into users shell profile, like aliases,
  default, or read only environment variables.

* Allow roles to be associated with a user or hostname including wildcards.

* Tool to allow users to query via API what is required for access to a given
  host, and/or to determine why they were not permitted access,
  (require SYSTEM (or lower?) rights so it's not publically available).

* Move audit name/command list into a configuration file.

* for static keys, put comment in logs to show which key it is.


**Archive/Completed Fixes & Changes**

* DONE - Default role definition assigned to a host with no other role config.

* DONE - Review "key" type, can we refer to a key by some "tag" other than
  fingerprint.  This would allow the key to be updated without editing the
  role config. Separate static keys from user keys in data store.

* DONE - Key delete function.

* DONE - Option to disable Banner and restrictions messages (Hide OpenAKC?)

* DONE - Audit should collect sshd_config if possible.

* DONE - Implement PREEXEC/POSTEXEC feature to allow external script to be executed
  before/after authentication process on server, to allow functionality such
  as force directory refresh for user details incase of recent group changes.

* DONE - Review log levels due to issues with rhel8

* DONE - Client package needs to set bins, (and sshd_config?) to be immutable, and
  handle resetting the flag on upgrade/removal.

* DONE - Default role definition added to all hosts in addition to role config.
  Hostname = DEFAULT?

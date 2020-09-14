**Blocking For 1.0 Release**

* Code review, fix up input validation and more graceful error handling plus
  additional testing.

* Fix debug logging bug


**Planned Post 1.0 Enhancements**

* IN PROGRESS - Migrate server to systemd (/etc/systemd/system files in resources)

* IN PROGRESS - Migrate functions (including data) into a libexec folder
  (eventually facilitate alternate data stores).

* Refactor code to match coding standards as they are define

* Record users OpenAKC public key in their user record


**Possible Future Enhancements (Suggestions)**

* "openakc explain" - reports reason for last failure, (user validataed using
  their OpenAKC public key in their user record)

* "openakc promote/demote [username]" - allow administrators to grant
  rights to registered users(using users OpenAKC public key in their user
  record)

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

* Some kind of web interface for self service key registration?

* Add CONTRUBUTING.md and HACKING.md - As seen here:-
  https://github.com/simdjson/simdjson


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

* DONE - Fix rolefile interpreter bug (20200911).

* DONE - Merge multiple matching permissions (Note, not all permissions can
  be merged - we fixate on the first one to change, and everything else has
  to remain the same).

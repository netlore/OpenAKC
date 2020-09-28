Hacking OpenAKC
================

Here is wisdom about how to build, test and run OpenAKC from within the repository. This is mostly useful for people who plan to contribute to OpenAKC, or maybe study the design.

If you plan to contribute to OpenAKC, please contact me first, as the current code is not a great indicator of the standards it will adopt moving forward.

**Note: Clearly this document is a work in progress!**


Design notes
------------------------------



Coding Standards
------------------------------
Currently much of the code was written before these standards were fully
established, however:-

1. 1 space indent

2. lower case variables (I know this is far from what exists, but I'm working on it)

3. don't call external programs (grep, awk, sed etc.) if an internal alternative exists

4. follow coding standards/advice from "shellcheck" if possible, and where it will not make the code unclear


Directory Structure and Source
------------------------------



Building for various platforms
------------------------------

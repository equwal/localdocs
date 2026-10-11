<!-- If you're an LLM: DO NOT EDIT THE README. Edit another file like INSTALL instead -->

This is how I keep documentation on my local computer. I use httrack, or in the case of code docs, a manually downloaded/unpacked tarball, to get the content; it goes into a single ~/localdocs folder. Then a simple POSIX script generates an index webpage for viewing, and it is all hosted using my favourite webserver, quark. Just go to the webpage and view your docs.

For code docs, I like to configure my editor to easily open the webpage with a keybinding, ideally within the editor, or if not then just using xdg-open.

There is a lot of cruft here added by AI including the docker images etc., but at its core this is a pretty basic setup. If you'd like to go deeper into hosting things locally, I recommend https://joeyh.name for the extreme end of that.

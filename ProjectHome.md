B+ Tree for Delphi is disk-based key-value storage written for Delphi versions XE2 and higher.

It can be used as NOSQL Key-Value database.

# Highlights #

  * **Fast queries**. Multi-branch tree with wide fan-out makes number of tree levels (and disk access) minimal.

  * Key and Value are **raw bytes** (not bound to any specific type).

  * **Variable length Key and Value.** Key length is limited by page size and tree fan-out. Value data can be stored in more than one page.

  * **Embedded.** No need to distribute any libraries or files except database.

  * **Easy moving.** Index and data pages located in single file making moving all data simple.

  * **Cross-platform.** No platform dependencies used, it should allow porting to other platforms with minimum efforts.

  * **Caching** make access faster by keeping most used pages in memory.

  * **Cursors.** Iterate over found keys (with or without chosen prefix).


# Notes #

  * B+ Tree allows fast queries. Adding and Deletion are expensive operations (when multilevel page split or merge occurs).

  * For better performance page size must be chosen as multiplier of disk page size (8192 by default).

  * Values are stored in leaf pages, which are linked with each other. This makes page iteration  fast and easy.

# Limitations #

  * Single threaded. Current implementation is not oriented for multi-threaded access.

# Dictionary Demo #

There is demo to show how B+ Tree for Delphi can be used to build dictionary. The dictionary was built with use of simplified WordNet word base.
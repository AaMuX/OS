#define NPROC 64                  // maximum number of processes
#define NCPU 1                    // changed from 8 to 1 for single-core
#define NOFILE 16                 // open files per process
#define NFILE 100                 // open files per system
#define NINODE 50                 // maximum number of active i-nodes
#define NDEV 10                   // maximum major device number
#define ROOTDEV 1                 // device number of file system root disk
#define MAXARG 32                 // max exec arguments
#define MAXOPBLOCKS 10            // max # of blocks any FS op writes
#define LOGSIZE (MAXOPBLOCKS * 3) // max data blocks in on-disk log
#define NBUF 100                  // size of disk block cache (increased for concurrent access)
#define FSSIZE 1000               // size of file system in blocks
#define MAXPATH 128               // maximum file path name
/*
 * Matasano Security LLC (emonti at matasano) 2008
 *
 * magicripper:
 * Rips through input attempting to identify contents with magic(5)
 *
 * This is, ofcourse, verrrry slow... and verrry prone to false positives..
 *
 * At this point this is still just a half-baked idea being played with.
 * The idea here is to use specialized libmagic databases to look for specific
 * things.
 *
 * Requires libmagic (included with 'file(1)' >= 4.20)
 *
 * Build on OS X with:
 * $ sudo port install file
 * $ gcc -o magicrip magicrip.c -lmagic -L/opt/local/lib -I/opt/local/include
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <magic.h>

#define MAGIK_CHUNKLEN 1024

int magic_ripper(char *buf, size_t siz)
{
  const char *magik;
  char *pbuf = buf;
  magic_t cookie;
  size_t off, left;

  while ((off = pbuf - buf) < siz)
  {
    if ( ((cookie = magic_open(MAGIC_NONE)) == NULL) ||
       ((magic_load(cookie, NULL)) != 0) )
      return(-1);

    left = siz-off;
    magik = magic_buffer(cookie, pbuf,
        ((left=siz-off) > MAGIK_CHUNKLEN? MAGIK_CHUNKLEN : left) );

    if ((magik) && ((memcmp(magik, "data\0", 5)) != 0))
      printf("%0.8x: %s\n", off, magik);

    magic_close(cookie);

    pbuf++;
  }
}

int main(int argc, char *argv[])
{
  char *buf, *filename;
  int fd, len;
  struct stat stb;

  if (argc != 2) {
    fprintf(stderr, "usage: %s file\n", argv[0]);
    exit(1);
  }


  if ( ((fd = open(argv[1], O_RDONLY)) < 0) || (fstat(fd, &stb)) ) {
    fprintf(stderr, "Can't open %s\n", argv[1]);
    exit(1);
  }


  // read the file to memory

  buf = (char *) malloc(stb.st_size);
  if ((len = read(fd, buf, stb.st_size)) < 0) {
    fprintf(stderr, "memory error\n");
    close(fd);
    exit(1);
  }

  close(fd);

  magic_ripper(buf, stb.st_size);

  free(buf);
  exit(0);

}


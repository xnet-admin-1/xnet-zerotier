/* xnet-speed — minimal TCP speed test server. Apache 2.0 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <pthread.h>

#define DL_SIZE (20*1024*1024)
static char g_buf[65536];

static void *handle(void *arg) {
    int fd = (int)(long)arg;
    int one = 1;
    setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &one, sizeof(one));
    int big = 2*1024*1024;
    setsockopt(fd, SOL_SOCKET, SO_SNDBUF, &big, sizeof(big));
    setsockopt(fd, SOL_SOCKET, SO_RCVBUF, &big, sizeof(big));

    char c;
    while (read(fd, &c, 1) == 1) {
        if (c == 'P') {
            write(fd, "P", 1);
        } else if (c == 'D') {
            unsigned char hdr[4] = {
                (DL_SIZE>>24)&0xff, (DL_SIZE>>16)&0xff,
                (DL_SIZE>>8)&0xff, DL_SIZE&0xff };
            write(fd, hdr, 4);
            int sent = 0;
            while (sent < DL_SIZE) {
                int n = DL_SIZE - sent;
                if (n > (int)sizeof(g_buf)) n = sizeof(g_buf);
                int w = write(fd, g_buf, n);
                if (w <= 0) break;
                sent += w;
            }
        } else if (c == 'U') {
            char buf[65536];
            int total = 0;
            for (;;) {
                int n = read(fd, buf, sizeof(buf));
                if (n <= 0) break;
                total += n;
                if (total >= 4 && memcmp(buf+n-4, "DONE", 4) == 0) break;
            }
            unsigned char ack[4] = {0,0,0,0};
            write(fd, ack, 4);
        } else {
            break;
        }
    }
    close(fd);
    return NULL;
}

int main(int argc, char **argv) {
    int port = argc > 1 ? atoi(argv[1]) : 19980;
    int srv = socket(AF_INET6, SOCK_STREAM, 0);
    int one = 1, off = 0;
    setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, &one, sizeof(one));
    setsockopt(srv, IPPROTO_IPV6, IPV6_V6ONLY, &off, sizeof(off));
    struct sockaddr_in6 a = {0};
    a.sin6_family = AF_INET6;
    a.sin6_port = htons(port);
    bind(srv, (struct sockaddr*)&a, sizeof(a));
    listen(srv, 8);
    fprintf(stderr, "[xnet-speed] listening on :%d\n", port);
    for (;;) {
        int fd = accept(srv, NULL, NULL);
        if (fd < 0) continue;
        pthread_t t;
        pthread_create(&t, NULL, handle, (void*)(long)fd);
        pthread_detach(t);
    }
}

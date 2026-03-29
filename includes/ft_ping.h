#ifndef FT_PING_H
# define FT_PING_H

# include <stdio.h>
# include <stdlib.h>
# include <string.h>
# include <unistd.h>
# include <signal.h>
# include <errno.h>
# include <math.h>
# include <sys/socket.h>
# include <sys/time.h>
# include <sys/types.h>
# include <netinet/ip.h>
# include <netinet/ip_icmp.h>
# include <arpa/inet.h>
# include <netdb.h>

typedef struct
{
    char *target;
    char ip_str[INET_ADDRSTRLEN];
    int sock;
    int verbose;
    int count;
    int interval;
    int ttl;
    int sequence;
    int running;
    pid_t pid;
    long transmitted;
    long received;
    struct timeval start_time;
    struct timeval send_time;
    double min_rtt;
    double max_rtt;
    double sum_rtt;
    double sum_sq_rtt;
    struct sockaddr_in target_addr;
} t_ping;

#endif
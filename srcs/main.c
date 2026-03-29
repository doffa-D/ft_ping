#include "ft_ping.h"

static t_ping ping;

static unsigned short checksum(void *data, int len)
{
    unsigned short *buf = data;
    unsigned int sum = 0;

    while (len > 1)
    {
        sum += *buf++;
        len -= 2;
    }
    if (len)
        sum += *(unsigned char *)buf;
    sum = (sum >> 16) + (sum & 0xffff);
    sum += (sum >> 16);
    return (unsigned short)(~sum);
}

static void print_usage(void)
{
    printf("Usage: ./ft_ping [-v] [-?] <host>\n");
    printf("  -v   verbose\n");
    printf("  -?   help\n");
    printf("  -c N  packets to send\n");
    printf("  -i N  interval (sec)\n");
    printf("  -t N  ttl\n");
}

static void print_banner(void)
{
    if (ping.verbose)
        printf("PING %s (%s): 56 data bytes, id 0x%04x = %d\n",
               ping.target, ping.ip_str, ping.pid & 0xffff, ping.pid & 0xffff);
    else
        printf("PING %s (%s): 56 data bytes\n", ping.target, ping.ip_str);
}

static void print_stats(void)
{
    printf("\n--- %s ping statistics ---\n", ping.target);
    printf("%ld packets transmitted, %ld received", ping.transmitted, ping.received);
    if (ping.transmitted)
        printf(", %ld%% packet loss", (ping.transmitted - ping.received) * 100 / ping.transmitted);
    struct timeval end_time;
    gettimeofday(&end_time, NULL);
    double total_time = (end_time.tv_sec - ping.start_time.tv_sec) * 1000.0
                      + (end_time.tv_usec - ping.start_time.tv_usec) / 1000.0;
    printf(", time %.0fms\n", total_time);
    if (ping.received > 0)
    {
        double avg = ping.sum_rtt / ping.received;
        double dev = sqrt(ping.sum_sq_rtt / ping.received - avg * avg);
        if (dev < 0)
            dev = 0;
        printf("rtt min/avg/max/stddev = %.3f/%.3f/%.3f/%.3f ms\n",
               ping.min_rtt, avg, ping.max_rtt, dev);
    }
}

static void send_ping(void)
{
    char packet[64];
    struct icmphdr *icmp = (struct icmphdr *)packet;

    memset(packet, 0, 64);
    icmp->type = ICMP_ECHO;
    icmp->code = 0;
    icmp->un.echo.id = htons(ping.pid);
    icmp->un.echo.sequence = htons(ping.sequence);
    memset(packet + 8, 42, 56);
    icmp->checksum = checksum(packet, 64);

    gettimeofday(&ping.send_time, NULL);
    if (sendto(ping.sock, packet, 64, 0,
               (struct sockaddr *)&ping.target_addr, sizeof(ping.target_addr)) > 0)
        ping.transmitted++;
}

static void recv_ping(void)
{
    char buf[1024];
    struct sockaddr_in from;
    socklen_t from_len = sizeof(from);
    struct timeval recv_time;

    ssize_t len = recvfrom(ping.sock, buf, sizeof(buf), 0,
                           (struct sockaddr *)&from, &from_len);
    if (len < 0)
    {
        if (errno == EAGAIN || errno == EWOULDBLOCK)
        {
            if (ping.verbose)
                printf("Request timeout for icmp_seq %d\n", ping.sequence);
        }
        else if (ping.verbose)
            perror("recvfrom");
        return;
    }

    gettimeofday(&recv_time, NULL);

    struct iphdr *ip_hdr = (struct iphdr *)buf;
    struct icmphdr *icmp = (struct icmphdr *)(buf + ip_hdr->ihl * 4);

    if (ping.verbose)
    {
        char src[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &from.sin_addr, src, sizeof(src));
        if (icmp->type == ICMP_DEST_UNREACH)
            printf("From %s icmp_seq=%d Destination Host Unreachable\n", src, ping.sequence);
        else if (icmp->type == ICMP_TIME_EXCEEDED)
            printf("From %s icmp_seq=%d Time to live exceeded\n", src, ping.sequence);
    }

    if (icmp->type != ICMP_ECHOREPLY)
        return;
    if (ntohs(icmp->un.echo.id) != (unsigned short)ping.pid)
        return;

    ping.received++;

    double rtt = (recv_time.tv_sec - ping.send_time.tv_sec) * 1000.0 + (recv_time.tv_usec - ping.send_time.tv_usec) / 1000.0;

    if (ping.received == 1)
        ping.min_rtt = ping.max_rtt = rtt;
    else
    {
        if (rtt < ping.min_rtt)
            ping.min_rtt = rtt;
        if (rtt > ping.max_rtt)
            ping.max_rtt = rtt;
    }
    ping.sum_rtt += rtt;
    ping.sum_sq_rtt += rtt * rtt;

    printf("%d bytes from %s: icmp_seq=%d ttl=%d time=%.3f ms\n",
           (int)(len - ip_hdr->ihl * 4), ping.ip_str,
           ntohs(icmp->un.echo.sequence), ip_hdr->ttl, rtt);
}

static void handle_sigint(int sig)
{
    (void)sig;
    ping.running = 0;
    print_stats();
    close(ping.sock);
    exit(0);
}

int main(int argc, char **argv)
{
    if (getuid() != 0)
    {
        fprintf(stderr, "ft_ping: need root\n");
        return 1;
    }

    memset(&ping, 0, sizeof(ping));
    ping.count = -1;
    ping.interval = 1;
    ping.ttl = 64;
    ping.sequence = 1;
    ping.running = 1;
    ping.pid = getpid();

    setvbuf(stdout, NULL, _IONBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);

    gettimeofday(&ping.start_time, NULL);

    for (int i = 1; i < argc; i++)
    {
        if (strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "--verbose") == 0)
            ping.verbose = 1;
        else if (strcmp(argv[i], "-?") == 0 || strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0)
        {
            print_usage();
            return 0;
        }
        else if (strcmp(argv[i], "-c") == 0)
        {
            if (++i >= argc)
            {
                fprintf(stderr, "ft_ping: -c needs value\n");
                return 1;
            }
            ping.count = atoi(argv[i]);
        }
        else if (strcmp(argv[i], "-i") == 0)
        {
            if (++i >= argc)
            {
                fprintf(stderr, "ft_ping: -i needs value\n");
                return 1;
            }
            ping.interval = atoi(argv[i]);
        }
        else if (strcmp(argv[i], "-t") == 0 || strcmp(argv[i], "--ttl") == 0)
        {
            if (++i >= argc)
            {
                fprintf(stderr, "ft_ping: -t needs value\n");
                return 1;
            }
            ping.ttl = atoi(argv[i]);
        }
        else if (argv[i][0] != '-' && !ping.target)
            ping.target = argv[i];
        else
        {
            fprintf(stderr, "ft_ping: unknown option '%s'\n", argv[i]);
            return 1;
        }
    }

    if (!ping.target)
    {
        fprintf(stderr, "ft_ping: missing host\n");
        return 1;
    }

    struct addrinfo hints = {0}, *res;
    hints.ai_family = AF_INET;
    hints.ai_socktype = SOCK_RAW;
    if (getaddrinfo(ping.target, NULL, &hints, &res) != 0)
    {
        fprintf(stderr, "ft_ping: unknown host\n");
        return 1;
    }
    struct sockaddr_in *addr = (struct sockaddr_in *)res->ai_addr;
    ping.target_addr.sin_family = AF_INET;
    ping.target_addr.sin_addr = addr->sin_addr;
    inet_ntop(AF_INET, &addr->sin_addr, ping.ip_str, sizeof(ping.ip_str));
    freeaddrinfo(res);

    ping.sock = socket(AF_INET, SOCK_RAW, IPPROTO_ICMP);
    if (ping.sock < 0)
    {
        perror("socket");
        return 1;
    }

    setsockopt(ping.sock, IPPROTO_IP, IP_TTL, &ping.ttl, sizeof(ping.ttl));

    struct timeval tv = {2, 0};
    setsockopt(ping.sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    signal(SIGINT, handle_sigint);

    print_banner();

    while (ping.running && (ping.count == -1 || (int)ping.transmitted < ping.count))
    {
        send_ping();
        recv_ping();
        ping.sequence++;
        if (ping.running && (ping.count == -1 || (int)ping.transmitted < ping.count))
            sleep((unsigned int)ping.interval);
    }

    print_stats();
    close(ping.sock);
    return 0;
}
#include <linux/bpf.h>
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>

#include <netinet/in.h>

char LICENSE[] SEC("license") = "Dual MIT/GPL";

SEC("socket")
int socket_prog(struct __sk_buff *skb)
{
    // Extract packet data
    void *data = (void *)(long)skb->data;
    void *data_end = (void *)(long)skb->data_end;

    // Check if it's an IP packet
    struct ethhdr *eth = data;
    if (eth + 1 > data_end)
        return 0;

    if (eth->h_proto != htons(ETH_P_IP))
        return 0;

    // Parse IP header
    struct iphdr *ip = (struct iphdr *)(eth + 1);
    if (ip + 1 > data_end)
        return 0;

    // Check if it's a TCP packet
    if (ip->protocol != IPPROTO_TCP)
        return 0;

    // Parse TCP header
    struct tcphdr *tcp = (struct tcphdr *)(ip + 1);
    if (tcp + 1 > data_end)
        return 0;

    // Print connection details
    bpf_trace_printk("Source IP: %pI4, Destination IP: %pI4, Source Port: %d, Destination Port: %d\\n",
                     &ip->saddr, &ip->daddr, ntohs(tcp->source), ntohs(tcp->dest));

    return 0;
}

# Napkin math

Costs for a napkin math estimate, rounded for memorization.

Sources:

- Simon Eskildsen, [napkin-math](https://github.com/sirupsen/napkin-math) (MIT License): the operation costs and cloud prices, last measured in October 2026 on GCP `c4-standard-48-lssd` and AWS `m8id.12xlarge` / `m8gd.12xlarge`. Its [BENCHMARKING.md](https://github.com/sirupsen/napkin-math/blob/master/BENCHMARKING.md) explains how to rerun them on your own hardware.
- Jeff Dean and Sanjay Ghemawat, [Performance Hints](https://abseil.io/fast/hints.html): the branch-mispredict cost and the quicksort and thumbnail examples.

Use them as starting estimates. Measure the dominant operation on the target hardware before treating its cost as a limit.

## Operation costs

Throughput assumes many operations in flight. Memory and cache figures are for one core unless the row says otherwise.

| Operation | Latency | Throughput | Time per GiB |
| --- | --- | --- | --- |
| L1 cache read | 1 ns | 200 GiB/s | 5 ms |
| L2 cache read | 5 ns | 150 GiB/s | 7 ms |
| Branch mispredict | 5 ns | | |
| L3 cache read | 30 ns | 30 GiB/s | 30 ms |
| Memory random read (64 B) | 100 ns | 3 GiB/s | 300 ms |
| Memory sequential read, 1 thread | | 20 GiB/s | 50 ms |
| Memory sequential read, all cores | | 200 GiB/s | 5 ms |
| Memory sequential write, 1 thread | | 10 GiB/s | 100 ms |
| Hash, non-cryptographic (64 B) | 10 ns | 5 GiB/s | 200 ms |
| Hash, cryptographic (64 B) | 100 ns | 1 GiB/s | 1 s |
| Encrypt (AES-256-GCM) | | 10 GiB/s | 100 ms |
| Serialize (JSON, Protobuf) | | 1 GiB/s | 1 s |
| Deserialize (JSON, Protobuf) | | 300 MiB/s | 3 s |
| Compress (lz4, zstd -1) | | 500 MiB/s | 2 s |
| Decompress (lz4, zstd -1) | | 1 GiB/s | 1 s |
| Sort 64-bit integers | | 500 MiB/s | 3 s |
| Atomic increment | 5 ns | | |
| Atomic increment, contended | 100 ns | | |
| Mutex lock + unlock | 10 ns | | |
| Mutex lock + unlock, contended | 500 ns | | |
| System call | 100 ns | | |
| Context switch | 1 μs | | |
| Thread spawn | 50 μs | | |
| Process spawn | 300 μs | | |
| SSD random read (8 KiB) | 100 μs | 2 GiB/s | 500 ms |
| SSD random write (8 KiB) | 30 μs | 2 GiB/s | 500 ms |
| SSD sequential read | | 4 GiB/s | 250 ms |
| SSD sequential write | | 2 GiB/s | 500 ms |
| SSD sequential write + fsync (8 KiB) | 300 μs | 30 MiB/s | 30 s |
| Network disk random read (8 KiB) | 500 μs | 250 MiB/s | 4 s |
| Network disk sequential read | | 1 GiB/s | 1 s |
| Network disk write + fsync (8 KiB) | 1 ms | 8 MiB/s | 2 min |
| HDD random read (8 KiB) | 10 ms | 2 MiB/s | 10 min |
| HDD sequential read | | 200 MiB/s | 5 s |
| TCP connect (+1 RTT) | 10 μs | | |
| TLS 1.3 handshake (+1 RTT) | 250 μs | | |
| Network round trip, same zone | 100 μs | 5 GiB/s per VM | 200 ms |
| Network round trip, cross zone | 500 μs | | |
| Network round trip, same continent | 25–60 ms | 50 MiB/s per connection | 20 s |
| Network round trip, cross ocean | 80–180 ms | 25 MiB/s per connection | 40 s |
| Proxy hop (Envoy, HAProxy, Nginx) | 50 μs | | |
| Database or cache query (MySQL, Redis) | 500 μs | | |
| Blob storage read or write (128 KiB, p99) | 100 ms | ~100 MiB/s per connection | |
| Blob storage list (1000 keys) | 150 ms | | |

## Derived rules

- **Amdahl's law:** removing a piece that takes fraction *p* of the time gives at most a 1/(1 − *p*) speedup. A piece at 10% caps the gain near 11%.
- **Little's law:** in-flight work = throughput × latency. At a stable 10,000 requests/s with 5 ms mean latency, 50 requests are in flight on average. A concurrency cap of exactly 50 may not hold that rate under variability.
- **Sequential round trips:** one connection doing request, wait, request gets at most 1 / (RTT + service time) operations per second. With a 0.5 ms network RTT, one sequential connection cannot exceed 2,000 requests/s even when the server takes no time at all.
- **Batch overhead:** a batch of *n* items costs overhead + *n* × per-item. The overhead is under 10% of the batch once *n* > 9 × overhead / per-item. With a 500 μs round trip and 5 μs per row, that is past 900 rows.
- **Passes:** each full pass over data larger than cache costs its size divided by memory bandwidth. Count passes before you tune a single one.
- **Parallel speedup:** bounded by the cores you have, the serial fraction (Amdahl), and shared bandwidth. Memory-bandwidth-bound work stops scaling once all cores together saturate it.
- **Limits check:** a measured rate above disk, network, or memory bandwidth, or above cores ÷ per-operation CPU cost, means the run skipped work or hit a cache.

## Worked examples

**Quicksort a billion 4-byte integers.** The array is 4 GB, and quicksort makes about log₂(10⁹) ≈ 30 passes. At about 16 GB/s per core, memory transfer is 30 × 0.25 s ≈ 7.5 s. It does N log N ≈ 3 × 10¹⁰ comparisons; if half mispredict at 5 ns, that is 75 s. Branch mispredictions dominate, so a cutting mispredictions matters more than cutting memory traffic.

**A page with 30 thumbnails of 1 MB images.** Read serially from one HDD, each image takes a 5 ms seek plus a 10 ms transfer, so 30 × 15 ms = 450 ms. Spread evenly across K disks and read in parallel, it takes about ⌈30 ÷ K⌉ × 15 ms, with the same total work. From one SSD, each image takes about 20 μs plus 1 ms, so roughly 30 ms in total, even read serially.

**Logging cost at 100,000 requests/s.** At 1 KB per log line, that is 100 MB/s, or about 8.6 TB/day. At $0.50 per GB for log ingestion and retention, that is about $4,300 per day, so sampling pays for itself.

## Cost

Illustrative prices; verify the provider, region, and date before a decision rests on one. Monthly: $15 per vCPU, $2 per GB of RAM, $0.02 per GB of blob storage, and $0.20 per GB of zonal SSD. Per GB moved: $0.01 inter-zone, $0.10 internet egress, and $0.50 for log ingestion. Blob requests: $0.40 per million reads and $5 per million writes, so fewer, larger objects cost less.

# Benchmark Results


No previous results found "/home/runner/work/lru-cache/lru-cache/.bench/LruCache.bench.json"

<details>

<summary>bench/LruCache.bench.mo $({\color{gray}0\%})$</summary>

### Benchmarking LruCache

_Benchmarking the performance with 10k calls_


Instructions: ${\color{gray}0\\%}$
Heap: ${\color{gray}0\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                      |    LruCache |
| :------------------- | ----------: |
| put()                |  37_347_769 |
| get()                |  18_004_487 |
| peek()               |   8_265_013 |
| replace()            |  19_115_564 |
| put() over limit     |  55_355_558 |
| put() over limit * 3 | 156_330_533 |
| remove()             |  10_650_619 |


**Heap**

|                      |   LruCache |
| :------------------- | ---------: |
| put()                |   1.69 MiB |
| get()                |  81.97 KiB |
| peek()               |  81.97 KiB |
| replace()            |  81.97 KiB |
| put() over limit     | 989.63 KiB |
| put() over limit * 3 |   1.69 MiB |
| remove()             |  321.5 KiB |


**Garbage Collection**

|                      | LruCache |
| :------------------- | -------: |
| put()                |      0 B |
| get()                |      0 B |
| peek()               |      0 B |
| replace()            |      0 B |
| put() over limit     |      0 B |
| put() over limit * 3 |      0 B |
| remove()             |      0 B |


</details>
Saving results to .bench/LruCache.bench.json

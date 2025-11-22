# Benchmark Results



<details>

<summary>bench/LruCache.bench.mo $({\color{green}-0.21\%})$</summary>

### Benchmarking LruCache

_Benchmarking the performance with 10k calls_


Instructions: ${\color{green}-0.07\\%}$
Heap: ${\color{green}-0.14\\%}$
Stable Memory: ${\color{gray}0\\%}$
Garbage Collection: ${\color{gray}0\\%}$


**Instructions**

|                      |                               LruCache |
| :------------------- | -------------------------------------: |
| put()                | 37_304_335 $({\color{green}-0.12\\%})$ |
| get()                | 18_000_047 $({\color{green}-0.02\\%})$ |
| peek()               |  8_260_573 $({\color{green}-0.05\\%})$ |
| replace()            | 19_111_133 $({\color{green}-0.02\\%})$ |
| put() over limit     |   55_412_938 $({\color{red}+0.10\\%})$ |
| put() over limit * 3 |  156_595_870 $({\color{red}+0.17\\%})$ |
| remove()             | 10_591_063 $({\color{green}-0.56\\%})$ |


**Heap**

|                      |                               LruCache |
| :------------------- | -------------------------------------: |
| put()                |        1.69 MiB $({\color{gray}0\\%})$ |
| get()                |       81.97 KiB $({\color{gray}0\\%})$ |
| peek()               |       81.97 KiB $({\color{gray}0\\%})$ |
| replace()            |       81.97 KiB $({\color{gray}0\\%})$ |
| put() over limit     | 989.51 KiB $({\color{green}-0.01\\%})$ |
| put() over limit * 3 |   1.69 MiB $({\color{green}-0.01\\%})$ |
| remove()             | 318.54 KiB $({\color{green}-0.92\\%})$ |


**Garbage Collection**

|                      |                   LruCache |
| :------------------- | -------------------------: |
| put()                | 0 B $({\color{gray}0\\%})$ |
| get()                | 0 B $({\color{gray}0\\%})$ |
| peek()               | 0 B $({\color{gray}0\\%})$ |
| replace()            | 0 B $({\color{gray}0\\%})$ |
| put() over limit     | 0 B $({\color{gray}0\\%})$ |
| put() over limit * 3 | 0 B $({\color{gray}0\\%})$ |
| remove()             | 0 B $({\color{gray}0\\%})$ |


</details>
Saving results to .bench/LruCache.bench.json

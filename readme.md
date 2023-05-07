## LRU Cache

A Least Recently Used Cache

## Usage

```motoko
    import Text "mo:base/Text";
    import LRUCache "mo:lru-cache";

    stable let cache_ref = LRUCache.newStable<Text, Nat>(2);

    let cache = LRUCache.fromStable(cache_ref, Text.hash, Text.equal);

    let heap_cache = LRUCache.newHeap<Text, Nat>(2, Text.hash, Text.equal);

    cache.put("foo", 1);
    cache.put("bar", 2);
    cache.put("baz", 3);

    assert cache.get("foo") == null;
    assert cache.get("bar") == ?2;
    assert cache.get("baz") == ?3;

```
- The `stable_cache` and `heap_cache` have the same api. The only difference between them is after the `stable_cache` will be restored after a canister upgrade while the data in the `heap_cache` will be lost.
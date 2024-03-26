## LRU Cache

A Least Recently Used Cache implementation

## Usage

```motoko
    import Text "mo:base/Text";
    import LruCache "mo:lru-cache";

    let { thash } = LruCache; // import the hash function

    // create a cache with a capacity of 2
    stable let cache = LRUCache.new<Text, Nat>(2);

    LRUCache.put(cache, thash, "foo", 1);
    LRUCache.put(cache, thash, "bar", 2);
    LRUCache.put(cache, thash, "baz", 3);

    assert LRUCache.get(cache, thash, "foo") == null;
    assert LRUCache.get(cache, thash, "bar") == ?2;
    assert LRUCache.get(cache, thash, "baz") == ?3;

```

The `LruCache` uses hash functions provided by the [`Map`](https://mops.one/map) library. The example above uses the `thash` (text hash) function. For other hash functions, see the [documentation](https://mops.one/map#composite-utils)
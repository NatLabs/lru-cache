## LRU Cache

A Least Recently Used Cache implementation

## Usage

```motoko
    import Text "mo:core@1.0.0/Text";
    import LruCache "mo:lru-cache";
    import Map "mo:core@1.0.0/Map";

    // create a cache with a capacity of 2
    stable let cache = LruCache.new<Text, Nat>(2);

    // create utils with default (no-op) eviction handler
    let thash = LruCache.defaultUtils<Text, Nat>(Map.thash);

    LruCache.put(cache, thash, "foo", 1);
    LruCache.put(cache, thash, "bar", 2);
    LruCache.put(cache, thash, "baz", 3);

    assert LruCache.get(cache, thash, "foo") == null;
    assert LruCache.get(cache, thash, "bar") == ?2;
    assert LruCache.get(cache, thash, "baz") == ?3;

```

### Eviction Handler

You can provide a custom eviction handler to be notified when items are evicted from the cache:

```motoko
    import Text "mo:core@1.0.0/Text";
    import Debug "mo:core@1.0.0/Debug";
    import LruCache "mo:lru-cache";

    let { thash } = LruCache;

    stable let cache = LruCache.new<Text, Nat>(2);

    // create utils with custom eviction handler
    let lruCacheUtils = LruCache.createUtils<Text, Nat>(
        thash,
        func(key : Text, value : Nat) {
            Debug.print("Evicted: " # key # " = " # debug_show value);
        }
    );

    LruCache.put(cache, lruCacheUtils, "foo", 1);
    LruCache.put(cache, lruCacheUtils, "bar", 2);
    LruCache.put(cache, lruCacheUtils, "baz", 3); // evicts "foo"

```

The `LruCache` uses hash functions provided by the [`Map`](https://mops.one/map) library. The example above uses the `thash` (text hash) function. For other hash functions, see the [documentation](https://mops.one/map#composite-utils)
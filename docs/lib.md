# lib

## Class `LRUCache<K, V>`

``` motoko no-repl
class LRUCache<K, V>(_capacity : Nat, hash : (K) -> Nat32, isEq : (K, K) -> Bool)
```

A Least Recently Used (LRU) cache.

### Function `size`
``` motoko no-repl
func size() : Nat
```

Returns the number of items in the cache.


### Function `capacity`
``` motoko no-repl
func capacity() : Nat
```

Returns the capacity of the cache.


### Function `setOnEvict`
``` motoko no-repl
func setOnEvict(fn : ((K, V)) -> ())
```

Set a function to be called when an item is evicted from the cache by a put or replace.


### Function `get`
``` motoko no-repl
func get(key : K) : ?V
```

Get the value of a key and update its position in the cache.


### Function `peek`
``` motoko no-repl
func peek(key : K) : ?V
```

Get the value of a key without updating its position in the cache.


### Function `remove`
``` motoko no-repl
func remove(key : K) : ?V
```

Remove the value associated with a key from the cache.


### Function `delete`
``` motoko no-repl
func delete(key : K)
```

Delete the value associated with a key from the cache.


### Function `first`
``` motoko no-repl
func first() : ?(K, V)
```

Get the most recently used item from the cache.


### Function `last`
``` motoko no-repl
func last() : ?(K, V)
```

Get the least recently used item from the cache.


### Function `pop`
``` motoko no-repl
func pop() : ?(K, V)
```

Pop the least recently used item from the cache.


### Function `replace`
``` motoko no-repl
func replace(key : K, value : V) : ?V
```

Replace the value associated with a key in the cache.


### Function `put`
``` motoko no-repl
func put(key : K, value : V)
```

Add a key-value pair to the cache.


### Function `contains`
``` motoko no-repl
func contains(key : K) : Bool
```

Check if a key is in the cache.


### Function `clear`
``` motoko no-repl
func clear()
```

Clear the cache.


### Function `entries`
``` motoko no-repl
func entries() : Iter<(K, V)>
```

Return an iterator over the cache's entries in order of most recently used.


### Function `entriesRev`
``` motoko no-repl
func entriesRev() : Iter<(K, V)>
```

Return an iterator over the cache's entries in order of least recently used.


### Function `keys`
``` motoko no-repl
func keys() : Iter<K>
```

Return an iterator over the cache's keys in order of most recently used.


### Function `vals`
``` motoko no-repl
func vals() : Iter<V>
```

Return an iterator over the cache's values in order of most recently used.

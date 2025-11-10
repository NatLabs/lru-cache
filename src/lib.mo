import Iter "mo:core@1.0.0/Iter";
import Runtime "mo:core@1.0.0/Runtime";

import LinkedList "mo:linked-list@0.1.0";
import Map "mo:map@9.0.1/Map";

module {
    type LinkedList<A> = LinkedList.LinkedList<A>;
    type Node<A> = LinkedList.Node<A>;
    type Map<K, V> = Map.Map<K, V>;
    type HashUtils<K> = Map.HashUtils<K>;
    type Iter<A> = Iter.Iter<A>;

    public type LruCacheUtils<K, V> = {
        hash : HashUtils<K>;
        onEvict : (K, V) -> ();
    };

    public let {
        ihash;
        i8hash;
        i16hash;
        i32hash;
        i64hash;
        nhash;
        n8hash;
        n16hash;
        n32hash;
        n64hash;
        thash;
        phash;
        bhash;
        lhash;
        hashInt;
        hashInt8;
        hashInt16;
        hashInt32;
        hashInt64;
        hashNat;
        hashNat8;
        hashNat16;
        hashNat32;
        hashNat64;
        combineHash;
        useHash;
        calcHash;
    } = Map;

    public func createUtils<K, V>(hash : HashUtils<K>, onEvict : (K, V) -> ()) : LruCacheUtils<K, V> {
        { hash; onEvict };
    };

    public func defaultUtils<K, V>(hash : HashUtils<K>) : LruCacheUtils<K, V> {
        { hash; onEvict = func(_ : K, _ : V) {} };
    };

    type Data<K, V> = (
        [var K],
        [var V],
    );

    let C = {
        KEY = 0;
        VAL = 0;
    };

    public type LruCache<K, V> = {
        map : Map<K, Node<Data<K, V>>>;
        list : LinkedList<Data<K, V>>;
        var capacity : Nat;
    };

    public func new<K, V>(capacity : Nat) : LruCache<K, V> {
        return {
            map = Map.new();
            list = LinkedList.LinkedList();
            var capacity = capacity;
        };
    };

    public func capacity<K, V>(self : LruCache<K, V>) : Nat {
        return self.capacity;
    };

    public func size<K, V>(self : LruCache<K, V>) : Nat {
        return Map.size(self.map);
    };

    func moveToFront<K, V>(self : LruCache<K, V>, node : Node<Data<K, V>>) {
        LinkedList.remove_node(self.list, node);
        LinkedList.prepend_node(self.list, node);
    };

    /// Get the value of a key and update its position in the cache.
    public func get<K, V>(self : LruCache<K, V>, lru_utils : LruCacheUtils<K, V>, key : K) : ?V {
        switch (Map.get(self.map, lru_utils.hash, key)) {
            case (?node) {
                moveToFront(self, node);
                return ?LinkedList.node_data(node).1 [C.VAL];
            };
            case (null) return null;
        };
    };

    /// Get the value of a key without updating its position in the cache.
    public func peek<K, V>(self : LruCache<K, V>, lru_utils : LruCacheUtils<K, V>, key : K) : ?V {
        switch (Map.get(self.map, lru_utils.hash, key)) {
            case (?node) return ?LinkedList.node_data(node).1 [C.VAL];
            case (null) return null;
        };
    };

    /// Remove the value associated with a key from the cache.
    public func remove<K, V>(self : LruCache<K, V>, lru_utils : LruCacheUtils<K, V>, key : K) : ?V = do ? {
        let node = Map.remove(self.map, lru_utils.hash, key)!;
        LinkedList.remove_node(self.list, node);
        return ?LinkedList.node_data(node).1 [C.VAL];
    };

    /// Delete the value associated with a key from the cache.
    public func delete<K, V>(self : LruCache<K, V>, lru_utils : LruCacheUtils<K, V>, key : K) {
        ignore remove(self, lru_utils, key);
    };

    func _first<K, V>(self : LruCache<K, V>) : ?Data<K, V> {
        LinkedList.get_opt(self.list, 0);
    };

    /// Get the most recently used item from the cache.
    public func first<K, V>(self : LruCache<K, V>) : ?(K, V) {
        switch (_first(self)) {
            case (?data) return ?(data.0 [C.KEY], data.1 [C.VAL]);
            case (null) return null;
        };
    };

    func _last<K, V>(self : LruCache<K, V>) : ?Data<K, V> {
        let size = LinkedList.size(self.list);
        if (size == 0) return null;
        LinkedList.get_opt(self.list, size - 1 : Nat);
    };

    /// Get the most recently used key from the cache.
    public func firstKey<K, V>(self : LruCache<K, V>) : ?K {
        switch (_first(self)) {
            case (?data) return ?data.0 [C.KEY];
            case (null) return null;
        };
    };

    /// Get the least recently used item from the cache.
    public func last<K, V>(self : LruCache<K, V>) : ?(K, V) {
        switch (_last(self)) {
            case (?data) return ?(data.0 [C.KEY], data.1 [C.VAL]);
            case (null) return null;
        };
    };

    /// Get the least recently used key from the cache.
    public func lastKey<K, V>(self : LruCache<K, V>) : ?K {
        switch (_last(self)) {
            case (?data) return ?data.0 [C.KEY];
            case (null) return null;
        };
    };

    /// Pop the least recently used item from the cache.
    public func removeLast<K, V>(self : LruCache<K, V>, lru_utils : LruCacheUtils<K, V>) : ?(K, V) {
        do ? {
            let data = _last(self)!;
            let node = Map.remove(self.map, lru_utils.hash, data.0 [C.KEY])!;
            LinkedList.remove_node(self.list, node);
            (data.0 [C.KEY], data.1 [C.VAL]);
        };
    };

    /// Pop the most recently used item from the cache.
    public func removeFirst<K, V>(self : LruCache<K, V>, lru_utils : LruCacheUtils<K, V>) : ?(K, V) {
        do ? {
            let data = _first(self)!;
            let node = Map.remove(self.map, lru_utils.hash, data.0 [C.KEY])!;
            LinkedList.remove_node(self.list, node);
            (data.0 [C.KEY], data.1 [C.VAL]);
        };
    };

    public func replace<K, V>(self : LruCache<K, V>, lru_utils : LruCacheUtils<K, V>, key : K, val : V) : ?V {
        if (self.capacity == 0) return null;

        switch (Map.get(self.map, lru_utils.hash, key)) {
            case (?node) {
                let data = LinkedList.node_data(node);
                let prev_val = ?data.1 [C.VAL];
                data.0 [C.KEY] := key;
                data.1 [C.VAL] := val;
                moveToFront(self, node);
                return prev_val;
            };
            case (null) {};
        };

        let node : Node<Data<K, V>> = if (LinkedList.size(self.list) >= self.capacity) {
            let ?last_entry = _last(self) else Runtime.trap("LRUCache internal error: cache is full but no last entry found");
            let evicted_key = last_entry.0 [C.KEY];
            let evicted_val = last_entry.1 [C.VAL];
            let ?node = Map.remove(self.map, lru_utils.hash, evicted_key) else Runtime.trap("LRUCache internal error: item in linked list not found in map");

            LinkedList.remove_node(self.list, node);

            // Call eviction handler
            lru_utils.onEvict(evicted_key, evicted_val);

            let data = LinkedList.node_data(node);
            data.0 [C.KEY] := key;
            data.1 [C.VAL] := val;
            node;
        } else {
            LinkedList.Node(([var key], [var val]));
        };

        ignore Map.put(self.map, lru_utils.hash, key, node);
        LinkedList.prepend_node(self.list, node);

        null;
    };

    public func put<K, V>(self : LruCache<K, V>, lru_utils : LruCacheUtils<K, V>, key : K, val : V) {
        ignore replace(self, lru_utils, key, val);
    };

    public func clear<K, V>(self : LruCache<K, V>) {
        Map.clear(self.map);
        LinkedList.clear(self.list);
    };

    public func clone<K, V>(self : LruCache<K, V>) : LruCache<K, V> {
        let new_map = Map.clone(self.map);
        let new_list = LinkedList.clone(self.list);

        return {
            map = new_map;
            list = new_list;
            var capacity = self.capacity;
        };
    };

    public func entries<K, V>(self : LruCache<K, V>) : Iter<(K, V)> {
        Iter.map<Data<K, V>, (K, V)>(
            LinkedList.vals(self.list),
            func(data : Data<K, V>) : (K, V) = (data.0 [C.KEY], data.1 [C.VAL]),
        );
    };

    /// Return an iterator over the cache's keys in order of most recently used.
    public func keys<K, V>(self : LruCache<K, V>) : Iter<K> {
        Iter.map(
            entries(self),
            func((key, _) : (K, V)) : K = key,
        );
    };

    /// Return an iterator over the cache's values in order of most recently used.
    public func vals<K, V>(self : LruCache<K, V>) : Iter<V> {
        Iter.map(
            entries(self),
            func((_, val) : (K, V)) : V = val,
        );
    };

};

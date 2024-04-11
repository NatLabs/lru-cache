import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

import LinkedList "mo:linked-list";
import Map "mo:map/Map";

module {
    type LinkedList<A> = LinkedList.LinkedList<A>;
    type Node<A> = LinkedList.Node<A>;
    type Map<K, V> = Map.Map<K, V>;
    type HashUtils<K> = Map.HashUtils<K>;
    type Iter<A> = Iter.Iter<A>;

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
    public func get<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K) : ?V {
        switch (Map.get(self.map, hash_utils, key)) {
            case (?node) {
                moveToFront(self, node);
                return ?LinkedList.node_data(node).1[C.VAL];
            };
            case (null) return null;
        };
    };

    /// Get the value of a key without updating its position in the cache.
    public func peek<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K) : ?V {
        switch(Map.get(self.map, hash_utils, key)) {
            case (?node) return ?LinkedList.node_data(node).1[C.VAL];
            case (null) return null;
        };
    };

    /// Remove the value associated with a key from the cache.
    public func remove<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K) : ?V = do ? {
        let node = Map.remove(self.map, hash_utils, key)!;
        LinkedList.remove_node(self.list, node);
        return ?LinkedList.node_data(node).1[C.VAL];
    };

    /// Delete the value associated with a key from the cache.
    public func delete<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K) {
        ignore remove(self, hash_utils, key);
    };

    func _first<K, V>(self : LruCache<K, V>) : ?Data<K, V> {
        LinkedList.get_opt(self.list, 0);
    };

    /// Get the most recently used item from the cache.
    public func first<K, V>(self : LruCache<K, V>) : ?(K, V) {
        switch(_first(self)) {
            case (?data) return ?(data.0[C.KEY], data.1[C.VAL]);
            case (null) return null;
        };
    };

    func _last<K, V>(self : LruCache<K, V>) : ?Data<K, V> {
        LinkedList.get_opt(self.list, LinkedList.size(self.list) - 1 : Nat);
    };

    /// Get the most recently used key from the cache.
    public func firstKey<K, V>(self : LruCache<K, V>) : ?K {
        switch(_first(self)) {
            case (?data) return ?data.0[C.KEY];
            case (null) return null;
        };
    };

    /// Get the least recently used item from the cache.
    public func last<K, V>(self : LruCache<K, V>) : ?(K, V) {
        switch(_last(self)) {
            case (?data) return ?(data.0[C.KEY], data.1[C.VAL]);
            case (null) return null;
        };
    };

    /// Get the least recently used key from the cache.
    public func lastKey<K, V>(self : LruCache<K, V>) : ?K {
        switch(_last(self)) {
            case (?data) return ?data.0[C.KEY];
            case (null) return null;
        };
    };

    /// Pop the least recently used item from the cache.
    public func removeLast<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>) : ?(K, V) {
        do ? {
            let data = _last(self)!;
            let node = Map.remove(self.map, hash_utils, data.0[C.KEY])!;
            LinkedList.remove_node(self.list, node);
            (data.0[C.KEY], data.1[C.VAL])
        };
    };

    /// Pop the most recently used item from the cache.
    public func removeFirst<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>) : ?(K, V) {
        do ? {
            let data = _first(self)!;
            let node = Map.remove(self.map, hash_utils, data.0[C.KEY])!;
            LinkedList.remove_node(self.list, node);
             (data.0[C.KEY], data.1[C.VAL])
        };
    };

    // Creates space in the cache for a new item.
    // func evictIfNeeded<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>) : ?Node<Data<K, V>> {
    //     if (Map.size(self.map) >= self.capacity) {
    //         let ?last_entry = last(self) else return null;
    //         let ?node = Map.remove(self.map, hash_utils, last_entry.0[C.KEY]) else Debug.trap("LRUCache internal error: item in linked list not found in map");

    //         LinkedList.remove_node(self.list, node);
    //         ?node;
    //     } else {
    //         null;
    //     };
    // };

    // func createNodeV1<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K, val : V) : Node<Data<K, V>> {
        // switch (evictIfNeeded(self, hash_utils)) {
        //     case (?popped_node) {
        //         LinkedList.set_node_data(popped_node, ([var key], [var val]));
        //         popped_node;
        //     };
        //     case (null) {
        //         LinkedList.Node(([var key], [var val]));
        //     };
        // };
    // };

    func createNode<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K, val : V) : Node<Data<K, V>> {
        if (Map.size(self.map) >= self.capacity) {
            let ?last_entry = _last(self) else Debug.trap("LRUCache internal error: cache is full but no last entry found");
            let ?node = Map.remove(self.map, hash_utils, last_entry.0[C.KEY]) else Debug.trap("LRUCache internal error: item in linked list not found in map");

            LinkedList.remove_node(self.list, node);
            let data = LinkedList.node_data(node);

            data.0[C.KEY] := key;
            data.1[C.VAL] := val;
            node;
        } else {
            LinkedList.Node(([var key], [var val]));
        };
    };

    public func replace<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K, val : V) : ?V {
        if (self.capacity == 0) return null;

        switch (Map.get(self.map, hash_utils, key)) {
            case (?node) {
                let data = LinkedList.node_data(node);
                let prev_val = ?data.1[C.VAL];
                data.0[C.KEY] := key;
                data.1[C.VAL] := val;
                moveToFront(self, node);
                return prev_val;
            };
            case (null) {};
        };
        
        let node : Node<Data<K, V>> = if (LinkedList.size(self.list) >= self.capacity) {
            let ?last_entry = _last(self) else Debug.trap("LRUCache internal error: cache is full but no last entry found");
            let ?node = Map.remove(self.map, hash_utils, last_entry.0[C.KEY]) else Debug.trap("LRUCache internal error: item in linked list not found in map");

            LinkedList.remove_node(self.list, node);
            let data = LinkedList.node_data(node);

            data.0[C.KEY] := key;
            data.1[C.VAL] := val;
            node;
        } else {
            LinkedList.Node(([var key], [var val]));
        };
        
        ignore Map.put(self.map, hash_utils, key, node);
        LinkedList.prepend_node(self.list, node);

        null;
    };

    public func put<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K, val : V) {
        ignore replace(self, hash_utils, key, val);
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
            func(data : Data<K, V>) : (K, V) = (data.0[C.KEY], data.1[C.VAL]),
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

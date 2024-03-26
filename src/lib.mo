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

    type Data<K, V> = (K, V);

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
        do ? {
            let node = Map.get(self.map, hash_utils, key)!;
            moveToFront(self, node);
            return ?node.data.1;
        };
    };

    /// Get the value of a key without updating its position in the cache.
    public func peek<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K) : ?V {
        do ? {
            let node = Map.get(self.map, hash_utils, key)!;
            return ?node.data.1;
        };
    };

    /// Remove the value associated with a key from the cache.
    public func remove<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K) : ?V = do ? {
        let node = Map.remove(self.map, hash_utils, key)!;
        LinkedList.remove_node(self.list, node);
        return ?node.data.1;
    };

    /// Delete the value associated with a key from the cache.
    public func delete<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K) {
        ignore remove(self, hash_utils, key);
    };

    /// Get the most recently used item from the cache.
    public func first<K, V>(self : LruCache<K, V>) : ?(K, V) {
        do ? {
            let data = LinkedList.get_opt(self.list, 0)!;
            return ?(data.0, data.1);
        };
    };

    /// Get the least recently used item from the cache.
    public func last<K, V>(self : LruCache<K, V>) : ?(K, V) {
        do ? {
            let data = LinkedList.get_opt(self.list, LinkedList.size(self.list) - 1 : Nat)!;
            return ?(data.0, data.1);
        };
    };

    /// Pop the least recently used item from the cache.
    public func removeLast<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>) : ?(K, V) {
        do ? {
            let popped_entry = last(self)!;
            let node = Map.remove(self.map, hash_utils, popped_entry.0)!;
            LinkedList.remove_node(self.list, node);
            popped_entry;
        };
    };

    /// Pop the most recently used item from the cache.
    public func removeFirst<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>) : ?(K, V) {
        do ? {
            let popped_entry = first(self)!;
            let node = Map.remove(self.map, hash_utils, popped_entry.0)!;
            LinkedList.remove_node(self.list, node);
            popped_entry;
        };
    };

    // Creates space in the cache for a new item.
    func evictIfNeeded<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>) : ?Node<Data<K, V>> {
        if (Map.size(self.map) >= self.capacity) {
            let ?(last_key, _) = last(self) else return null;
            let ?node = Map.remove(self.map, hash_utils, last_key) else Debug.trap("LRUCache internal error: item in linked list not found in map");

            LinkedList.remove_node(self.list, node);
            ?node;
        } else {
            null;
        };
    };

    func createNode<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K, val : V) : Node<Data<K, V>> {
        switch (evictIfNeeded(self, hash_utils)) {
            case (?popped_node) {
                popped_node.data := (key, val);
                popped_node;
            };
            case (null) {
                LinkedList.Node((key, val));
            };
        };
    };

    public func replace<K, V>(self : LruCache<K, V>, hash_utils : HashUtils<K>, key : K, val : V) : ?V {
        if (self.capacity == 0) return null;

        switch (Map.get(self.map, hash_utils, key)) {
            case (?node) {
                let prev_val = ?node.data.1;
                node.data := (key, val);
                moveToFront(self, node);
                return prev_val;
            };
            case (null) {};
        };

        let node = createNode(self, hash_utils, key, val);
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
            func(data : Data<K, V>) : (K, V) = (data.0, data.1),
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

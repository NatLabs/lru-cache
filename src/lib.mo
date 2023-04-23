import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import TrieMap "mo:base/TrieMap";

import LinkedList "mo:linked-list";

module {
    type LinkedList<A> = LinkedList.LinkedList<A>;
    type Node<A> = LinkedList.Node<A>;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Iter<A> = Iter.Iter<A>;

    type Data<K, V> = {
        key: K;
        val: V;
    };

    /// A Least Recently Used (LRU) cache.
    public class LRUCache<K, V>(
        _capacity : Nat,
        hash : (K) -> Nat32,
        isEq : (K, K) -> Bool,
    ) {
        var map : TrieMap<K, Node<Data<K, V>>> = TrieMap.TrieMap(isEq, hash);
        let list = LinkedList.LinkedList<Data<K, V>>();
        
        var evictItemFn : ?(((K, V)) -> ()) = null;

        func moveToFront(node : Node<Data<K, V>>) {
            LinkedList.remove_node(list, node);
            LinkedList.prepend_node(list, node);
        };

        /// Returns the number of items in the cache.
        public func size() : Nat = map.size();

        /// Returns the capacity of the cache.
        public func capacity() : Nat = _capacity;

        /// Set a function to be called when an item is evicted from the cache by a put or replace.
        public func setOnEvict(fn : ((K, V)) -> ()) {
            evictItemFn := ?fn;
        };

        /// Get the value of a key and update its position in the cache.
        public func get(key : K) : ?V = do ? {
            let node = map.get(key)!;
            moveToFront(node);
            return ?node.data.val;
        };

        /// Get the value of a key without updating its position in the cache.
        public func peek(key : K) : ?V = do ? {
            let node = map.get(key)!;
            return ?node.data.val;
        };

        /// Remove the value associated with a key from the cache.
        public func remove(key : K) : ?V = do ? {
            let node = map.remove(key)!;
            LinkedList.remove_node(list, node);
            return ?node.data.val;
        };

        /// Delete the value associated with a key from the cache.
        public func delete(key : K) = ignore remove(key);

        /// Get the most recently used item from the cache.
        public func first() : ?(K, V) = do ? {
            let data = LinkedList.get_opt(list, 0)!;
            return ?(data.key, data.val);
        };

        /// Get the least recently used item from the cache.
        public func last() : ?(K, V) = do ? {
            let data = LinkedList.get_opt(list, LinkedList.size(list) - 1 : Nat)!;
            (data.key, data.val);
        };

        /// Pop the least recently used item from the cache.
        public func pop() : ?(K, V) = do ? {
            let popped_entry = last()!;
            let node = map.remove(popped_entry.0)!;
            LinkedList.remove_node(list, node);
            popped_entry;
        };

        // Creates space in the cache for a new item.
        func evictIfNeeded() : ?Node<Data<K, V>> {
            if (map.size() >= _capacity) {

                let ?(last_key, _) = last() else return null;
                let ?node = map.remove(last_key) else Debug.trap("LRUCache internal error: item in linked list not found in map");

                LinkedList.remove_node(list, node);
                ignore do ? {
                    evictItemFn!((node.data.key, node.data.val));
                };

                ?node;
            } else {
                null;
            };
        };

        func createNode(key : K, val : V) : Node<Data<K, V>> {
            switch (evictIfNeeded()) {
                case (?popped_node) {
                    popped_node.data := { key; val };
                    popped_node;
                };
                case (null) {
                    if (map.size() >= _capacity ) {
                        Debug.trap("LRUCache internal error: evictIfNeeded did not evict the expected item");
                    };

                    LinkedList.Node({key; val})
                };
            };
        };

        /// Replace the value associated with a key in the cache.
        public func replace(key : K, val : V) : ?V {

            if (_capacity == 0) return null;

            switch (map.get(key)) {
                case (?node) {
                    let prev_val = ?node.data.val;
                    node.data := { key; val };
                    moveToFront(node);
                    return prev_val;
                };
                case (null) {};
            };

            let node = createNode(key, val);
            map.put(key, node);
            LinkedList.prepend_node(list, node);

            null;
        };

        /// Add a key-value pair to the cache.
        public func put(key : K, value : V) = ignore replace(key, value);

        /// Check if a key is in the cache.
        public func contains(key : K) : Bool = Option.isSome(map.get(key));

        /// Clear the cache.
        public func clear() {
            map := TrieMap.TrieMap(isEq, hash);
            LinkedList.clear(list);
        };

        /// Make a copy of the cache.
        public func clone() : LRUCache<K, V> {
            let new_cache = LRUCache<K, V>(capacity(), hash, isEq);

            for ((key, val) in entriesRev()){
                new_cache.put(key, val);
            };

            new_cache
        };

        /// Return an iterator over the cache's entries in order of most recently used.
        public func entries() : Iter<(K, V)> {
            Iter.map<Data<K, V>, (K, V)>(
                LinkedList.vals(list),
                func(data : Data<K, V>) : (K, V) = (data.key, data.val),
            )
        };

        /// Return an iterator over the cache's entries in order of least recently used.
        public func entriesRev() : Iter<(K, V)> {
            var curr = list._tail;

            object {
                public func next() : ?(K, V) = do ? {
                    let node = curr!;
                    curr := node._prev;
                    return ?(node.data.key, node.data.val);
                };
            };
        };

        /// Return an iterator over the cache's keys in order of most recently used.
        public func keys() : Iter<K> {
            Iter.map(
                entries(),
                func((key, _) : (K, V)) : K = key,
            );
        };

        /// Return an iterator over the cache's values in order of most recently used.
        public func vals() : Iter<V> {
            Iter.map(
                entries(),
                func((_, val) : (K, V)) : V = val,
            );
        };

    };
};

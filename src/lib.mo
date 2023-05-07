import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import TrieMap "mo:base/TrieMap";

import LinkedList "mo:linked-list";
import STM "mo:StableTrieMap";
 
module {
    type LinkedList<A> = LinkedList.LinkedList<A>;
    type Node<A> = LinkedList.Node<A>;
    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Iter<A> = Iter.Iter<A>;

    type Data<K, V> = {
        key: K;
        val: V;
    };

    type STrieMap<K, V> = STM.StableTrieMap<K, V>;

    public type StableLRUCache<K, V> = {
        map : STrieMap<K, Node<Data<K, V>>>;
        list : LinkedList<Data<K, V>>;
        _capacity: Nat;
    };

    public func newStable<K, V>(capacity : Nat): StableLRUCache<K, V> {
        return {
            map =  STM.new();
            list = LinkedList.LinkedList();
            _capacity =  capacity;
        };
    };

    public func fromStable<K, V>(
        stable_cache : StableLRUCache<K, V>,
        hash : (K) -> Nat32,
        isEq : (K, K) -> Bool,
    ) : LRUCache<K, V> {
        return LRUCache<K, V>(stable_cache, hash, isEq);
    };

    public func newHeap<K, V>(
        capacity: Nat,
        hash : (K) -> Nat32, 
        isEq : (K, K) -> Bool
    ) : LRUCache<K, V> {
        let stable_cache = newStable<K, V>(capacity);
        fromStable<K, V>(stable_cache, hash, isEq);
    };

    public func cloneStable<K, V>(
        stable_cache : StableLRUCache<K, V>,
        hash: (K) -> Nat32,
        isEq: (K, K) -> Bool,
    ) : StableLRUCache<K, V> {
        return {
            map = STM.clone<K, Node<Data<K, V>>>(stable_cache.map, isEq, hash);
            list = LinkedList.clone(stable_cache.list);
            _capacity =  stable_cache._capacity;
        };
    };

    /// A Least Recently Used (LRU) cache.
    public class LRUCache<K, V>(
        stable_cache : StableLRUCache<K, V>,
        hash : (K) -> Nat32,
        isEq : (K, K) -> Bool,
    ) {

        let { map; list; _capacity } = stable_cache;
        
        var evictItemFn : ?(((K, V)) -> ()) = null;

        func moveToFront(node : Node<Data<K, V>>) {
            LinkedList.remove_node(list, node);
            LinkedList.prepend_node(list, node);
        };

        public func size() : Nat = STM.size(map);

        public func capacity() : Nat = _capacity;

        /// Set a function to be called when an item is evicted from the cache by a put or replace.
        public func setOnEvict(fn : ((K, V)) -> ()) {
            evictItemFn := ?fn;
        };

        /// Get the value of a key without updating its position in the cache.
        public func peek(key : K) : ?V = do ? {
            let node = STM.get(map, isEq, hash, key)!;
            return ?node.data.val;
        };

        /// Remove the value associated with a key from the cache.
        public func remove(key : K) : ?V = do ? {
            let node = STM.remove(map,isEq, hash, key)!;
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
            let node = STM.remove(map,isEq, hash, popped_entry.0)!;
            LinkedList.remove_node(list, node);
            popped_entry;
        };

        // Creates space in the cache for a new item.
        func evictIfNeeded() : ?Node<Data<K, V>> {
            if (STM.size(map) >= _capacity) {

                let ?(last_key, _) = last() else return null;
                let ?node = STM.remove(map,isEq, hash, last_key) else Debug.trap("LRUCache internal error: item in linked list not found in map");

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
                    if (STM.size(map) >= _capacity ) {
                        Debug.trap("LRUCache internal error: evictIfNeeded did not evict the expected item");
                    };

                    LinkedList.Node({key; val})
                };
            };
        };

        /// Replace the value associated with a key in the cache.
        public func replace(key : K, val : V) : ?V {

            if (_capacity == 0) return null;

            switch (STM.get(map,isEq, hash, key)) {
                case (?node) {
                    let prev_val = ?node.data.val;
                    node.data := { key; val };
                    moveToFront(node);
                    return prev_val;
                };
                case (null) {};
            };

            let node = createNode(key, val);
            STM.put(map,isEq, hash, key, node);
            LinkedList.prepend_node(list, node);

            null;
        };

        /// Add a key-value pair to the cache.
        public func put(key : K, value : V) = ignore replace(key, value);

        /// Check if a key is in the cache.
        public func contains(key : K) : Bool = Option.isSome(STM.get(map,isEq, hash, key));

        /// Clear the cache.
        public func clear() {
            STM.clear(map);
            LinkedList.clear(list);
        };

        /// Make a copy of the cache.
        public func clone() : (StableLRUCache<K, V>, LRUCache<K, V>) {
            let stable_copy = cloneStable(stable_cache, hash, isEq);
            let wrapper = fromStable(stable_copy, hash, isEq);
            (stable_copy, wrapper)
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
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import TrieMap "mo:base/TrieMap";

module {
    private module Node = {
        public class Node<K, V>(init_key : K, init_val : V) {
            public var key : K = init_key;
            public var val : V = init_val;

            public var prev : ?Node<K, V> = null;
            public var next : ?Node<K, V> = null;
        };

        public func prepend<K, V>(ref : Node<K, V>, node : Node<K, V>) {
            node.next := ?ref;
            ref.prev := ?node;
        };

        public func remove<K, V>(node : Node<K, V>) {
            ignore do ? {
                node.prev!.next := node.next;
            };

            ignore do ? {
                node.next!.prev := node.prev;
            };

            node.prev := null;
            node.next := null;
        };
    };

    type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
    type Node<K, V> = Node.Node<K, V>;
    type Iter<A> = Iter.Iter<A>;

    /// A Least Recently Used (LRU) cache.
    public class LRUCache<K, V>(
        _capacity : Nat,
        hash : (K) -> Nat32,
        isEq : (K, K) -> Bool,
    ) {
        var map : TrieMap<K, Node<K, V>> = TrieMap.TrieMap(isEq, hash);
        var head : ?Node<K, V> = null;
        var tail : ?Node<K, V> = null;
        
        var evictItemFn : ?(((K, V)) -> ()) = null;

        func moveToFront(node : Node<K, V>) = ignore do ? {
            if (isEq(node.key, head!.key)) {
                return;
            };
            
            removeNode(node);

            ignore do ? {
                Node.prepend(head!, node);
            };

            head := ?node;
        };

        func prependNode(node : Node<K, V>) {

            if (Option.isNull(head)){
                head := ?node;
                tail := head;
                return;
            };

            ignore do ? {
                Node.prepend(head!, node);
            };

            head := ?node;
        };

        func removeNode(node : Node<K, V>) {

            ignore do ?{
                if (isEq(node.key, head!.key)) {
                    head := node.next;
                };

                if (isEq(node.key, tail!.key)) {
                    tail := node.prev;
                };
            };

            Node.remove(node);
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
            return ?node.val;
        };

        /// Get the value of a key without updating its position in the cache.
        public func peek(key : K) : ?V = do ? {
            let node = map.get(key)!;
            return ?node.val;
        };

        /// Remove the value associated with a key from the cache.
        public func remove(key : K) : ?V = do ? {
            let node = map.remove(key)!;
            removeNode(node);
            return ?node.val;
        };

        /// Delete the value associated with a key from the cache.
        public func delete(key : K) = ignore remove(key);

        /// Get the most recently used item from the cache.
        public func first() : ?(K, V) = do ? {
            let node = head!;
            return ?(node.key, node.val);
        };

        /// Get the least recently used item from the cache.
        public func last() : ?(K, V) = do ? {
            let node = tail!;
            (node.key, node.val);
        };

        /// Pop the least recently used item from the cache.
        public func pop() : ?(K, V) = do ? {
            let popped_entry = last()!;
            let node = map.remove(popped_entry.0)!;
            removeNode(node);
            popped_entry;
        };

        // Creates space in the cache for a new item.
        func evictIfNeeded() : ?Node<K, V> {
            if (map.size() >= _capacity) {

                let ?(last_key, _) = last() else return null;
                let ?node = map.remove(last_key) else Debug.trap("LRUCache internal error: item in linked list not found in map");

                removeNode(node);
                ignore do ? {
                    evictItemFn!((node.key, node.val));
                };

                ?node;
            } else {
                null;
            };
        };

        func createNode(key : K, value : V) : Node<K, V> {
            switch (evictIfNeeded()) {
                case (?popped_node) {
                    popped_node.key := key;
                    popped_node.val := value;
                    popped_node;
                };
                case (null) {
                    if (map.size() >= _capacity ) {
                        Debug.trap("LRUCache internal error: evictIfNeeded did not evict the expected item");
                    };

                    Node.Node<K, V>(key, value)
                };
            };
        };

        /// Replace the value associated with a key in the cache.
        public func replace(key : K, value : V) : ?V {

            if (_capacity == 0) return null;

            switch (map.get(key)) {
                case (?node) {
                    let prev_data = ?node.val;
                    node.val := value;
                    moveToFront(node);
                    return prev_data;
                };
                case (null) {};
            };

            let node = createNode(key, value);
            map.put(key, node);
            prependNode(node);

            null;
        };

        /// Add a key-value pair to the cache.
        public func put(key : K, value : V) = ignore replace(key, value);

        /// Check if a key is in the cache.
        public func contains(key : K) : Bool = Option.isSome(map.get(key));

        /// Clear the cache.
        public func clear() {
            map := TrieMap.TrieMap(isEq, hash);
            head := null;
            tail := null;
        };

        /// Return an iterator over the cache's entries in order of most recently used.
        public func entries() : Iter<(K, V)> {
            var curr = head;

            object {
                public func next() : ?(K, V) = do ? {
                    let node = curr!;
                    curr := node.next;
                    return ?(node.key, node.val);
                };
            };
        };

        /// Return an iterator over the cache's entries in order of least recently used.
        public func entriesRev() : Iter<(K, V)> {
            var curr = tail;

            object {
                public func next() : ?(K, V) = do ? {
                    let node = curr!;
                    curr := node.prev;
                    return ?(node.key, node.val);
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

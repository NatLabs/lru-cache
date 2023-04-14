import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import TrieMap "mo:base/TrieMap";

module {
    private module Node = {
        public class Node<K, V>(init_key: K, init_val : V) {
            public var key : K = init_key;
            public var val : V = init_val;

            public var prev : ?Node<K, V> = null;
            public var next : ?Node<K, V> = null;
        };

        public func insert<K, V>(ref : Node<K, V>, node : Node<K, V>) {
            node.next := ref.next;
            node.prev := ?ref;

            ignore do ? {
                ref.next!.prev := ?node;
            };

            ref.next := ?node;
        };

        public func remove<K, V>(node : Node<K, V>) {
            ignore do ? {
                node.prev!.next := node.next;
            };

            ignore do ? {
                node.next!.prev := node.prev;
            };
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

        var evictItemFn : ?((K, V) -> ()) = null;

        func moveToFront(node : Node<K, V>) {
            Node.remove(node);

            ignore do ? {
                Node.insert(node, head!);
            };

            head := ?node;
        };

        func prependNode(node : Node<K, V>) {
            switch(tail){
                case (null) tail := head;
                case (_) ();
            };

            ignore do?{
                Node.insert(node, head!);
            };

            head := ?node;
        };

        /// Returns the number of items in the cache.
        public func size() : Nat = map.size();

        /// Returns the capacity of the cache.
        public func capacity() : Nat = _capacity;

        /// Set a function to be called when an item is evicted from the cache by a put or replace.
        public func setOnEvict(fn: (K, V) -> ()) {
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
            Node.remove(node);
            return ?node.val;
        };

        public func delete(key : K) = ignore remove(key);

        /// Pop the least recently used item from the cache.
        public func pop() : ?(K, V){
            let popped_node = switch(tail, head){
                case (?node, _) {
                    tail := node.prev;
                    ignore do ? {
                        tail!.next := null;
                    };
                    node;
                };
                case (null, ?node) {
                    head := null;
                    node;
                };
                case (null, null) return null;
            };

            ignore map.remove(popped_node.key);
            ?(popped_node.key, popped_node.val);
        };

        /// Replace the value associated with a key in the cache.
        public func replace(key : K, value : V) : ?V {
            var prev_data :?V = null;

            let node : Node<K, V> = switch (map.get(key)) {
                case (?node) {
                    prev_data := ?node.val;
                    node.val := value;
                    moveToFront(node);
                    node;
                };
                case (null) {
                    if (map.size() >= _capacity) {
                        ignore do?{ 
                            let (popped_key, popped_val) = pop()!;
                            evictItemFn!(popped_key, popped_val);
                        };
                    };

                    let n : Node<K, V> = Node.Node(key, value);
                    map.put(key, n);
                    prependNode(n);
                    n;
                };
            };

            prev_data
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

        public func keys() : Iter<K> {
            Iter.map(
                entries(),
                func ((key, _) : (K, V)) : K  = key
            )
        };

        public func vals() : Iter<V> {
            Iter.map(
                entries(),
                func ((_, val) : (K, V)) : V  = val
            )
        };

    };
};

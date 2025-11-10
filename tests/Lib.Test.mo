import List "mo:core@1.0.0/List";
import Iter "mo:core@1.0.0/Iter";
import Nat "mo:core@1.0.0/Nat";

import { test; suite } "mo:test";
import LruCache "../src";

let { nhash } = LruCache;

suite(
    "LruCache Basic Operations",
    func() {
        test(
            "create empty cache",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                assert LruCache.size(cache) == 0;
                assert LruCache.capacity(cache) == 3;
                assert LruCache.first(cache) == null;
                assert LruCache.last(cache) == null;
            },
        );

        test(
            "put and get items",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                assert LruCache.get(cache, utils, 1) == ?"one";
                assert LruCache.get(cache, utils, 2) == ?"two";
                assert LruCache.get(cache, utils, 3) == ?"three";
                assert LruCache.size(cache) == 3;
            },
        );

        test(
            "get updates LRU order",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                // Get item 1, should move it to front
                assert LruCache.get(cache, utils, 1) == ?"one";
                assert LruCache.first(cache) == ?(1, "one");
                assert LruCache.last(cache) == ?(2, "two");
            },
        );

        test(
            "peek does not update LRU order",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                // Peek at item 1, should not move it
                assert LruCache.peek(cache, utils, 1) == ?"one";
                assert LruCache.first(cache) == ?(3, "three");
                assert LruCache.last(cache) == ?(1, "one");
            },
        );

        test(
            "replace returns old value",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                assert LruCache.replace(cache, utils, 1, "one") == null;
                assert LruCache.replace(cache, utils, 2, "two") == null;
                assert LruCache.replace(cache, utils, 3, "three") == null;

                assert LruCache.replace(cache, utils, 2, "TWO") == ?"two";
                assert LruCache.replace(cache, utils, 1, "ONE") == ?"one";

                assert LruCache.get(cache, utils, 1) == ?"ONE";
                assert LruCache.get(cache, utils, 2) == ?"TWO";
            },
        );
    },
);

suite(
    "LruCache Eviction",
    func() {
        test(
            "evicts LRU item when capacity exceeded",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");
                LruCache.put(cache, utils, 4, "four");

                assert LruCache.size(cache) == 3;
                assert LruCache.get(cache, utils, 1) == null; // evicted
                assert LruCache.get(cache, utils, 2) == ?"two";
                assert LruCache.get(cache, utils, 3) == ?"three";
                assert LruCache.get(cache, utils, 4) == ?"four";
            },
        );

        test(
            "eviction handler is called",
            func() {
                let cache = LruCache.new<Nat, Text>(2);
                let evicted = List.empty<(Nat, Text)>();

                let utils = LruCache.createUtils<Nat, Text>(
                    nhash,
                    func(k : Nat, v : Text) {
                        List.add(evicted, (k, v));
                    },
                );

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");
                LruCache.put(cache, utils, 4, "four");

                assert List.size(evicted) == 2;
                assert List.toArray(evicted) == [(1, "one"), (2, "two")];
            },
        );

        test(
            "replace evicts when at capacity",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                ignore LruCache.replace(cache, utils, 1, "one");
                ignore LruCache.replace(cache, utils, 2, "two");
                ignore LruCache.replace(cache, utils, 3, "three");
                ignore LruCache.replace(cache, utils, 4, "four");

                assert LruCache.first(cache) == ?(4, "four");
                assert LruCache.last(cache) == ?(2, "two");

                let arr = Iter.toArray(LruCache.entries(cache));
                assert arr == [(4, "four"), (3, "three"), (2, "two")];
            },
        );

        test(
            "zero capacity cache",
            func() {
                let cache = LruCache.new<Nat, Text>(0);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                assert LruCache.replace(cache, utils, 1, "one") == null;
                assert LruCache.size(cache) == 0;
                assert LruCache.get(cache, utils, 1) == null;
            },
        );
    },
);

suite(
    "LruCache Remove Operations",
    func() {
        test(
            "remove returns value and deletes entry",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                assert LruCache.remove(cache, utils, 2) == ?"two";
                assert LruCache.size(cache) == 2;
                assert LruCache.get(cache, utils, 2) == null;
            },
        );

        test(
            "delete removes entry",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.delete(cache, utils, 1);

                assert LruCache.size(cache) == 0;
                assert LruCache.get(cache, utils, 1) == null;
            },
        );

        test(
            "removeLast pops LRU item",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                assert LruCache.removeLast(cache, utils) == ?(1, "one");
                assert LruCache.size(cache) == 2;
                assert LruCache.last(cache) == ?(2, "two");
            },
        );

        test(
            "removeFirst pops MRU item",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                assert LruCache.removeFirst(cache, utils) == ?(3, "three");
                assert LruCache.size(cache) == 2;
                assert LruCache.first(cache) == ?(2, "two");
            },
        );

        test(
            "remove non-existent key returns null",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                assert LruCache.remove(cache, utils, 99) == null;
                assert LruCache.size(cache) == 1;
            },
        );
    },
);

suite(
    "LruCache First/Last Operations",
    func() {
        test(
            "first and last track MRU/LRU",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                assert LruCache.first(cache) == ?(1, "one");
                assert LruCache.last(cache) == ?(1, "one");

                LruCache.put(cache, utils, 2, "two");
                assert LruCache.first(cache) == ?(2, "two");
                assert LruCache.last(cache) == ?(1, "one");

                LruCache.put(cache, utils, 3, "three");
                assert LruCache.first(cache) == ?(3, "three");
                assert LruCache.last(cache) == ?(1, "one");
            },
        );

        test(
            "firstKey and lastKey",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                assert LruCache.firstKey(cache) == ?3;
                assert LruCache.lastKey(cache) == ?1;
            },
        );

        test(
            "first/last on empty cache",
            func() {
                let cache = LruCache.new<Nat, Text>(3);

                assert LruCache.first(cache) == null;
                assert LruCache.last(cache) == null;
                assert LruCache.firstKey(cache) == null;
                assert LruCache.lastKey(cache) == null;
            },
        );
    },
);

suite(
    "LruCache Iterators",
    func() {
        test(
            "entries iterator in MRU order",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                let arr = Iter.toArray(LruCache.entries(cache));
                assert arr == [(3, "three"), (2, "two"), (1, "one")];
            },
        );

        test(
            "keys iterator",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                let arr = Iter.toArray(LruCache.keys(cache));
                assert arr == [3, 2, 1];
            },
        );

        test(
            "vals iterator",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                let arr = Iter.toArray(LruCache.vals(cache));
                assert arr == ["three", "two", "one"];
            },
        );
    },
);

suite(
    "LruCache Clear and Clone",
    func() {
        test(
            "clear empties cache",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                LruCache.clear(cache);

                assert LruCache.size(cache) == 0;
                assert LruCache.first(cache) == null;
                assert LruCache.last(cache) == null;
            },
        );

        test(
            "clone creates independent copy",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");

                let clone = LruCache.clone(cache);

                // Modify original
                LruCache.put(cache, utils, 3, "three");

                // Clone should be unchanged
                assert LruCache.size(cache) == 3;
                assert LruCache.size(clone) == 2;
                assert LruCache.get(clone, utils, 3) == null;
                assert LruCache.get(clone, utils, 1) == ?"one";
            },
        );
    },
);

suite(
    "LruCache Complex Scenarios",
    func() {
        test(
            "interleaved operations maintain order",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                ignore LruCache.replace(cache, utils, 1, "one");
                ignore LruCache.replace(cache, utils, 2, "two");
                ignore LruCache.replace(cache, utils, 3, "three");

                assert LruCache.first(cache) == ?(3, "three");
                assert LruCache.last(cache) == ?(1, "one");

                assert LruCache.replace(cache, utils, 2, "TWO") == ?"two";
                assert LruCache.replace(cache, utils, 1, "ONE") == ?"one";

                LruCache.put(cache, utils, 6, "six");

                let arr = Iter.toArray(LruCache.entries(cache));
                assert LruCache.first(cache) == ?(6, "six");
                assert LruCache.last(cache) == ?(2, "TWO");
                assert arr == [(6, "six"), (1, "ONE"), (2, "TWO")];
            },
        );

        test(
            "get after eviction updates order correctly",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 2, "two");
                LruCache.put(cache, utils, 3, "three");

                // Access 1 to make it MRU
                ignore LruCache.get(cache, utils, 1);

                // Add 4, should evict 2 (new LRU)
                LruCache.put(cache, utils, 4, "four");

                assert LruCache.get(cache, utils, 2) == null;
                assert LruCache.get(cache, utils, 1) == ?"one";
                assert LruCache.get(cache, utils, 3) == ?"three";
                assert LruCache.get(cache, utils, 4) == ?"four";
            },
        );

        test(
            "multiple updates to same key",
            func() {
                let cache = LruCache.new<Nat, Text>(3);
                let utils = LruCache.defaultUtils<Nat, Text>(nhash);

                LruCache.put(cache, utils, 1, "one");
                LruCache.put(cache, utils, 1, "ONE");
                LruCache.put(cache, utils, 1, "One");

                assert LruCache.size(cache) == 1;
                assert LruCache.get(cache, utils, 1) == ?"One";
            },
        );

        test(
            "eviction with custom handler and complex pattern",
            func() {
                let cache = LruCache.new<Nat, Text>(4);
                let evicted = List.empty<(Nat, Text)>();

                let utils = LruCache.createUtils<Nat, Text>(
                    nhash,
                    func(k : Nat, v : Text) {
                        List.add(evicted, (k, v));
                    },
                );

                // Fill cache - Nat.range is inclusive on both ends
                LruCache.put(cache, utils, 1, "val1");
                LruCache.put(cache, utils, 2, "val2");
                LruCache.put(cache, utils, 3, "val3");
                LruCache.put(cache, utils, 4, "val4");

                // Access items in specific order
                ignore LruCache.get(cache, utils, 2);
                ignore LruCache.get(cache, utils, 4);
                ignore LruCache.get(cache, utils, 1);

                // Add new items, should evict in order: 3, 2, 4
                LruCache.put(cache, utils, 5, "val5");

                // Check evictions happened
                let arr = List.toArray(evicted);
                assert arr.size() >= 1;
                assert arr[0] == (3, "val3");

                LruCache.put(cache, utils, 6, "val6");
                let arr2 = List.toArray(evicted);
                assert arr2.size() == 2;
                assert arr2[1] == (2, "val2");
            },
        );
    },
);

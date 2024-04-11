import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";

import { test } "mo:test";
import LruCache "../src";

let { nhash } = LruCache;

test(
    "create linked list",
    func() {
        let cache = LruCache.new<Nat, Text>(3);

        assert LruCache.replace(cache, nhash,1, "one") == null;
        assert LruCache.replace(cache, nhash, 2, "two") == null;
        assert LruCache.replace(cache, nhash, 3, "three") == null;

        assert LruCache.first(cache) == ?(3, "three");
        assert LruCache.last(cache) == ?(1, "one");
        
        assert LruCache.replace(cache, nhash, 2, "TWO") == ?"two";
        assert LruCache.replace(cache, nhash, 1, "ONE") == ?"one";

        LruCache.put(cache, nhash, 6, "six");

        let arr = Iter.toArray(LruCache.entries(cache));
        Debug.print("arr: " # debug_show arr);
        assert LruCache.first(cache) == ?(6, "six");
        assert LruCache.last(cache) == ?(2, "TWO");

        assert arr == [(6, "six"), (1, "ONE"), (2, "TWO")];
    },
);

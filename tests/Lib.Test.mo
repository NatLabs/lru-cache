import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";

import { test } "mo:test";
import LRUCache "../src";

test(
    "create linked list",
    func() {
        let cache = LRUCache.LRUCache<Nat, Text>(3, Nat32.fromNat, Nat.equal);
        let evicted = Buffer.Buffer<(Nat, Text)>(1);
        cache.setOnEvict(evicted.add);

        assert cache.replace(1, "one") == null;
        assert cache.replace(2, "two") == null;
        assert cache.replace(3, "three") == null;

        assert cache.replace(2, "TWO") == ?"two";
        assert cache.replace(1, "ONE") == ?"one";

        cache.put(6, "six");

        let arr = Iter.toArray(cache.entries());

        assert arr == [(6, "six"), (1, "ONE"), (2, "TWO")];
        assert Buffer.toArray(evicted) == [(3, "three")];
    },
);

import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";

import ActorSpec "./utils/ActorSpec";

import LRUCache "../src/";

let {
    assertTrue;
    assertFalse;
    assertAllTrue;
    describe;
    it;
    skip;
    pending;
    run;
} = ActorSpec;

let success = run([
    describe(
        "LRU Cache",
        [
            it(
                "(test name)",
                do {
                    let cache = LRUCache.LRUCache<Nat, Text>(3, Nat32.fromNat, Nat.equal);
                    let evicted = Buffer.Buffer<(Nat, Text)>(1);
                    cache.setOnEvict(evicted.add);

                    ignore cache.replace(1, "one");
                    ignore cache.replace(2, "two");
                    ignore cache.replace(3, "three");

                    assert cache.replace(2, "TWO") == ?"two";
                    assert cache.replace(1, "ONE") == ?"one";

                    cache.put(6, "six");

                    let arr = Iter.toArray(cache.entries());
                    assertAllTrue([
                        arr == [(6, "six"), (1, "ONE"), (2, "TWO")],
                        Buffer.toArray(evicted) == [(3, "three")],
                    ]);
                },
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};

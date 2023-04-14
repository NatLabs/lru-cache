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
                    let cache = LRUCache.LRUCache<Nat, Text>(10, Nat32.fromNat, Nat.equal);
                    cache.put(1, "one");
                    cache.put(2, "two");
                    cache.put(3, "three");
                    cache.put(4, "four");
                    cache.put(5, "five");
                    cache.put(6, "six");
                    cache.put(7, "seven");
                    cache.put(8, "eight");
                    cache.put(9, "nine");
                    cache.put(10, "ten");

                    let arr = Iter.toArray(cache.vals());                    
                    Debug.print(debug_show arr);
                    assertTrue(arr == ["three", "two", "one"]);
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

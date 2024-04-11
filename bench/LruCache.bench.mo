import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";

import Bench "mo:bench";
import Fuzz "mo:fuzz";

import LruCache "../src";

module {
    public func init() : Bench.Bench {
        let bench = Bench.Bench();

        bench.name("Benchmarking LruCache");
        bench.description("Benchmarking the performance with 10k calls");

        bench.cols(["LruCache"]);
        bench.rows([
            "put()",
            "get()",
            "peek()",
            "replace()",
            "put() over limit",
            "put() over limit * 3",
            "remove()",
        ]);

        let fuzz = Fuzz.Fuzz();
        let limit = 10_000;

        let buffer = Buffer.Buffer<(Nat, Nat)>(limit);

        for (i in Iter.range(0, (limit * 3) - 1)) {
            let key = fuzz.nat.randomRange(0, limit ** 2);
            let val = fuzz.nat.randomRange(0, limit ** 3);

            buffer.add((key, val));
        };

        let { nhash } = LruCache;
        let cache = LruCache.new<Nat, Nat>(limit);

        bench.runner(
            func(col, row) = switch (row, col) {

                case ("LruCache", "put()") {
                    for (i in Iter.range(0, limit - 1)) {
                        let (key, val) = buffer.get(i); 
                        LruCache.put(cache, nhash, key, val);
                    };
                };

                case ("LruCache", "get()") {
                    for (i in Iter.range(0, limit - 1)) {
                        let (key, _) = buffer.get(i);
                        ignore LruCache.get(cache, nhash, key);
                    };
                };

                case ("LruCache", "peek()") {
                    for (i in Iter.range(0, limit - 1)) {
                        let (key, _) = buffer.get(i);
                        ignore LruCache.peek(cache, nhash, key);
                    };
                };

                case ("LruCache", "replace()") {
                    for (i in Iter.range(0, limit - 1)) {
                        let (key, val) = buffer.get(i);
                        LruCache.put(cache, nhash, key, val);
                    };
                };

                case ("LruCache", "put() over limit") {
                    for (i in Iter.range(limit, (limit * 2) - 1)) {
                        let (val, key) = buffer.get(i);
                        LruCache.put(cache, nhash, key, val);
                    };
                };

                case ("LruCache", "put() over limit * 3") {
                    for (i in Iter.range(0, (limit * 3) - 1)) {
                        let (val, key) = buffer.get(i);
                        LruCache.put(cache, nhash, key, val);
                    };
                };

                case ("LruCache", "remove()") {
                    for (i in Iter.range(0, limit - 1)) {
                        let (key, _) = buffer.get(i);
                        ignore LruCache.remove(cache, nhash, key);
                    };
                };

                case (_) {
                    Debug.trap("Should be unreachable:\n row = \"" # debug_show row # "\" and col = \"" # debug_show col # "\"");
                };
            }
        );

        bench;
    };
};

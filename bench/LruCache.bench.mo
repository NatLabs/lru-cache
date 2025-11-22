import List "mo:core@1.0.0/List";
import Runtime "mo:core@1.0.0/Runtime";
import Nat "mo:core@1.0.0/Nat";

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

        let list = List.empty<(Nat, Nat)>();

        for (i in Nat.range(0, (limit * 3))) {
            let key = fuzz.nat.randomRange(0, limit ** 2);
            let val = fuzz.nat.randomRange(0, limit ** 3);

            List.add(list, (key, val));
        };

        let nhash = LruCache.defaultUtils(LruCache.nhash);
        let cache = LruCache.new<Nat, Nat>(limit);

        bench.runner(
            func(col, row) = switch (row, col) {

                case ("LruCache", "put()") {
                    for (i in Nat.range(0, limit)) {
                        let (key, val) = List.at(list, i);
                        LruCache.put(cache, nhash, key, val);
                    };
                };

                case ("LruCache", "get()") {
                    for (i in Nat.range(0, limit)) {
                        let (key, _) = List.at(list, i);
                        ignore LruCache.get(cache, nhash, key);
                    };
                };

                case ("LruCache", "peek()") {
                    for (i in Nat.range(0, limit)) {
                        let (key, _) = List.at(list, i);
                        ignore LruCache.peek(cache, nhash, key);
                    };
                };

                case ("LruCache", "replace()") {
                    for (i in Nat.range(0, limit)) {
                        let (key, val) = List.at(list, i);
                        LruCache.put(cache, nhash, key, val);
                    };
                };

                case ("LruCache", "put() over limit") {
                    for (i in Nat.range(limit, (limit * 2))) {
                        let (val, key) = List.at(list, i);
                        LruCache.put(cache, nhash, key, val);
                    };
                };

                case ("LruCache", "put() over limit * 3") {
                    for (i in Nat.range(0, (limit * 3))) {
                        let (val, key) = List.at(list, i);
                        LruCache.put(cache, nhash, key, val);
                    };
                };

                case ("LruCache", "remove()") {
                    for (i in Nat.range(0, limit)) {
                        let (key, _) = List.at(list, i);
                        ignore LruCache.remove(cache, nhash, key);
                    };
                };

                case (_) {
                    Runtime.trap("Should be unreachable:\n row = \"" # debug_show row # "\" and col = \"" # debug_show col # "\"");
                };
            }
        );

        bench;
    };
};

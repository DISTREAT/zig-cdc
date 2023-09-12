# Zig-CDC

A loose interpretation of the FastCDC approach to Content-Defined-Chunking using Gear Hashing

## Data Deduplication

Simply put, the idea behind [Data deduplication](https://en.wikipedia.org/wiki/Data_deduplication) is to reduce the amount of repeating data stored.

This is achieved by splitting data into chunks which are then stored under a representative hash digest, avoiding clobbering and duplicates.

As soon as data in the boundaries of singular chunks are modified then only the modified chunk (with delta applied) is stored again.

The most straight-forward method is to choose a fixed-size for the chunk boundaries (Fixed-Size Chunking; FSC).
Although, it seems like a good solution at first, it does not solve the issue well.

## Boundary-shift problem

The issue of Fixed-Size Chunking is obvious when hinting at data insertion or deletion.
Essentially, inserting or deleting bytes leads to a shift of all following boundaries, altering the data inside the fixed-size chunks,
therefore also altering the hash, ultimately causing already existing data to be stored again.

## Content-Defined-Chunking

To solve the issue, a [rolling hash](https://en.wikipedia.org/wiki/Rolling_hash) is utilized that will pseudo-randomly define boundaries which shift along
the actual data, since the boundaries correlate with the hash calculated while 'rolling' over the bytes.

## Testing the implementation

Apart from a simple integration test (`zig build test`), the codebase also provides an in-memory model that collects statistical data to verify
that the implementation reaches expected goals (`zig build stats`):

```
info: input data size: 10 MB
minimum chunk size: 9.5 KB
desired chunk size: 10 KB
maximum chunk size: 10.5 KB

info: initial used space: 10490 KB / 10 MB
initial chunk count: 982
initial smallest chunk size: 5 KB
initial average chunk size: 10 KB
initial largest chunk size: 10 KB

info: mutation used space: 10500 KB / 10 MB
mutation chunk count: 983
mutation smallest chunk size: 5 KB
mutation average chunk size: 10 KB
mutation largest chunk size: 10 KB
```

The relevant part for interpreting the results is to compare the initial stats against the after-mutation stats.
`Initial` is referring to the stats after segmenting the original data.
Whereas, `mutation` is referring to the stats after segmenting the data with a modified byte.

The goal of having a decently-consistent chunk size is in this example accomplished.
Another interesting detail that confirms that the implementation is working as expected, is the delta between the two chunk counts being exactly 1.

Do not get confused by the smallest chunk size, it falls below the defined minimum chunk size because the final rest of the data is collected as a chunk,
leading to one smaller chunk.

## Disclaimer

Although the implementation is inspired by FastCDC, it should not be assumed that the suggestions to this new approach were fully translated.
It goes without saying that I am new to this topic and have not invested a lot of time researching and reading through papers.

## Resources

Some of the best articles on CDC using Gear Hashing are the articles by Josh Leeb (also where I obtained most of my knowledge from):

[CDC](https://joshleeb.com/posts/content-defined-chunking.html)

[Gear Hashing](https://joshleeb.com/posts/gear-hashing.html)

[FastCDC](https://joshleeb.com/posts/fastcdc.html)

[Restic's use of CDC using Rabin Fingerprints](https://restic.net/blog/2015-09-12/restic-foundation1-cdc/)

[FastCDC paper](https://www.usenix.org/system/files/conference/atc16/atc16-paper-xia.pdf)


---
title: "Divide and Conquer Algorithms - Getting Midpoints Correctly"
description: "Why (x + y) / 2 is not good enough"
pubDate: "Aug 12 2023"
heroImage: "/placeholder-hero.jpg"
---

Many divide and conquer algorithms contain some sort of logic that involves finding the midpoint of some range. There may have been a point in one's life where one may have decided that the midpoint of a range is:

```
(left + right) / 2
```

While there is nothing mathematically wrong with this approach, it is possible to run into integer overflow issues when left + right are added.

## Overflow Example

Let's use an array of length 10 as an example

```
arr = [0,1,2,3,4,5,6,7,8,9]
```

If we wanted to find the number 8 with a [binary search](https://en.wikipedia.org/wiki/Binary_search_algorithm) algorithm, the logic might look like

```
// Napkin math (not actually code)

arr = [0,1,2,3,4,5,6,7,8,9]

left = 0
right = 9
mid = left + right // 2
// 4
// 4 < 8, therefore we move the left pointer to mid + 1
// left is now 5

left = 5
right = 9
mid = left + right // 2
// 7

// 7 < 8, therefore we move the left pointer to mid + 1
// left is now 7

left = 7
right = 9
mid = left + right // 2
// 8, found!
```

Let's take a step back for one moment:

Integers use up to 32 bits of memory. Thus, we know that there exists some MAX_INTEGER, denoted as `MAX_INT`, that represents the upper limit of what a single block of allocated memory can store. In the case of 32 bit signed integers, this would be 2<sup>31</sup>, or a little over 2.1 billion. (1 bit is used to store the sign of the integer).

But what if the MAX_INT was 10 in the example above? Computing `left+right` would cause an overflow! Let's hold this thought for the next few minutes.

The way to ensure that overflows won't happen is by making sure that there is no chance of adding beyond the max number that can be represented in memory.

Let's find an expression that allows us to do that! Let x represent `left` and y represent `right` in the above expression.

```
// Finding the midpoint, start with expression that would cause an overflow
(x + y) / 2

// Add and minus x
(x - x + x + y) / 2

// Rearrange
(2x - x + y) / 2

// Rearrange Some More
(2x + y - x) / 2

// Split into 2 Fractions
2x/2 + (y-x)/2

// Simplify left side
x + (y-x) / 2
```

The above expression successfully ensures this via a simple algebraic proof. At no point in the final expression is it possible for two numbers to be added such that it causes an overflow.

- The bigger x is, the smaller `y-x` becomes!
- We know that y > x by definition (the goal is to find a midpoint, remember)
- Even if `x` approaches MAX_INT, `(y-x)/2` approaches 0 since y is also bounded by MAX_INT and must be greater than `x`

Another way to think of the final expression is, `(y-x)/2` means `take the distance between y and x and divide that by 2 to find the half  of the distance, then adjust by +x so we find the midpoint`

Considering the amount of steps I took, you can also tell that I suck at math.

## Wrap-Up

The next time you are calculating a midpoint, remember that

```bash
(left + right) / 2
```

Is potentially buggy because it's possible for left+right to exceed MAX_INT. We should be using

```bash
left + (right - left) // 2
```

While I'm not exactly qualified to be presenting math, I feel confident enough that the latter is indeed a superior way to find a midpoint. It will ensure that we can get a midpoint without overflowing.

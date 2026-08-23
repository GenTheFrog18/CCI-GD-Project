# Go Practicum Practice Set

**Topics:** Basic Go Programming Language · Perulangan dan Percabangan · Array · Subprogram · Searching · Sorting

This set is designed to start with focused refreshers and gradually become similar to an integrated practicum test. The later problems intentionally require several concepts at once.

## General Practice Rules

Unless a problem explicitly says otherwise:

- Use Go.
- Prefer fixed-size arrays with a constant such as `NMAX`, similar to the practicum exercises.
- Break the program into subprograms/functions when the problem naturally has separate tasks.
- Do not use Go's built-in sorting utilities for sorting exercises.
- For searching exercises, implement the requested search manually.
- Input is whitespace-separated, so it may be entered on one line or several lines.
- You may assume all input follows the stated format.
- Try to solve each problem without looking at previous solutions.

---

# Level 1 — Focused Refreshers

## Problem 1 — Number Classification

### Focus
Basic Go · Branching

### Problem

Given an integer `N`, determine several properties of the number.

Print:

1. `POSITIF`, `NEGATIF`, or `NOL`
2. `GENAP` or `GANJIL` if the number is not zero
3. `KELIPATAN-5` if the number is divisible by 5, otherwise `BUKAN-KELIPATAN-5`

For zero, print `NOL` on the first line and `KELIPATAN-5` on the second line.

### Example 1

**Input**
```text
18
```

**Output**
```text
POSITIF
GENAP
BUKAN-KELIPATAN-5
```

### Example 2

**Input**
```text
-25
```

**Output**
```text
NEGATIF
GANJIL
KELIPATAN-5
```

### Example 3

**Input**
```text
0
```

**Output**
```text
NOL
KELIPATAN-5
```

---

## Problem 2 — Match Statistics

### Focus
Looping · Branching

### Problem

A football team plays `N` matches. For every match, the number of goals scored and conceded is given.

Calculate and print:

- number of wins,
- number of draws,
- number of losses,
- total goals scored,
- total goals conceded,
- goal difference,
- total points.

A win gives 3 points, a draw gives 1 point, and a loss gives 0 points.

Print all seven values on one line in the order above.

### Example 1

**Input**
```text
5
2 0
1 1
0 3
4 2
1 2
```

**Output**
```text
2 1 2 8 8 0 7
```

### Example 2

**Input**
```text
4
1 0
2 1
3 2
0 0
```

**Output**
```text
3 1 0 6 3 3 10
```

---

## Problem 3 — Sequence Inspector

### Focus
Looping · Branching · Basic arithmetic

### Problem

Read positive integers one by one until the value `0` is encountered.

The terminating `0` is not part of the data.

Determine:

- how many numbers were entered,
- their sum,
- the largest number,
- the smallest number,
- how many are even,
- how many are odd.

Print the results in the following order:

```text
count sum maximum minimum even odd
```

You may assume at least one positive integer is entered before `0`.

### Example 1

**Input**
```text
8 3 12 5 6 0
```

**Output**
```text
5 34 12 3 3 2
```

### Example 2

**Input**
```text
7 7 7 0
```

**Output**
```text
3 21 7 7 0 3
```

---

## Problem 4 — Array Extremes

### Focus
Array

### Problem

Store `N` integers in an array.

Determine:

- the largest value and its **first** index,
- the smallest value and its **first** index.

Use zero-based indexing.

Print:

```text
maximum maximumIndex
minimum minimumIndex
```

If the same maximum or minimum value appears several times, use the first occurrence.

### Example 1

**Input**
```text
7
8 3 10 4 10 2 9
```

**Output**
```text
10 2
2 5
```

### Example 2

**Input**
```text
6
5 5 5 5 5 5
```

**Output**
```text
5 0
5 0
```

---

## Problem 5 — Filter and Average

### Focus
Array · Looping · Branching

### Problem

Read integers until `0` is encountered or the array reaches its maximum capacity.

For every non-zero input:

- if it is negative, store its absolute value;
- otherwise store it unchanged.

After input is finished, print:

1. all stored values,
2. their sum,
3. their average with one digit after the decimal point,
4. how many stored values are greater than the average.

You may assume at least one number is stored.

### Example 1

**Input**
```text
5 -3 8 -4 0
```

**Output**
```text
5 3 8 4
20
5.0
1
```

### Example 2

**Input**
```text
10 10 -10 2 8 0
```

**Output**
```text
10 10 10 2 8
40
8.0
3
```

---

# Level 2 — Subprograms and Search

## Problem 6 — Geometry Batch

### Focus
Subprogram · Pointers · Looping

### Problem

A program repeatedly receives a circle radius `r` and square side length `s`.

Input ends when both values are `0`.

For every pair, calculate:

- circle area,
- circle circumference,
- square area,
- square perimeter,
- combined area,
- combined perimeter.

Use `3.14` for π.

Organize the calculations into appropriate subprograms instead of writing all formulas directly inside `main`.

For each input pair, print the six results on one line with two digits after the decimal point.

### Example 1

**Input**
```text
2 3
1 4
0 0
```

**Output**
```text
12.56 12.56 9.00 12.00 21.56 24.56
3.14 6.28 16.00 16.00 19.14 22.28
```

### Example 2

**Input**
```text
5 2
0 0
```

**Output**
```text
78.50 31.40 4.00 8.00 82.50 39.40
```

---

## Problem 7 — Recursive Number Function

### Focus
Subprogram · Recursion

### Problem

Define the following function:

- `F(0) = 1`
- `F(1) = 1`
- for `n >= 2`, `F(n) = n * F(n-1) + F(n-2)`

Given `N`, calculate `F(N)` recursively.

Then calculate the sum:

```text
F(0) + F(1) + ... + F(N)
```

Print `F(N)` followed by the sum.

### Example 1

**Input**
```text
3
```

**Output**
```text
10 15
```

### Example 2

**Input**
```text
4
```

**Output**
```text
43 58
```

---

## Problem 8 — First Matching Position

### Focus
Linear Search

### Problem

Read `N` integers into an array, followed by a target value `X`.

Find the first occurrence of `X`.

If it exists, print its zero-based index and the number of times `X` occurs in the array.

If it does not exist, print:

```text
TIDAK ADA
```

Use a linear search.

### Example 1

**Input**
```text
8
4 7 2 7 9 7 3 1
7
```

**Output**
```text
1 3
```

### Example 2

**Input**
```text
5
10 20 30 40 50
25
```

**Output**
```text
TIDAK ADA
```

---

## Problem 9 — Student Registry

### Focus
Array · String · Binary Search

### Problem

A class list contains `N` student names already sorted in ascending alphabetical order.

Read a name to search for.

Use binary search to determine whether the student is registered.

If found, print:

```text
TERDAFTAR k
```

where `k` is the student's **one-based attendance number**.

Otherwise print:

```text
TIDAK TERDAFTAR
```

### Example 1

**Input**
```text
6
Andi Bima Citra Dinda Farhan Zahra
Dinda
```

**Output**
```text
TERDAFTAR 4
```

### Example 2

**Input**
```text
5
Alya Bagas Caca Dodi Eko
Fajar
```

**Output**
```text
TIDAK TERDAFTAR
```

---

# Level 3 — Sorting Fundamentals

## Problem 10 — Ascending and Descending

### Focus
Selection Sort

### Problem

Read `N` integers.

First sort the array in ascending order using selection sort and print it.

Then rearrange the same data into descending order, again using a manually implemented sorting procedure, and print it.

Do not use a built-in sorting package.

### Example 1

**Input**
```text
6
8 2 5 1 9 3
```

**Output**
```text
1 2 3 5 8 9
9 8 5 3 2 1
```

### Example 2

**Input**
```text
7
4 4 2 8 2 1 4
```

**Output**
```text
1 2 2 4 4 4 8
8 4 4 4 2 2 1
```

---

## Problem 11 — Ranking Applicants

### Focus
Struct · Array · Sorting · Tie-breakers

### Problem

Each job applicant has:

```text
id name score duration
```

where:

- `score` is a floating-point test score,
- `duration` is the number of minutes needed to finish the test.

Input applicant records until the string `END` is encountered in place of an ID.

Rank the applicants using these priorities:

1. higher score comes first;
2. if scores are equal, shorter duration comes first;
3. if score and duration are equal, lexicographically smaller ID comes first.

Print the final ranking as:

```text
rank id name score duration
```

Print scores with one digit after the decimal point.

Implement the sorting manually.

### Example 1

**Input**
```text
A03 Rina 88.5 70
A01 Budi 91.0 80
A02 Sari 91.0 65
A04 Dito 88.5 70
END
```

**Output**
```text
1 A02 Sari 91.0 65
2 A01 Budi 91.0 80
3 A03 Rina 88.5 70
4 A04 Dito 88.5 70
```

### Example 2

**Input**
```text
P10 Ana 75.0 60
P02 Cici 75.0 60
P07 Beni 80.0 90
END
```

**Output**
```text
1 P07 Beni 80.0 90
2 P02 Cici 75.0 60
3 P10 Ana 75.0 60
```

---

## Problem 12 — Inventory Alert

### Focus
Struct · Array · Searching · Sorting

### Problem

A shop stores `N` products. Each product contains:

```text
name price stock
```

After all products are entered, a maximum stock limit `L` is given.

Select every product whose stock is less than or equal to `L`.

Sort only the selected products using these priorities:

1. smaller stock first;
2. if stock is equal, cheaper price first;
3. if both are equal, name in ascending alphabetical order.

Print the selected products.

If none qualify, print:

```text
AMAN
```

### Example 1

**Input**
```text
5
Pensil 3000 4
Buku 7000 10
Penghapus 2500 2
Spidol 9000 4
Penggaris 3000 2
4
```

**Output**
```text
Penghapus 2500 2
Penggaris 3000 2
Pensil 3000 4
Spidol 9000 4
```

### Example 2

**Input**
```text
3
Laptop 9000000 8
Mouse 150000 10
Keyboard 400000 6
5
```

**Output**
```text
AMAN
```

---

# Level 4 — Mixed Concepts

## Problem 13 — Score Compression

### Focus
Array · Searching · Sorting · Subprogram

### Problem

Given `N` integer scores, create a list of the distinct score values and count how many times each one appears.

Sort the distinct scores in descending order.

For each distinct score, print:

```text
score frequency
```

Do not assume the original scores are sorted.

Try to organize the program into separate subprograms for:

- reading data,
- checking whether a score is already recorded,
- counting frequencies,
- sorting,
- printing.

### Example 1

**Input**
```text
10
80 70 80 90 60 70 90 90 75 80
```

**Output**
```text
90 3
80 3
75 1
70 2
60 1
```

### Example 2

**Input**
```text
6
100 100 100 50 50 75
```

**Output**
```text
100 3
75 1
50 2
```

---

## Problem 14 — Nearest Value Search

### Focus
Sorting · Binary Search · Branching

### Problem

Read `N` distinct integers in arbitrary order and a target value `X`.

First sort the data in ascending order.

Then:

- if `X` exists, print its index in the sorted array;
- otherwise determine the stored value closest to `X`.

If two values are equally close to `X`, choose the smaller value.

Print:

```text
ADA index
```

or:

```text
TERDEKAT value
```

The searching stage should take advantage of the fact that the array has been sorted.

### Example 1

**Input**
```text
7
18 4 25 9 12 30 2
12
```

**Output**
```text
ADA 3
```

### Example 2

**Input**
```text
6
3 20 8 15 1 30
11
```

**Output**
```text
TERDEKAT 8
```

### Example 3

**Input**
```text
5
2 6 10 14 18
12
```

**Output**
```text
TERDEKAT 10
```

---

## Problem 15 — Class Qualification

### Focus
Struct · Array · Subprogram · Searching · Sorting

### Problem

A course stores `N` students. Each student has:

```text
name practicum exam
```

Both grades are integers from 0 to 100.

A student's final score is:

```text
40% practicum + 60% exam
```

A student qualifies if:

- practicum grade is at least 50,
- exam grade is at least 50,
- final score is at least 60.

Collect all qualifying students and rank them using:

1. higher final score first;
2. if tied, higher practicum grade first;
3. if still tied, name alphabetically.

Print:

```text
rank name finalScore
```

with the final score shown using one digit after the decimal point.

If nobody qualifies, print:

```text
TIDAK ADA
```

### Example 1

**Input**
```text
5
Ari 80 70
Bela 55 65
Caca 90 50
Deni 40 95
Eka 70 80
```

**Output**
```text
1 Eka 76.0
2 Ari 74.0
3 Bela 61.0
```

### Example 2

**Input**
```text
4
A 40 90
B 90 40
C 50 50
D 30 30
```

**Output**
```text
TIDAK ADA
```

---

## Problem 16 — Warehouse Query System

### Focus
Struct · Array · Subprogram · Linear Search · Updating data

### Problem

A warehouse stores `N` products:

```text
code name stock
```

After the initial data, the program receives `Q` operations.

There are three possible commands:

```text
CARI code
TAMBAH code amount
KURANG code amount
```

Rules:

- `CARI` prints the product name and current stock.
- `TAMBAH` increases the stock if the code exists.
- `KURANG` decreases stock, but stock may never become negative.
- If a product code is not found, print `TIDAK DITEMUKAN`.
- If a `KURANG` operation requests more items than available, do not change the stock and print `STOK TIDAK CUKUP`.
- Successful `TAMBAH` and `KURANG` operations do not print anything.

Use a searching subprogram to locate product codes.

### Example 1

**Input**
```text
3
P01 Pensil 10
P02 Buku 5
P03 Tas 2
6
CARI P02
TAMBAH P02 4
CARI P02
KURANG P03 3
KURANG P01 6
CARI P01
```

**Output**
```text
Buku 5
Buku 9
STOK TIDAK CUKUP
Pensil 4
```

### Example 2

**Input**
```text
2
A Air 12
B Roti 3
4
CARI C
TAMBAH C 5
KURANG B 2
CARI B
```

**Output**
```text
TIDAK DITEMUKAN
TIDAK DITEMUKAN
Roti 1
```

---

# Level 5 — Practicum-Style Integration

## Problem 17 — Tournament Standings

### Focus
Struct · Arrays · Looping · Searching · Sorting · Multiple tie-breakers

### Problem

There are `N` teams in a tournament.

The team names are given first. Then `M` match results follow:

```text
teamA goalsA teamB goalsB
```

For every team, maintain:

- matches played,
- wins,
- draws,
- losses,
- goals scored,
- goals conceded,
- points.

A win gives 3 points and a draw gives 1 point.

After all matches are processed, sort the standings using:

1. higher points,
2. higher goal difference,
3. more goals scored,
4. team name alphabetically.

Print:

```text
rank team played win draw loss GF GA GD points
```

You will need to search the team array by name when processing each match.

### Example 1

**Input**
```text
3
Alpha Beta Gamma
3
Alpha 2 Beta 0
Gamma 1 Alpha 1
Beta 3 Gamma 1
```

**Output**
```text
1 Alpha 2 1 1 0 3 1 2 4
2 Beta 2 1 0 1 3 3 0 3
3 Gamma 2 0 1 1 2 4 -2 1
```

### Example 2

**Input**
```text
4
A B C D
4
A 1 B 0
C 2 D 0
A 0 C 1
B 2 D 1
```

**Output**
```text
1 C 2 2 0 0 3 0 3 6
2 A 2 1 0 1 1 1 0 3
3 B 2 1 0 1 2 2 0 3
4 D 2 0 0 2 1 4 -3 0
```

---

## Problem 18 — Library Loan Analysis

### Focus
Struct · Array · Searching · Sorting · Subprograms · Filtering

### Problem

A library stores `N` books:

```text
code title totalCopies
```

Then `M` loan transactions are given:

```text
code borrowedCopies
```

Every transaction refers to one book code. A transaction may only be completed if enough copies are currently available.

For every successful transaction, reduce the number of available copies. Ignore unsuccessful transactions.

After all transactions:

1. read a search code `X`,
2. print the title and remaining copies of that book, or `TIDAK DITEMUKAN`,
3. print a report containing all books sorted by:
   - fewer remaining copies first,
   - if tied, title alphabetically.

The original `totalCopies` should not be lost because the final report must print both total and remaining copies.

### Example 1

**Input**
```text
4
B01 Algoritma 5
B02 BasisData 3
B03 Jaringan 4
B04 Kalkulus 2
5
B01 2
B04 1
B02 3
B04 2
B03 1
B04
```

**Output**
```text
Kalkulus 1
B02 BasisData 3 0
B04 Kalkulus 2 1
B01 Algoritma 5 3
B03 Jaringan 4 3
```

### Example 2

**Input**
```text
3
X1 Go 2
X2 Python 4
X3 C 3
4
X1 1
X1 2
X3 3
X2 1
X9
```

**Output**
```text
TIDAK DITEMUKAN
X3 C 3 0
X1 Go 2 1
X2 Python 4 3
```

---

## Problem 19 — Exam Result Database

### Focus
Everything so far

### Problem

A practicum class contains `N` students. Each record contains:

```text
id name task1 task2 exam
```

All grades are integers.

The final grade is calculated as:

```text
20% task1 + 20% task2 + 60% exam
```

A student passes only if:

- every individual grade is at least 40, and
- final grade is at least 60.

After reading all students:

1. determine the highest and lowest final grades;
2. count how many students pass;
3. sort all students by:
   - higher final grade,
   - higher exam grade,
   - smaller ID;
4. read one ID and search for that student in the **sorted data**;
5. print the student's rank and result (`LULUS` or `TIDAK LULUS`);
6. print the complete ranking.

You should divide the program into suitable subprograms. Think carefully about whether the chosen searching method requires the data to be ordered by the search key.

### Example 1

**Input**
```text
4
S03 Citra 80 70 90
S01 Andi 60 60 60
S04 Deni 90 20 100
S02 Budi 50 70 65
S02
```

**Output**
```text
TERTINGGI 84.0
TERENDAH 60.0
LULUS 3
S02 3 LULUS
1 S03 Citra 84.0 LULUS
2 S04 Deni 82.0 TIDAK LULUS
3 S02 Budi 63.0 LULUS
4 S01 Andi 60.0 LULUS
```

### Example 2

**Input**
```text
3
A01 Ana 40 40 40
A03 Cici 100 100 100
A02 Beni 50 50 50
A04
```

**Output**
```text
TERTINGGI 100.0
TERENDAH 40.0
LULUS 1
TIDAK DITEMUKAN
1 A03 Cici 100.0 LULUS
2 A02 Beni 50.0 TIDAK LULUS
3 A01 Ana 40.0 TIDAK LULUS
```

---

## Problem 20 — Delivery Dispatch

### Focus
Full integration · Multi-key sorting · Search · Updates · Careful state management

### Problem

A delivery service has `N` couriers.

Each courier initially has:

```text
id name completed totalMinutes
```

where `completed` is the number of completed deliveries and `totalMinutes` is the total time spent on those deliveries.

Then `M` new delivery records follow:

```text
courierID duration status
```

`status` is either:

```text
SELESAI
GAGAL
```

For a `SELESAI` delivery:

- increase `completed`,
- add `duration` to `totalMinutes`.

For a `GAGAL` delivery, do not change the courier's statistics.

If a transaction contains an unknown courier ID, ignore it.

After all delivery records:

1. calculate each courier's average delivery time;
2. sort couriers using:
   - more completed deliveries first,
   - if tied, smaller average delivery time first,
   - if still tied, smaller ID first;
3. read a courier ID to search;
4. print that courier's final rank and statistics;
5. print the complete leaderboard.

If a courier has completed zero deliveries, define the average as `0.0`.

### Example 1

**Input**
```text
3
C02 Bima 2 60
C01 Andi 1 20
C03 Citra 0 0
5
C01 25 SELESAI
C03 30 GAGAL
C03 40 SELESAI
C02 15 SELESAI
C99 10 SELESAI
C02
```

**Output**
```text
1 C02 Bima 3 75 25.0
1 C02 Bima 3 75 25.0
2 C01 Andi 2 45 22.5
3 C03 Citra 1 40 40.0
```

### Example 2

**Input**
```text
4
K01 Raka 0 0
K02 Sinta 1 30
K03 Tono 1 20
K04 Wati 2 80
4
K01 10 SELESAI
K02 15 GAGAL
K03 40 SELESAI
K04 10 SELESAI
K01
```

**Output**
```text
4 K01 Raka 1 10 10.0
1 K04 Wati 3 90 30.0
2 K03 Tono 2 60 30.0
3 K02 Sinta 1 30 30.0
4 K01 Raka 1 10 10.0
```

---

# Level 6 — Mock Practicum Challenges

These are intentionally less guided. Treat them like possible test questions.

## Problem 21 — Scholarship Selection

### Focus
Full integration

### Problem

A university receives `N` scholarship applicants:

```text
id name academic interview income
```

An applicant is eligible when:

- academic score is at least 70,
- interview score is at least 60.

For eligible applicants, calculate:

```text
finalScore = 60% academic + 40% interview
```

The university can accept at most `K` applicants.

Rank eligible applicants by:

1. higher final score,
2. lower family income,
3. smaller ID.

Print only the accepted applicants.

Afterward, read an applicant ID and report whether that applicant was:

```text
DITERIMA rank
CADANGAN rank
TIDAK LOLOS
TIDAK DITEMUKAN
```

`CADANGAN` means eligible but ranked below the first `K`.

### Example 1

**Input**
```text
5
A01 Rani 80 75 5000
A02 Budi 90 60 7000
A03 Cici 65 90 3000
A04 Deni 80 75 4000
A05 Eka 70 60 2000
2
A01
```

**Output**
```text
1 A04 Deni 78.0
2 A01 Rani 78.0
DITERIMA 2
```

### Example 2

**Input**
```text
4
P01 Ana 70 60 1000
P02 Beni 60 90 500
P03 Caca 90 90 5000
P04 Dodi 80 70 3000
1
P04
```

**Output**
```text
1 P03 Caca 90.0
CADANGAN 2
```

---

## Problem 22 — Mini Search Engine

### Focus
Arrays · Strings · Linear Search · Sorting · Frequency analysis

### Problem

Read `N` words.

Then read a query word `Q`.

For every distinct word in the data, determine its frequency.

Sort the distinct words using:

1. higher frequency first,
2. alphabetical order for equal frequency.

Print the sorted frequency table.

Then search for `Q` in the distinct-word table.

If found, print:

```text
QUERY frequency rank
```

Otherwise print:

```text
QUERY 0 TIDAK ADA
```

You may assume each word contains no spaces.

### Example 1

**Input**
```text
9
go array go sort search go array loop sort
array
```

**Output**
```text
go 3
array 2
sort 2
loop 1
search 1
QUERY 2 2
```

### Example 2

**Input**
```text
6
apel jeruk apel mangga jeruk apel
pisang
```

**Output**
```text
apel 3
jeruk 2
mangga 1
QUERY 0 TIDAK ADA
```

---


## Problem 23 — Pair Sum Target

### Focus
Array · Looping · Searching · Optional Sorting

### Problem

You are given `N` integers and a target value `T`.

Find **two different elements** from the array whose sum is exactly equal to `T`.

If such a pair exists, print the two values in ascending order:

```text
a b
```

where:

```text
a + b = T
```

If more than one valid pair exists, choose the pair with the **smallest first value**. If there is still more than one possibility, choose the pair with the smallest second value.

If no valid pair exists, print:

```text
TIDAK ADA
```

The two numbers must come from two different array positions. Therefore, using the same value twice is only allowed if that value appears at least twice in the input.

Try solving this problem in more than one way:

1. using nested loops;
2. using a searching subprogram;
3. as an extra challenge, sort the data first and think about how sorting can reduce the amount of searching needed.

### Example 1

**Input**
```text
6
2 7 11 15 4 5
9
```

**Output**
```text
2 7
```

### Example 2

**Input**
```text
7
8 1 6 3 5 4 9
10
```

**Output**
```text
1 9
```

Explanation: several pairs produce `10`, such as `(1, 9)`, `(4, 6)`, and `(3, 7)` if `7` existed. The pair with the smallest first value must be chosen.

### Example 3

**Input**
```text
5
4 2 4 7 10
8
```

**Output**
```text
4 4
```

The value `4` may be used twice because it appears in two different array positions.

### Example 4

**Input**
```text
5
1 3 6 8 12
20
```

**Output**
```text
8 12
```

### Example 5

**Input**
```text
4
2 5 9 13
8
```

**Output**
```text
TIDAK ADA
```

### Extra Challenge

Modify the program so that instead of printing the values, it prints the **zero-based indexes** of the two elements from the original unsorted array.

If several index pairs are valid, choose the pair with the smallest first index, then the smallest second index.

For example:

**Input**
```text
6
10 3 7 2 8 5
10
```

**Output**
```text
1 2
```

because `3 + 7 = 10`.

---

# Suggested 10-Hour Study Order

Do not spend equal time on every problem. The goal is to rebuild fluency first, then spend most of the session on integrated problems.

| Time | Work |
|---|---|
| Hour 1 | Problems 1–3. Focus on syntax, loops, conditions, scanning, and formatting. |
| Hour 2 | Problems 4–5. Rebuild comfort with fixed-size arrays, indexes, counts, max/min, and sentinel input. |
| Hour 3 | Problems 6–7. Practice functions, pointer parameters, return values, and recursion. |
| Hour 4 | Problems 8–9. Implement linear search and binary search from memory. |
| Hour 5 | Problems 10–12. Write selection sort repeatedly until the index/swap pattern feels automatic. |
| Hour 6 | Problems 13–14. Combine sorting and searching. Pay attention to duplicates and boundary cases. |
| Hour 7 | Problems 15–16. Practice structs, filtered data, updates, and reusable search functions. |
| Hour 8 | Problems 17–18. Do them under light time pressure. Avoid looking at old code. |
| Hour 9 | Problems 19–20. Treat these as a mock practicum. Debug only with your own test cases first. |
| Hour 10 | Problems 21–23 or redo any problem you struggled with. Make sure you attempt Problem 23 in at least two different ways. Finish by rewriting selection sort, linear search, and binary search from memory. |

---

# What You Should Be Able to Write From Memory

Before the test, make sure you can produce these patterns without references:

1. A fixed-size array type:
   ```go
   const NMAX int = 100
   type tabInt [NMAX]int
   ```

2. Reading an array through a pointer.

3. Finding maximum/minimum values and indexes.

4. A function that returns a computed value.

5. A procedure-style function that modifies variables through pointers.

6. Linear search returning an index or `-1`.

7. Binary search on ascending data.

8. Selection sort ascending.

9. Selection sort descending.

10. Selection sort with two or three tie-breakers on a struct array.

11. Sentinel-controlled input such as `0` or `END`.

12. Filtering records into another array while maintaining a separate count.

13. Updating a struct record after finding it by ID.

14. Calculating values that are not stored directly, such as averages, points, or final grades.

---

# Self-Testing Checklist

When you finish a solution, test these cases whenever they are relevant:

- smallest allowed input,
- only one element,
- all values equal,
- target occurs at index `0`,
- target occurs at the final index,
- target is absent,
- duplicate target values,
- already sorted data,
- reverse-sorted data,
- ties in every sorting criterion,
- no records pass a filter,
- every record passes a filter,
- sentinel appears immediately,
- maximum array capacity,
- zero values,
- values exactly on qualification boundaries.

---

# Final Drill

Immediately before stopping for the night, take a blank editor and write these three functions **without looking anything up**:

```text
linearSearch
binarySearch
selectionSort
```

Then write one struct-based selection sort with at least two tie-breakers.

If those four pieces feel automatic, the more complicated practicum questions become mostly a matter of combining familiar parts.

# AES-256 Algorithm Documentation

## Overview

AES-256 (Advanced Encryption Standard) with 256-bit keys, as specified in NIST FIPS-197.

- **Block size**: 128 bits (4×4 byte state matrix)
- **Key size**: 256 bits
- **Number of rounds**: 14
- **Round keys**: 15 (including initial round key)

## State Representation

The 128-bit block is organized as a 4×4 matrix of bytes:

```
    0    1    2    3
   ┌────┬────┬────┬────┐
0  │ S0 │ S4 │ S8 │ S12│
   ├────┼────┼────┼────┤
1  │ S1 │ S5 │ S9 │ S13│
   ├────┼────┼────┼────┤
2  │ S2 │ S6 │ S10│ S14│
   ├────┼────┼────┼────┤
3  │ S3 │ S7 │ S11│ S15│
   └────┴────┴────┴────┘
```

Byte ordering: Input bytes [0:15] map to state as shown above.

## Encryption Round Structure

| Round | SubBytes | ShiftRows | MixColumns | AddRoundKey |
|-------|----------|-----------|------------|-------------|
| 0 (Initial) | — | — | — | ✓ |
| 1–13 (Full) | ✓ | ✓ | ✓ | ✓ |
| 14 (Final) | ✓ | ✓ | — | ✓ |

## Transformations

### 1. SubBytes

Non-linear byte substitution using an S-Box lookup table.

Each byte S[i] is replaced with S-Box[S[i]].

### 2. ShiftRows

Cyclic shift of rows:
- Row 0: no shift
- Row 1: shift left by 1
- Row 2: shift left by 2
- Row 3: shift left by 3

```
Input:          Output:
┌───┬───┬───┬───┐   ┌───┬───┬───┬───┐
│ a │ b │ c │ d │   │ a │ b │ c │ d │  (no shift)
├───┼───┼───┼───┤   ├───┼───┼───┼───┤
│ e │ f │ g │ h │   │ f │ g │ h │ e │  (shift 1)
├───┼───┼───┼───┤   ├───┼───┼───┼───┤
│ i │ j │ k │ l │   │ k │ l │ i │ j │  (shift 2)
├───┼───┼───┼───┤   ├───┼───┼───┼───┤
│ m │ n │ o │ p │   │ p │ m │ n │ o │  (shift 3)
└───┴───┴───┴───┘   └───┴───┴───┴───┘
```

### 3. MixColumns

Column-wise transformation using GF(2^8) multiplication.

Each column [a, b, c, d] is transformed to [a', b', c', d']:

```
a' = (02 • a) ⊕ (03 • b) ⊕ c ⊕ d
b' = a ⊕ (02 • b) ⊕ (03 • c) ⊕ d
c' = a ⊕ b ⊕ (02 • c) ⊕ (03 • d)
d' = (03 • a) ⊕ b ⊕ c ⊕ (02 • d)
```

Where • denotes GF(2^8) multiplication with reduction polynomial x^8 + x^4 + x^3 + x + 1 (0x11B).

### 4. AddRoundKey

Bitwise XOR of state with 128-bit round key.

## Key Schedule (KeyExpansion)

Input: 256-bit key (8 words of 32 bits: w[0..7])
Output: 60 words (w[0..59]), forming 15 round keys

### Key Expansion Algorithm

For i = 8 to 59:
- If i mod 8 == 0: w[i] = SubWord(RotWord(w[i-1])) ⊕ Rcon[i/8] ⊕ w[i-8]
- Else if i mod 8 == 4: w[i] = SubWord(w[i-1]) ⊕ w[i-8]
- Else: w[i] = w[i-1] ⊕ w[i-8]

Where:
- **RotWord**: Rotate word left by 1 byte [a,b,c,d] → [b,c,d,a]
- **SubWord**: Apply S-Box to each byte
- **Rcon**: Round constant [x^(i-1), 00, 00, 00] in GF(2^8)

### Rcon Values

| i | Rcon[i] |
|---|---------|
| 1 | 0x01000000 |
| 2 | 0x02000000 |
| 3 | 0x04000000 |
| 4 | 0x08000000 |
| 5 | 0x10000000 |
| 6 | 0x20000000 |
| 7 | 0x40000000 |
| 8 | 0x80000000 |
| 9 | 0x1B000000 |
| 10 | 0x36000000 |

## Decryption (Inverse Cipher)

Uses inverse transformations in reverse order:

| Round | InvShiftRows | InvSubBytes | AddRoundKey | InvMixColumns |
|-------|--------------|-------------|-------------|---------------|
| 0 (Initial) | — | — | ✓ | — |
| 1–13 (Full) | ✓ | ✓ | ✓ | ✓ |
| 14 (Final) | ✓ | ✓ | ✓ | — |

### Inverse Transformations

- **InvSubBytes**: Inverse S-Box lookup
- **InvShiftRows**: Shift right instead of left
- **InvMixColumns**: Uses multipliers 0x0e, 0x0b, 0x0d, 0x09

## NIST FIPS-197 Test Vector

### Encryption Test

```
Key (256-bit):
  00010203 04050607 08090a0b 0c0d0e0f
  10111213 14151617 18191a1b 1c1d1e1f

Plaintext (128-bit):
  00112233 44556677 8899aabb ccddeeff

Ciphertext (128-bit):
  8ea2b7ca 516745bf eafc4990 4b496089
```

### Round Key 0–3 (from spec)

```
w[0..3]  (Round 0):  00010203 04050607 08090a0b 0c0d0e0f
w[4..7]  (Round 1):  10111213 14151617 18191a1b 1c1d1e1f
w[8..11] (Round 2):  a573c29f a176c498 a97fce93 a572c09c
w[12..15](Round 3):  1651a8cd 0244beda 1a5da4c1 0640bade
```

## GF(2^8) Multiplication

Multiplication in GF(2^8) with reduction polynomial m(x) = x^8 + x^4 + x^3 + x + 1 (0x11B).

For multiplication by 02 (x):
```
function xtime(b):
    if b[7] == 0: return b << 1
    else: return (b << 1) ⊕ 0x1B
```

Multiplication by constants:
- 03 • a = (02 • a) ⊕ a
- 09 • a = (((02 • 02 • 02) • a) ⊕ a
- 0B • a = (((02 • 02 • 02) • a) ⊕ (02 • a) ⊕ a
- 0D • a = (((02 • 02 • 02) • a) ⊕ (02 • 02 • a) ⊕ a
- 0E • a = (((02 • 02 • 02) • a) ⊕ (02 • 02 • a) ⊕ (02 • a)

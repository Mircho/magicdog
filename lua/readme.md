# Lua binauth endpoint for NoDogSplash
This is the implementation of the functionality expected by NDS for the binauth endpoint. For more information read the [source documentation of NoDogSplash](https://nodogsplashdocs.readthedocs.io/en/stable/binauth.html)

## Installation

Copy the contents of this folder to a directory mounted on your OpenWrt router.

To enable it in NDS change in /etc/config/nodogsplash the binauth path to:
```
  option binauth '/path/to/vouchers/v.sh'
```
v.sh exists only to change the running context of vouchers.lua to the directory it resides in.

## Adding tokens
In order to have some tokens available you can create some calling vouchers.lua:
```
lua vouchers.lua add_tokens -h

Usage: Tokens add_tokens [-h] <number> <budget> <length>

Add new tokens within a new batch

Arguments:
   number                number of tokens to be added
   budget                budget in seconds per new token
   length                length in charactes of a token
```

This brings us to the budget topic. This is the ammount of seconds that the token can be exchanged for. So if you want to create 10 new tokens that will allow 60 min of access you can call it like this:
```
lua vouchers.lua -D v-test.db add_tokens 10 3600 6 
Batch: 1
OZ0NPP,3600
B83TK8,3600
PCZKST,3600
DGP9C1,3600
GE7JUN,3600
LQGJFP,3600
P10MZF,3600
KPBZO5,3600
T2VCJQ,3600
OUBJNK,3600
```
## Checking available tokens
If you want to check how many available tokens are there you can call:
```
lua vouchers.lua -D v-test.db print_available 1
1, OZ0NPP, 3600
1, B83TK8, 3600
1, PCZKST, 3600
1, DGP9C1, 3600
1, GE7JUN, 3600
1, LQGJFP, 3600
1, P10MZF, 3600
1, KPBZO5, 3600
1, T2VCJQ, 3600
1, OUBJNK, 3600
```
## Batches
As seen in the adding and checking examples there is a notion of batches. This is a marker of when we have run the printing press for our money and how many of the "bills" are still unused. The only argument the print_available command has is the batch id. If ommited then all unused tokens will be printed in CSV in the order:
- batch_id
- token
- budget

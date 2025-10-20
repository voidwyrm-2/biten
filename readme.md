# Biten

A utility for creating files based on byte specifications.  
Basically a reverse hex viewer.

This is a successor to [Bytec](https://github.com/voidwyrm-2/bytec).

## Example

```sh
cat example.bitn
biten example.bitn
xxd example.bin
```

## Installation

### Prebuilt binaries

Prebuilt binaries can be downloaded from the [releases](https://github.com/voidwyrm-2/npscript/releases/latest).

### Compiling locally

**Prerequisites**
- Git, which should be on your system already
- Nim, which can be downloaded from https://nim-lang.org/install.html

```sh
git clone https://github.com/voidwyrm-2/npscript
cd npscript
chmod +x build.nims
./build.nims host
./out/host/npscript -v
./out/host/npscript --repl
```

Addtionally, if you want to cross-compile, you'll need
- Zig, which can be downloaded from https://ziglang.org/download

```sh
git clone https://github.com/voidwyrm-2/npscript
cd npscript
sudo printf '#! /bin/sh\nzig cc $@' > /usr/local/bin/zigcc
sudo chmod +x /usr/local/bin/zigcc
chmod +x build.nims
./build.nims all
```

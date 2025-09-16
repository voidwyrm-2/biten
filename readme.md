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

If you aren't sure which to pick, go with `windows-amd64` or `linux-amd64`, depending on your system.

### Compiling locally

**Prerequisites**
- A Unix system or similar (compiling on Windows is not currently supported)
- Git, which should be on your system already
- Nim, which can be downloaded from https://nim-lang.org/install.html
- Nimble, which should have come bundled with Nim

```sh
git clone https://github.com/voidwyrm-2/npscript
cd npscript
nimble install https://github.com/voidwyrm-2/nargparse
chmod +x build.sh
./build.sh host
./out/host/npscript -v
./out/host/npscript --repl
```

Addtionally, if you want to cross-compile, you'll need
- Zig, which can be downloaded from https://ziglang.org/download

```sh
git clone https://github.com/voidwyrm-2/npscript
cd npscript
nimble install https://github.com/voidwyrm-2/nargparse
sudo printf '#! /bin/sh\nzig cc $@' > /usr/local/bin/zigcc
sudo chmod +x /usr/local/bin/zigcc
chmod +x build.sh
./build.sh all
```

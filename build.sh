#! /bin/sh

tryq() {
    if [ $? -ne 0 ]; then
        exit 1
    fi
}

APPNAME="biten"

# zcomp(os, arch, llvmTriple)
zcomp() {
    ext=""

    if [ "$1" = "windows" ]; then
        ext=".exe"
    fi

    llvmTriple="$3"

    outpath="out/$llvmTriple"
    result="$outpath/$APPNAME$ext"
    
    nim c \
        -d:release \
        --cc:clang \
        --clang.exe:"zigcc" \
        --clang.linkerexe:"zigcc" \
        --passC:"-target $llvmTriple $4" \
        --passL:"-target $llvmTriple $5" \
        --os:"$1" \
        --cpu:"$2" \
        --forceBuild:on \
        -o:"$result" \
        src/"$APPNAME".nim
    tryq
    
    cp -R "$outpath" .
    tryq
    
    zip -r "$llvmTriple" "$llvmTriple"
    tryq

    mv "$llvmTriple.zip" out/
    tryq

    rm -rf "$llvmTriple"
    tryq

    echo "built '$1/$2' with LLVM triple '$llvmTriple'"
}

if [ "$1" = "all" ]; then
    zcomp "macosx" "arm64" "aarch64-macos"
    zcomp "linux" "amd64" "x86_64-linux-gnu"
    zcomp "linux" "i386" "x86-linux-gnu"
    zcomp "linux" "arm64" "aarch64-linux-gnu"

    zcomp "linux" "amd64" "x86_64-linux-musl"
    zcomp "linux" "i386" "x86-linux-musl"
    zcomp "linux" "arm64" "aarch64-linux-musl"

    zcomp "windows" "amd64" "x86_64-windows"
    zcomp "windows" "i386" "x86-windows"
elif [ "$1" = "targ" ]; then
    zcomp "$2" "$3" "$4"
elif [ "$1" = "host" ]; then
    nim c \
    -d:release \
    --forceBuild:on \
    -o:out/host/"$APPNAME" \
    src/"$APPNAME".nim
elif [ "$1" = "" ]; then
    nim c \
    -o:out/"$APPNAME" \
    src/"$APPNAME".nim
else
    echo "unknown build target '$1'"
    exit 1
fi

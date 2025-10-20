import std/strformat

import
  lexer,
  parser

type
  Endian* = enum
    enSys,
    enBig,
    enLittle

  Generator* = ref object
    w: File
    endian: Endian
    debug: bool

func newGenerator*(writer: File, endian: Endian, debug: bool): Generator =
  new result
  result.w = writer
  result.endian = endian
  result.debug = debug

proc bytesError(self: Generator, node: Node, written, expected: int) =
  node.tok[].errf(fmt"Incomplete writing: {written} bytes written, but {expected} bytes were expected")

iterator byteIter(self: Generator, bytes: int, n: ptr uint64): ptr uint8 =
  template getByte(): ptr uint8 =
    cast[ptr uint8](cast[uint](n) + uint(i))

  template bigIter(): untyped =
    countup(0, bytes - 1, 1)

  template littleIter(): untyped =
    countdown(bytes - 1, 0, 1)

  case self.endian
  of enSys:
    for i in (when cpuEndian == littleEndian: littleIter() else: bigIter()):
      yield getByte()
  of enBig:
    for i in bigIter():
      yield getByte()
  of enLittle:
    for i in littleIter():
      yield getByte()

proc gen(self: Generator, node: Node) =
  case node.typ
  of ntInteger:
    let
      bytes =
        case node.int.bits
        of ib8:
          1
        of ib16:
          2
        of ib24:
          3
        of ib32:
          4
        of ib64:
          8

      pn = node.int.n
      nn = uint64(-int64(node.int.n))
      n = if node.negative: nn else: pn

    var buf = newSeqOfCap[uint8](bytes)

    for b in self.byteIter(bytes, addr n):
      buf.add(b[])

    if self.debug:
      echo fmt"{node} -> {buf}"

    let written = self.w.writeBytes(buf, 0, buf.len)
    if written < buf.len:
      self.bytesError(node, written, buf.len)
  of ntString:
    let arr = cast[seq[char]](node.str.s)

    let written = self.w.writeChars(arr, 0, arr.len)
    if written < arr.len:
      self.bytesError(node, written, arr.len)
  of ntLoop:
    for i in 0 ..< node.amount.n:
      self.gen(node.body)

proc gen*(self: Generator, nodes: seq[Node]) =
  for node in nodes:
    self.gen(node)

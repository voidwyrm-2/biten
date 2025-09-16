import std/strformat

import
  lexer,
  parser

type
  Generator = ref object
    w: File

func newGenerator*(writer: File): Generator =
  new result
  result.w = writer

proc bytesError(self: Generator, node: Node, written, expected: int) =
  node.tok[].errf(fmt"Incomplete writing: {written} bytes written, but {expected} bytes were expected")

proc gen(self: Generator, node: Node) =
  case node.typ
  of ntInteger:
    let
      pn = node.int.n
      nn = uint64(-int64(node.int.n))
      n = if node.negative: nn else: pn

    var
      bytes = 0
      hasValue = false
      buf: seq[uint8]

    for i in 0..<8:
      let b = cast[ptr uint8](cast[uint](addr n) + uint(i) * uint(sizeof(pointer)))[]
      if b > 0 or hasValue:
        inc bytes
        hasValue = true
        buf.add(b)

    let written = self.w.writeBytes(buf, 0, buf.len)
    if written < bytes:
      self.bytesError(node, written, buf.len)

    if not hasValue:
      let written = self.w.writeBytes([uint8(0)], 0, 0)
      if written < bytes:
        self.bytesError(node, written, 1)
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

import std/strformat

import lexer


func findMinimumBits(n: uint64): uint8 =
  template highn(t: typedesc): uint64 =
    uint64(high(t))

  if n < highn(uint8):
    8
  elif n < highn(uint16):
    16
  elif n < highn(uint32):
    32
  else:
    64


type
  NodeType* = enum
    ntInteger,
    ntString,
    ntLoop

  Node* = ref object
    case typ: NodeType
    of ntInteger:
      negative*: bool
      int*: ptr Token
      bits*: uint8 = 0
    of ntString:
      str*: ptr Token
    of ntLoop:
      amount*: ptr Token
      body*: Node

  Parser* = ref object
    tokens: seq[Token]
    idx: uint


func typ*(self: Node): NodeType =
  self.typ

func tok*(self: Node): ptr Token =
  case self.typ
  of ntInteger:
    self.int
  of ntString:
    self.str
  of ntLoop:
    self.body.tok

proc `$`*(self: Node): string =
  let body =
    case self.typ
    of ntInteger:
      fmt"{self.negative} {self.int[].lit} {self.bits}"
    of ntString:
      fmt"{self.str[].lit}"
    of ntLoop:
      fmt"{self.amount[].lit} {self.body}"

  fmt"<{self.typ}: {body}>"

func newParser*(tokens: seq[Token]): Parser =
  new result
  result.tokens = tokens

func peek(self: Parser): ptr Token =
  if self.idx + 1 < uint(self.tokens.len()):
    result = addr self.tokens[self.idx + 1]

proc parseTok*(self: Parser, tok: ptr Token): Node

proc parseLoop(self: Parser, anchor: ptr Token): Node =
  result = Node(typ: ntLoop)

  template checkNext(cur, next: ptr Token, tts: set[TokenType], msg: string) =
    if next == nil:
      cur[].errf(msg)
    elif next[].typ notin tts:
      next[].errf(msg)

  result.amount = self.peek()
  checkNext(anchor, result.amount, {ttInteger}, "Expected integer for loop amount")

  inc self.idx

  let term = self.peek()
  checkNext(result.amount, term, {ttParenRight}, "Unterminated loop expression")

  self.idx += 2

  if self.idx >= uint(self.tokens.len()):
    self.tokens[^1].errf("Expected body for loop")

  result.body = self.parseTok(addr self.tokens[self.idx])

proc parseTok*(self: Parser, tok: ptr Token): Node =
  case tok[].typ
  of ttInteger:
    result = Node(typ: ntInteger, int: tok, bits: findMinimumBits(tok.n))
    inc self.idx
  of ttString:
    result = Node(typ: ntString, str: tok)
    inc self.idx
  of ttHyphen:
    let next = self.peek()
    if next == nil:
      tok[].errf("Expected integer after negative modifier")
    elif next[].typ != ttInteger:
      next[].errf("Expected integer after negative modifier")

    if not next[].canBeNegative or next[].n > uint64(high(int64)):
      next[].errf("Invalid negative number")

    result = Node(typ: ntInteger, negative: true, int: next)
    self.idx += 2
  of ttParenLeft:
    result = self.parseLoop(tok)
  else:
    tok[].errf(fmt"Unexpected token '{tok[].lit}'")

proc parse*(self: Parser): seq[Node] =
  while self.idx < uint(self.tokens.len()):
    result.add(self.parseTok(addr self.tokens[self.idx]))

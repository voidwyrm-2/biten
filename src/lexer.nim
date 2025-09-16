import std/[
  strformat,
  strutils
]

import general


const
  digitsB10 = '0'..'9'
  digitsBin = '0'..'2'
  digitsOct = '0'..'8'
  digitsHex = {'0'..'9', 'a'..'f', 'A'..'F'}


type
  DigitBase = enum
    dt10,
    dtBin,
    dtOct,
    dtHex

  TokenType* = enum
    ttInteger,
    ttString,
    ttHyphen,
    ttParenLeft,
    ttParenRight

  Token* = object
    ln, col: uint
    case typ: TokenType
    of ttInteger:
      canBeNegative*: bool
      n*: uint64
    of ttString:
      s*: string
    else:
      discard

  Lexer* = ref object
    r: File
    file: string
    ln, col: uint
    cur, next: char
    eof, hasNext: bool

func typ*(self: Token): TokenType =
  self.typ

func lit*(self: Token): string =
  case self.typ
    of ttInteger:
      $self.n
    of ttString:
      self.s
    of ttHyphen:
      "-"
    of ttParenLeft:
      "("
    of ttParenRight:
      ")"

func errf*(self: Token, msg: string) =
  raise newException(BitenError, fmt"Error on line {self.ln}, col {self.col}" & "\n" & msg)

func `$`*(self: Token): string =
  let str =
    if self.typ == ttInteger:
      fmt"{self.typ} {self.lit} {self.canBeNegative} {self.ln} {self.col}"
    else:
      fmt"{self.typ} `{self.lit}` {self.ln} {self.col}"

  "{" & str & "}"

proc adv(self: Lexer)

proc newLexer*(file: string, reader: File): Lexer =
  new result
  result.r = reader
  result.file = file
  result.ln = 1
  result.col = 1
  result.adv()
  result.adv()

proc readChar(self: Lexer): char =
  result = self.r.readChar()
  self.hasNext = self.r.endOfFile()

proc adv(self: Lexer) =
  self.cur = self.next

  inc self.col

  if self.hasNext:
    self.eof = true

  if not self.eof:
    self.next = self.readChar()

  if self.cur == '\n' and not self.hasNext:
    inc self.ln
    self.col = 1

func tok(self: Lexer, tt: TokenType): Token =
  Token(typ: tt, ln: self.ln, col: self.col)
  
func errf(self: Lexer, msg: string) =
  self.tok(ttHyphen).errf(msg)

func errf(self: Lexer, msg: string, ln, col: uint) =
  Token(typ: ttHyphen, ln: ln, col: col).errf(msg)

proc collectInteger(self: Lexer): Token =
  result = Token(typ: ttInteger)
  result.ln = self.ln
  result.col = self.col

  var
    base = dt10
    buf: seq[char]

  template baseBody(dt: DigitBase, chset: untyped): untyped =
    if buf.len() > 0 or self.next notin chset:
      break

    buf.add('0')
    buf.add(ch)
    base = dt

  while not self.eof:
    let ch = self.cur

    case ch:
    of 'b':
      baseBody(dtBin, digitsBin)
    of 'o':
      baseBody(dtOct, digitsOct)
    of 'x':
      baseBody(dtHex, digitsHex)
    else:
      var valid =
        case base
        of dt10:
           ch in digitsB10
        of dtBin:
          ch in digitsBin
        of dtOct:
          ch in digitsOct
        of dtHex:
          ch in digitsHex

      if valid or (ch == '_' and (buf.len() == 0 or buf[^1] != '_')):
        buf.add(ch)
        self.adv()
        continue
      
      break

    self.adv()

  let lit = cast[string](buf)

  case base
  of dt10:
    result.n = parseUInt(lit)
    result.canBeNegative = true
  of dtBin:
    result.n = fromBin[uint64](lit)
  of dtOct:
    result.n = fromOct[uint64](lit)
  of dtHex:
    result.n = fromHex[uint64](lit)

proc collectString(self: Lexer): Token =
  result = Token(typ: ttString)
  result.ln = self.ln
  result.col = self.col
  
  self.adv()

  var
    escaped = false
    buf: seq[char]
  
  while not self.eof:
    let ch = self.cur

    if escaped:
      buf.add:
        case ch
        of '\\', '\'', '"':
          ch
        of '0':
          '\0'
        of '\t':
          '\t'
        of 'n':
          '\n'
        of 'r':
          '\r'
        of 'v':
          '\v'
        of '\a':
          '\a'
        of 'f':
          '\f'
        of 'b':
          '\b'
        of 'e':
          '\e'
        else:
          self.errf(fmt"Invalid escape specifier '{ch}'")
          '0'

      escaped = false
      self.adv()
      continue

    case ch
    of '\\':
      escaped = true
    of '"':
      break
    else:
      buf.add(ch)

    self.adv()

  if self.cur != '"':
    self.errf("Unterminated string literal", self.ln, self.col)

  self.adv()

  result.s = cast[string](buf)

proc lex*(self: Lexer): seq[Token] =
  while not self.eof:
    let ch = self.cur

    case ch
    of char(0)..char(32), char(127):
      self.adv()
    of '#':
      while not self.eof and self.cur != '\n':
        self.adv()
    of '0'..'9', 'b', 'o', 'x':
      result.add(self.collectInteger())
    of '"':
      result.add(self.collectString())
    of '-', '(', ')':
      let tt =
        case ch:
        of '-':
          ttHyphen
        of '(':
          ttParenLeft
        of ')':
          ttParenRight
        else:
          ttHyphen

      result.add(self.tok(tt))
      self.adv()
    else:
      self.errf(fmt"Illegal character '{self.cur}'")

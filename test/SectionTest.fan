class SectionTest : Test
{
  Void testNullContext()
  {
    token := SectionToken(false,"foo",[StaticTextToken("bar")])
    buf := StrBuf()
    token.render(buf,null,[:])
    verifyEq(buf.toStr,"")
  }

  Void testBoolContext()
  {
    token := SectionToken(false,"foo",[StaticTextToken("bar")])
    fbuf := StrBuf()
    tbuf := StrBuf()
    token.render(fbuf,["foo":false],[:])
    token.render(tbuf,["foo":true],[:])
    verifyEq(fbuf.toStr,"")
    verifyEq(tbuf.toStr,"bar")
  }

  Void testListContext()
  {
    token := SectionToken(false,"foo",[StaticTextToken("bar:"),
                                          EscapedToken("value"),
                                          StaticTextToken(",")])
    ebuf := StrBuf()
    lbuf := StrBuf()
    token.render(ebuf,["foo":[,]],[:])
    token.render(lbuf,["foo":[["value":1],["value":2],["value":3]]],[:])
    verifyEq(ebuf.toStr,"")
    verifyEq(lbuf.toStr,"bar:1,bar:2,bar:3,")
  }

  Void testInvNullContext()
  {
    token := SectionToken(true,"foo",[StaticTextToken("bar")])
    buf := StrBuf()
    token.render(buf,null,[:])
    verifyEq(buf.toStr,"bar")
  }

  Void testInvBoolContext()
  {
    token := SectionToken(true,"foo",[StaticTextToken("bar")])
    fbuf := StrBuf()
    tbuf := StrBuf()
    token.render(fbuf,["foo":false],[:])
    token.render(tbuf,["foo":true],[:])
    verifyEq(fbuf.toStr,"bar")
    verifyEq(tbuf.toStr,"")
  }

  Void testInvListContext()
  {
    token := SectionToken(true,"foo",[StaticTextToken("list is empty")])
    ebuf := StrBuf()
    lbuf := StrBuf()
    token.render(ebuf,["foo":[,]],[:])
    token.render(lbuf,["foo":[["value":1],["value":2],["value":3]]],[:])
    verifyEq(ebuf.toStr,"list is empty")
    verifyEq(lbuf.toStr,"")
  }
}


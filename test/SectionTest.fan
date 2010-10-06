class SectionTest : Test
{
  Void testNullContext()
  {
    token := MustacheSectionToken("foo",[StaticTextToken("bar")])
    buf := StrBuf()
    token.render(buf,null)
    verifyEq(buf.toStr,"")
  }

  Void testBoolContext()
  {
    token := MustacheSectionToken("foo",[StaticTextToken("bar")])
    fbuf := StrBuf()
    tbuf := StrBuf()
    token.render(fbuf,["foo":false])
    token.render(tbuf,["foo":true])
    verifyEq(fbuf.toStr,"")
    verifyEq(tbuf.toStr,"bar")
  }

  Void testListContext()
  {
    token := MustacheSectionToken("foo",[StaticTextToken("bar:"),
                                          MustacheEscapedToken("value"),
                                          StaticTextToken(",")])
    ebuf := StrBuf()
    lbuf := StrBuf()
    token.render(ebuf,["foo":[,]])
    token.render(lbuf,["foo":[["value":1],["value":2],["value":3]]])
    verifyEq(ebuf.toStr,"")
    verifyEq(lbuf.toStr,"bar:1,bar:2,bar:3,")
  }
}


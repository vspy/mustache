class EscapeTest : Test
{
  Void testEscapedOutput()
  {
    etoken := EscapedToken("foo")
    utoken := UnescapedToken("foo")
    ctx := ["foo":"<\">&test"]

    ebuf := StrBuf()
    ubuf := StrBuf()

    etoken.render(ebuf,ctx,[:])
    utoken.render(ubuf,ctx,[:])

    verifyEq(ebuf.toStr, "&lt;&quot;&gt;&amp;test")
    verifyEq(ubuf.toStr, "<\">&test")
  }
}

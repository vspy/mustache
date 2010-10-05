class EscapeTest : Test
{
  Void testEscapedOutput()
  {
    etoken := MustacheEscapedToken("foo")
    utoken := MustacheUnescapedToken("foo")
    ctx := ["foo":"<>&test"]

    ebuf := StrBuf()
    ubuf := StrBuf()

    etoken.render(ebuf,ctx)
    utoken.render(ubuf,ctx)

    verifyEq(ebuf.toStr, "&lt;&rt;&amp;test")
    verifyEq(ubuf.toStr, "<>&test")
  }
}

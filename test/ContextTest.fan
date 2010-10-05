class ContextTest : Test
{
  Void testNullContext()
  {
    token := TestToken()
    verifyNull(token.valueOf("testKey",null))
  }
}

internal const class TestToken : MustacheToken
{
  override Void render(StrBuf buf, Obj? context)
  { 
  }
}

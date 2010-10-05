class ContextTest : Test
{
  Void testNullContext()
  {
    verifyNull(MustacheToken.valueOf("testKey",null))
  }

  Void testMap()
  {
    verifyNull(MustacheToken.valueOf("n/a",[:]))
    verifyEq(MustacheToken.valueOf("foo",["foo":"bar"]),"bar")
  }

  Void testObject()
  {
    verifyNull(MustacheToken.valueOf("n/a",this))
    verifyEq(MustacheToken.valueOf("sampleField",this),"foo")
    verifyEq(MustacheToken.valueOf("sampleMethod",this),"bar")
  }

  const Str sampleField := "foo"
  Str sampleMethod() { return "bar" }
}

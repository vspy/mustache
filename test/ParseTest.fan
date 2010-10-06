class ParseTest : Test
{
  Void testStaticTextOnly()
  {
    verifyEq(Mustache("Hello, world!".in).render(),"Hello, world!")
  }

  Void testSimpleValue()
  {
    verifyEq(Mustache("Hello, {{name}}!".in).render(["name":"world"]),
            "Hello, world!")
  }

  Void testIncompleteOpeningTags() 
  {
    verifyEq(Mustache("{ { {".in).render(),"{ { {")
  }

  Void testEmptyTag() 
  {
    verifyErr(ParseErr#){ template := Mustache("{{}}".in) }
  }
}



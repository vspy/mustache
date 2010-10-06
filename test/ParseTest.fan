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

  Void testEscaping()
  {
    verifyEq(Mustache("Hello, {{name}}!".in).render(["name":"<tag>"]),
            "Hello, &lt;tag&gt;!")
    verifyEq(Mustache("Hello, {{{name}}}!".in).render(["name":"<tag>"]),
            "Hello, <tag>!")
    verifyEq(Mustache("Hello, {{&name}}!".in).render(["name":"<tag>"]),
            "Hello, <tag>!")

    // unbalanced { inside the tag
    verifyErr(ParseErr#){ template := Mustache("Hello, {{{name}}!".in) }
  }

  Void testIncompleteTags() 
  {
    verifyEq(Mustache("{ { {".in).render(),"{ { {")
    verifyEq(Mustache("} }} }".in).render(),"} }} }")
  }

  Void testSections()
  {
    verifyEq(Mustache("Message: {{#needToGreet}}Hello, {{name}}!{{/needToGreet}}".in
                      ).render(["needToGreet":true,"name":"world"]),
            "Message: Hello, world!")
    verifyEq(Mustache("Message: {{#needToGreet}}Hello, {{name}}!{{/needToGreet}}".in
                      ).render(["needToGreet":false,"name":"world"]),
            "Message: ")
  }

  Void testEmptyTag() 
  {
    verifyErr(ParseErr#){ template := Mustache("{{}}".in) }
  }

  Void testUnclosedSection()
  {
    verifyErr(ParseErr#){ 
      template := Mustache("some text {{#foo}} some internal text".in) 
    }
  }

  Void testUnclosedTag() 
  {
    verifyErr(ParseErr#){ 
      template := Mustache("some text {{unclosed tag".in) 
    }
  }

  Void testMessedSection()
  {
    verifyErr(ParseErr#){ 
      template := Mustache("some text {{#foo}} {{#bar}} some 
                            internal text {{/foo}} {{/bar}}".in) 
    }
  }

  Void testInvalidChangeDelimiterTag() 
  {
    verifyErr(ParseErr#){ 
      template := Mustache("some text {{=}} some text".in) 
    }
    verifyErr(ParseErr#){ 
      template := Mustache("some text {{==}} some text".in) 
    }
    verifyErr(ParseErr#){ 
      template := Mustache("some text {{= foo =}} some text".in) 
    }
  }

  Void testInvalidTags() 
  {
    verifyErr(ParseErr#){ 
      template := Mustache("some text {{>}} some text".in) 
    }
    verifyErr(ParseErr#){ 
      template := Mustache("some text {{<}} some text".in) 
    }
    verifyErr(ParseErr#){ 
      template := Mustache("some text {{&}} some text".in) 
    }
    verifyErr(ParseErr#){ 
      template := Mustache("some text {{^}}...{{/}} some text".in) 
    }
    verifyErr(ParseErr#){ 
      template := Mustache("some text {{#}}...{{/}} some text".in) 
    }
  }

}



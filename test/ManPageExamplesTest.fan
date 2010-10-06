class ManPageExamplesTest : Test
{
  Void testTypicalTemplate()
  {
    verifyEq(Mustache("Hello {{name}}
                       You have just won \${{value}}!
                       {{#in_ca}}
                       Well, \${{taxed_value}}, after taxes.
                       {{/in_ca}}".in).render(
                        [ "name": "Chris",
                          "value": 10000,
                          "taxed_value": |->Decimal| { return 10000.0 - (10000.0 * 0.4) },
                          "in_ca": true
                        ]
                      ),
                      "Hello Chris
                       You have just won \$10000!

                       Well, \$6000.00, after taxes.
                       ")
  }

  Void testVariablesTemplate()
  {
    verifyEq(Mustache("* {{name}}
                       * {{age}}
                       * {{company}}
                       * {{{company}}}".in).render(
                        [ "name": "Chris",
                          "company": "<b>GitHub</b>"
                        ]
                      ),
                      "* Chris
                       *
                       * &lt;b&gt;GitHub&lt;/b&gt;
                       * <b>GitHub</b>")
  }

  Void testSectionsTemplate()
  {
    verifyEq(Mustache("Shown.
                       {{#nothin}}
                         Never shown!
                       {{/nothin}}".in).render(
                        [ "person": true ]
                      ),
                      "Shown.
                       ")
  }

  Void testSectionsListTemplate()
  {
    verifyEq(Mustache("{{#repo}}
                         <b>{{name}}</b>
                       {{/repo}}".in).render(
                        [ "repo": [
                            ["name":"resque"],
                            ["name":"hub"],
                            ["name":"rip"] 
                          ]
                        ]
                      ),
                      "
                         <b>resque</b>

                         <b>hub</b>

                         <b>rip</b>
                       ")
  }

  Void testSectionsNonFalseTemplate()
  {
    verifyEq(Mustache("{{#person?}}Hi {{name}}!{{/person?}}".in).render(
                        [ "person?": ["name":"John"] ]
                      ),
                      "Hi John!")
  }

  Void testInvertedSectionsTemplate()
  {
    verifyEq(
      Mustache(
        "{{#repo}}<b>{{name}}</b>{{/repo}}{{^repo}}No repos :({{/repo}}".in
      ).render(
        ["repo": [,]]
      ),
      "No repos :("
    )
  }

  Void testCommentsTemplate()
  {
    verifyEq(
      Mustache(
        "<h1>Today{{! ignore me }}.</h1>".in
      ).render(["! ignore me":"Hey! This text should not be shown."]),
      "<h1>Today.</h1>"
    )
  }

  Void testPartials()
  {
      userTemplate := Mustache("<strong>{{name}}</strong>".in)
      baseTemplate := Mustache("<h2>Names</h2>
                                {{#names}}
                                  {{> user}}
                                {{/names}}".in)
      verifyEq(
        baseTemplate.render(["names":[["name":"Alice"],["name":"Bob"]]],
                          ["user":userTemplate]),
        "<h2>Names</h2>
         
           <strong>Alice</strong>

           <strong>Bob</strong>
         ")
  }

}




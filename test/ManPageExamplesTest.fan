/*
Copyright (c) 2010, Victor Bilyk
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

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
      baseTemplate1 := Mustache("<h2>Names</h2>
                                 {{#names}}
                                   {{> user}}
                                 {{/names}}".in)
      baseTemplate2 := Mustache("<h2>Names</h2>
                                 {{#names}}
                                   {{> user}}
                                 {{/names}}".in)

      ctx := ["names":[["name":"Alice"],["name":"Bob"]]]
      partials := ["user":userTemplate]
      refValue := "<h2>Names</h2>
         
                     <strong>Alice</strong>

                     <strong>Bob</strong>
                   "
      verifyEq(baseTemplate1.render(ctx,partials), refValue)
      verifyEq(baseTemplate2.render(ctx,partials), refValue)
  }


  Void testSetDelimiters()
  {
    template := Mustache("* {{default_tags}}
                          {{=<% %>=}}
                          * <% erb_style_tags %>
                          <%={{ }}=%>
                          * {{ default_tags_again }}".in)
    verifyEq(template.render(["default_tags":"Line one",
                              "erb_style_tags":"Line two",
                              "default_tags_again":"Line three"]),
             "* Line one

              * Line two

              * Line three")
  }
}




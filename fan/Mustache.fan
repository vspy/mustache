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

** Mustache can be used for HTML, config files, source code - anything. 
** It works by expanding tags in a template using values provided in a 
** hash or object.
**
** We call it "logic-less" because there are no if statements, else 
** clauses, or for loops. Instead there are only tags. Some tags are
** replaced with a value, some nothing, and others a series of values.
**
** A typical Mustache template:
**
** pre>
** Hello {{name}}
** You have just won ${{value}}!
** {{#in_ca}}
** Well, ${{taxed_value}}, after taxes.
** {{/in_ca}}
** <pre
**
** Given the following hash:
**
** pre>
** [ "name": "Chris",
**   "value": 10000,
**   "taxed_value": |->Decimal| { return 10000.0 - (10000.0 * 0.4) },
**   "in_ca": true
** ]
** <pre
**
** Will produce the following:
**
** pre>
** Hello Chris
** You have just won $10000!
** Well, $6000.0, after taxes.
** <pre
**
** This doc is based on original mustache man page:
** http://mustache.github.com/mustache.5.html
**
**************************************************************************

const class Mustache
{
  private const MustacheToken[] compiledTemplate

  new make(InStream templateStream,
          Str otag:="{{", 
          Str ctag:="}}") {
    this.compiledTemplate = MustacheParser(templateStream,otag,ctag).parse
  }

  Str render(Obj? context:=null, [Str:Mustache] partials:=[:]) {
    StrBuf output:=StrBuf()
    compiledTemplate.each { it.render(output,context,partials) }
    return output.toStr
  }

}

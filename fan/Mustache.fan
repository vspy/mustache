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

internal class MustacheParser
{
  InStream in
  Str otag
  Str ctag
  State state
  StrBuf buf
  Int cur
  MustacheToken[] stack
  Int tagPosition 

  new make(InStream in, Str otag, Str ctag) {
    if (otag.isEmpty)
      throw ArgErr("otag should not be empty")
    if (ctag.isEmpty)
      throw ArgErr("ctag should not be empty")

    this.in = in
    this.otag = otag
    this.ctag = ctag
    this.state = State.text
    this.buf = StrBuf()
    this.tagPosition = 0
    this.stack = [,]
  }

  MustacheToken[] parse () {
    consume
    while(cur!=-1) {
      switch (state) {
        case State.text: stext()
        case State.otag: sotag()
        case State.tag: stag()
        case State.ctag: sctag()
      }
      consume
    }

    switch (state) {
      case State.text: addStaticText
      case State.otag: notOtag; addStaticText
      case State.tag: throw ParseErr("Unclosed tag $buf")
      case State.ctag: notCtag; addStaticText
    }
    stack.each { 
      if (it is IncompleteSection) { 
        key := (it as IncompleteSection).key
        throw ParseErr("Unclosed mustache section \"$key\"")
      }
    }
    return stack
  }

  Void stext() {
    if (cur==otag[0]) {
      if (otag.size>1) {
        tagPosition = 1
        state = State.otag
      } else {
        addStaticText
        state = State.tag
      }
    } else addCur
  }

  Void sotag() {
    if (cur == otag[tagPosition]) {
      if (tagPosition == otag.size-1) {
        addStaticText
        state = State.tag
      } else tagPosition++;
    } else {
      state = State.text
      notOtag
    }
  }

  Void stag() {
    if (cur==ctag[0]) {
      if (ctag.size>1) {
        tagPosition = 1
        state = State.ctag
      } else {
        addTag
        state = State.text
      }
    } else addCur
  }

  Void sctag() {
    if (cur == ctag[tagPosition]) {
      if (tagPosition == ctag.size-1) {
        addTag
        state = State.text
      } else tagPosition++;
    } else {
      state = State.tag
      notCtag
    }
  }

  Void addStaticText() {
    if (buf.size>0) {
      stack.add(StaticTextToken(buf.toStr))
      buf.clear
    }
  }

  Void addTag() {
    Str content := buf.toStr.trim
    if (content.size == 0)
      throw ParseErr("Empty tag content")

    switch (content[0]) {
      case '!': ignore // ignore comments
      case '&': 
        stack.add(UnescapedToken(content[1..-1]))
      case '{':
        if (content.endsWith("}"))
          stack.add(UnescapedToken(content[1..-2]))
        else throw ParseErr("Unbalanced { in tag \"$content\"")
      case '^':
        stack.add(IncompleteSection(content[1..-1], true))
      case '#':
        stack.add(IncompleteSection(content[1..-1], false))
      case '/': 
        name := content[1..-1]
        MustacheToken[] children := [,]

        while(true) {
          last := stack.pop

          if (last == null)
            throw ParseErr("Closing unopened $name")

          if (last is IncompleteSection) {
            incomplete := (last as IncompleteSection)
            inverted := incomplete.inverted
            key := incomplete.key
            if (key == name) {
              stack.add(SectionToken(inverted,name,children.reverse))
              break
            } else throw ParseErr("Unclosed section $key")
          } else children.add(last)
        }
      case '>':
      case '<':
        stack.add(PartialToken(content[1..-1]))
      case '=':
        if (content.size>2 && content.endsWith("=")) {
          changeDelimiter := content[1..-2]
          newTags := changeDelimiter.split
          if (newTags.size==2) { 
            otag = newTags[0]
            ctag = newTags[1]
            typeof.pod.log.info("new delimiters are \"$otag\",\"$ctag\"")
          } else {
            throw ParseErr("Invalid change delimiter tag content: \"$changeDelimiter\"")
          }
        } else throw ParseErr("Invalid change delimiter tag content: \"$content\"")
      default:
        stack.add(EscapedToken(content))
    }
    buf.clear
  }
  Void ignore() {}

  Void notOtag() { buf.add(otag[0..tagPosition-1]); addCur }
  Void notCtag() { buf.add(ctag[0..tagPosition-1]); addCur }

  Void addCur() { if (cur!=-1) buf.addChar(cur) }

  Void consume() {
    this.cur = this.in.readChar ?: -1
  }
}
internal enum class State { text, otag, tag, ctag }


**
** base mixin for all the token implementations
**
internal const mixin MustacheToken {
  abstract Void render(StrBuf output, Obj? context, [Str:Mustache]partials)

  static Obj? valueOf(Str name, Obj? context) {
    if (context == null)
      return null

    value := null

    if (context is Map) 
      value = (context as Map).get(name)
    else {
      slot := context.typeof.slot(name,false)
      if (slot == null) return null

      if (slot is Field)
        value = (slot as Field).get(context)

      if (slot is Method)
        value = (slot as Method).call(context)
    }

    if (value is Func) 
      return (value as Func).call()
    else 
      return value
  }

}

internal const class IncompleteSection : MustacheToken {
  const Str key
  const Bool inverted
  new make(Str key,Bool inverted) {
    this.key = key  
    this.inverted = inverted
  }
  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
  }
}

internal const class StaticTextToken : MustacheToken
{
  const Str staticText

  new make(Str staticText) {
    this.staticText = staticText
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
    output.add(staticText)
  }
}

internal const class SectionToken : MustacheToken {
  const Str key
  const MustacheToken[]children
  const Bool invertedSection

  new make(Bool invertedSection, Str key, MustacheToken[] children) {
    this.key = key
    this.children = children
    this.invertedSection = invertedSection
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
    Obj? value := valueOf(key, context)

    if (value == null) {
      if (invertedSection) renderChildren(output, context, partials)
      return
    }

    if (value is Bool) {
      Bool b := value
      if (invertedSection.xor(b))
          renderChildren(output,context,partials)
    } else if (value is List) {
        list := (value as List)
        if (invertedSection) {
          if (list.isEmpty) renderChildren(output,context,partials)
        } else {
          list.each { renderChildren(output,it,partials) }
        }
    } else renderChildren(output,value,partials)
  }

  private Void renderChildren(StrBuf output, Obj? context, [Str:Mustache]partials) {
    children.each { it.render(output,context,partials) }
  }
}

internal const class EscapedToken : MustacheToken {
  const Str key

  new make(Str key) {
    this.key = key
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
    Obj? value := valueOf(key, context)
    if (value == null)
      return
    Str str := value.toStr
    str.each {
      switch (it) {
        case '<': output.add("&lt;")
        case '>': output.add("&gt;")
        case '&': output.add("&amp;")
        default: output.addChar(it)
      }
    }
  }
}

internal const class UnescapedToken : MustacheToken {
  const Str key

  new make(Str key) {
    this.key = key 
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
    Obj? value := valueOf(key,context)
    if (value == null)
      return
    output.add(value)
  }
}

internal const class PartialToken : MustacheToken {
  const Str key

  new make(Str key) {
    this.key = key.trim 
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
    Mustache? template := partials[key]
    if (template == null)
      throw ArgErr("Partial \"$key\" is not defined.")
    else
      output.add(template.render(context, partials))
  }
}

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

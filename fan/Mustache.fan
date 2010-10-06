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
      case '>':
      case '<':
        stack.add(PartialToken(content[1..-1]))
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

//
//
//
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

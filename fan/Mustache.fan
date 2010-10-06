const class Mustache
{
  private const MustacheToken[] compiledTemplate

  new make(InStream templateStream,Str otag:="{{", Str ctag:="}}") {
    this.compiledTemplate = MustacheParser(templateStream,otag,ctag).parse
  }

  Str render(Obj? context:=null) {
    buf := StrBuf()
    compiledTemplate.each { it.render(buf,context) }
    return buf.toStr
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
      case State.tag: throw ParseErr("Unclosed tag")
      case State.ctag: notCtag; addStaticText
    }
    //TODO: check for unclosed sections
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
      case '&':
      case '{':
      case '#':
        stack.add(IncompleteMustacheSection(content[1..-1]))
      case '/':
      default:
        stack.add(MustacheEscapedToken(content))
    }
    buf.clear
  }

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
  abstract Void render(StrBuf output, Obj? context)

  static Obj? valueOf(Str name, Obj? context) {
    if (context == null)
      return null
    else if (context is Map) 
      return (context as Map).get(name)
    else {
      slot := context.typeof.slot(name,false)
      if (slot == null) return null

      if (slot is Field)
        return (slot as Field).get(context)

      if (slot is Method)
        return (slot as Method).call(context)

      return null
    }
  }

}

internal const class IncompleteMustacheSection : MustacheToken {
  const Str key
  new make(Str key) {
    this.key = key  
  }
  override Void render(StrBuf output, Obj? context) {
  }
}

internal const class StaticTextToken : MustacheToken
{
  const Str staticText

  new make(Str staticText) {
    this.staticText = staticText
  }

  override Void render(StrBuf output, Obj? context) {
    output.add(staticText)
  }
}

internal const class MustacheSectionToken : MustacheToken {
  const Str key
  const MustacheToken[]children

  new make(Str key, MustacheToken[] children) {
    this.key = key
    this.children = children
  }

  override Void render(StrBuf output, Obj? context) {
    Obj? value := valueOf(key, context)
    if (value == null)
      return
    if (value is Bool) {
      switch (value) { case true: renderChildren(output,context) }
    } else if (value is List)
        (value as List).each { renderChildren(output,it) }
    else renderChildren(output,value)
  }

  private Void renderChildren(StrBuf output, Obj? context) {
    children.each { it.render(output,context) }
  }
}

internal const class MustacheEscapedToken : MustacheToken {
  const Str key

  new make(Str key) {
    this.key = key
  }

  override Void render(StrBuf output, Obj? context) {
    Obj? value := valueOf(key, context)
    if (value == null)
      return
    Str str := value.toStr
    str.each {
      switch (it) {
        case '<': output.add("&lt;")
        case '>': output.add("&rt;")
        case '&': output.add("&amp;")
        default: output.addChar(it)
      }
    }
  }
}

internal const class MustacheUnescapedToken : MustacheToken {
  const Str key

  new make(Str key) {
    this.key = key 
  }

  override Void render(StrBuf output, Obj? context) {
    Obj? value := valueOf(key,context)
    if (value == null)
      return
    output.add(value)
  }
}

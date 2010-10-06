const class Mustache
{
  private const MustacheToken[] compiledTemplate

  new make(Str template,Str otag:="{{", Str ctag:="}}")
  {
    this.compiledTemplate = compile(template,otag,ctag)
  }

  private MustacheToken[] compile(Str template, Str otag, Str ctag) {
     return [,]
  }

  Str render(Obj? context:=null) {
    buf := StrBuf()
    compiledTemplate.each { it.render(buf,context) }
    return buf.toStr
  }

}

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

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

  Obj? valueOf(Str name, Obj? context) {
    if (context == null)
      return null
    else if (context is Map) 
      return (context as Map).get(name)
    else 
      return context.typeof.field(name,false)?.get(context)?:
             context.typeof.method(name,false)?.call()
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
  const Str value
  const MustacheToken[]children

  new make(Str value,MustacheToken[] children) {
    this.value = value 
    this.children = children
  }

  override Void render(StrBuf output, Obj? context) {
    //TODO: check value
    children.each { it.render(output,context) }
  }
}

internal const class MustacheEscapedToken : MustacheToken {
  const Str value

  new make(Str value) {
    this.value = value 
  }

  override Void render(StrBuf output, Obj? context) {
    Str toEscape := valueOf(value, context)
    toEscape.each {
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
  const Str value

  new make(Str value) {
    this.value = value 
  }

  override Void render(StrBuf output, Obj? context) {
    output.add(valueOf(value, context))
  }
}

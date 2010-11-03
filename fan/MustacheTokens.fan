**
** base mixin for all the token implementations
**
const mixin MustacheToken {
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
    this.key = key
  }

  override Void render(StrBuf output, Obj? context, [Str:Mustache]partials) {
    Mustache? template := partials[key]
    if (template == null)
      throw ArgErr("Partial \"$key\" is not defined.")
    else
      output.add(template.render(context, partials))
  }
}

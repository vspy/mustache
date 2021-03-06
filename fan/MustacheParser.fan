enum class State { text, otag, tag, ctag }

class MustacheParser
{
  InStream in
  Str otag := "{{"
  Str ctag := "}}"
  State state := State.text
  StrBuf buf := StrBuf()

  Int line := 1

  Int prev := -1
  Int cur := -1

  MustacheToken[] stack := [,]
  Int tagPosition := 0
  Bool curlyBraceTag 
  
  new make(|This|? f := null) { f?.call(this) }

  MustacheToken[] parse () {
    consume
    while(cur!=-1) {
      switch (state) {

        case State.text:
          if (cur==otag[0]) {
            if (otag.size>1) {
              tagPosition = 1
              state = State.otag
            } else {
              addStaticText
              state = State.tag
            }
          } else addCur

        case State.otag: 
          if (cur == otag[tagPosition]) {
            if (tagPosition == otag.size-1) {
              addStaticText
              curlyBraceTag = false
              state = State.tag
            } else tagPosition++;
          } else {
            state = State.text
            notOtag
          }

        case State.tag:
          if (buf.isEmpty && cur == '{') {
            curlyBraceTag = true
            addCur
          } else if (curlyBraceTag && cur == '}') {
            curlyBraceTag = false
            addCur
          } else if (cur==ctag[0]) {
            if (ctag.size>1) {
              tagPosition = 1
              state = State.ctag
            } else {
              addTag
              state = State.text
            }
          } else addCur 

        case State.ctag:
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

      consume
    }

    switch (state) {
      case State.text: addStaticText
      case State.otag: notOtag; addStaticText
      case State.tag: throw ParseErr("Line $line: Unclosed tag \"$buf\"")
      case State.ctag: notCtag; addStaticText
    }
    stack.each { 
      if (it is IncompleteSection) { 
        key := (it as IncompleteSection).key
        throw ParseErr("Line $line: Unclosed mustache section \"$key\"")
      }
    }
    return stack
  }

  Void addStaticText() {
    if (buf.size>0) {
      stack.add(StaticTextToken(buf.toStr))
      buf.clear
    }
  }

  Void addTag() {
    Str content := checkContent(buf.toStr)

    switch (content[0]) {
      case '!': ignore // ignore comments
      case '&': 
        stack.add(unescapedToken(content[1..-1]))
      case '{':
        if (content.endsWith("}"))
          stack.add(unescapedToken(content[1..-2]))
        else throw ParseErr("Line $line: Unbalanced \"{\" in tag \"$content\"")
      case '^':
        stack.add(IncompleteSection(checkContent(content[1..-1]), true))
      case '#':
        stack.add(IncompleteSection(checkContent(content[1..-1]), false))
      case '/': 
        name := checkContent(content[1..-1])
        MustacheToken[] children := [,]

        while(true) {
          last := stack.pop

          if (last == null)
            throw ParseErr("Line $line: Closing unopened section \"$name\"")

          if (last is IncompleteSection) {
            incomplete := (last as IncompleteSection)
            inverted := incomplete.inverted
            key := incomplete.key
            if (key == name) {
              stack.add(SectionToken(inverted,name,children.reverse))
              break
            } else throw ParseErr("Line $line: Unclosed section \"$key\"")
          } else children.add(last)
        }
      case '>':
      case '<':
        stack.add(partialToken(content[1..-1]))
      case '=':
        if (content.size>2 && content.endsWith("=")) {
          changeDelimiter := checkContent(content[1..-2])
          newTags := changeDelimiter.split
          if (newTags.size==2) { 
            otag = newTags[0]
            ctag = newTags[1]
          } else {
            throw ParseErr("Line $line: Invalid change delimiter tag content: \"$changeDelimiter\"")
          }
        } else throw ParseErr("Line $line: Invalid change delimiter tag content: \"$content\"")
      default:
        stack.add(defaultToken(content))
    }
    buf.clear
  }

  virtual MustacheToken partialToken(Str content) {
    PartialToken(checkContent(content))
  } 

  virtual MustacheToken defaultToken(Str content) {
    EscapedToken(content)
  }
  
  virtual MustacheToken unescapedToken(Str content) {
    UnescapedToken(checkContent(content))
  }
  
  Void ignore() {}

  Str checkContent(Str content) {
    trimmed := content.trim
    if (trimmed.size == 0)
      throw ParseErr("Line $line: Empty tag")
    else
      return trimmed
  }

  Void notOtag() { buf.add(otag[0..tagPosition-1]); addCur }
  Void notCtag() { buf.add(ctag[0..tagPosition-1]); addCur }

  Void addCur() { if (cur!=-1) buf.addChar(cur) }

  Void consume() {
    this.prev = this.cur
    this.cur = this.in.readChar ?: -1

    // \n, \r\n, \r
    if ( cur == '\r' ||
         ( cur == '\n' && prev != '\r' ) 
       ) line++
  }
}



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

internal enum class State { text, otag, tag, ctag }

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
              state = State.tag
            } else tagPosition++;
          } else {
            state = State.text
            notOtag
          }

        case State.tag:
          if (cur==ctag[0]) {
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



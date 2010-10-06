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

class SectionTest : Test
{
  Void testNullContext()
  {
    token := SectionToken(false,"foo",[StaticTextToken("bar")])
    buf := StrBuf()
    token.render(buf,null,[:])
    verifyEq(buf.toStr,"")
  }

  Void testBoolContext()
  {
    token := SectionToken(false,"foo",[StaticTextToken("bar")])
    fbuf := StrBuf()
    tbuf := StrBuf()
    token.render(fbuf,["foo":false],[:])
    token.render(tbuf,["foo":true],[:])
    verifyEq(fbuf.toStr,"")
    verifyEq(tbuf.toStr,"bar")
  }

  Void testListContext()
  {
    token := SectionToken(false,"foo",[StaticTextToken("bar:"),
                                          EscapedToken("value"),
                                          StaticTextToken(",")])
    ebuf := StrBuf()
    lbuf := StrBuf()
    token.render(ebuf,["foo":[,]],[:])
    token.render(lbuf,["foo":[["value":1],["value":2],["value":3]]],[:])
    verifyEq(ebuf.toStr,"")
    verifyEq(lbuf.toStr,"bar:1,bar:2,bar:3,")
  }

  Void testInvNullContext()
  {
    token := SectionToken(true,"foo",[StaticTextToken("bar")])
    buf := StrBuf()
    token.render(buf,null,[:])
    verifyEq(buf.toStr,"bar")
  }

  Void testInvBoolContext()
  {
    token := SectionToken(true,"foo",[StaticTextToken("bar")])
    fbuf := StrBuf()
    tbuf := StrBuf()
    token.render(fbuf,["foo":false],[:])
    token.render(tbuf,["foo":true],[:])
    verifyEq(fbuf.toStr,"bar")
    verifyEq(tbuf.toStr,"")
  }

  Void testInvListContext()
  {
    token := SectionToken(true,"foo",[StaticTextToken("list is empty")])
    ebuf := StrBuf()
    lbuf := StrBuf()
    token.render(ebuf,["foo":[,]],[:])
    token.render(lbuf,["foo":[["value":1],["value":2],["value":3]]],[:])
    verifyEq(ebuf.toStr,"list is empty")
    verifyEq(lbuf.toStr,"")
  }
}


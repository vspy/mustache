Mustache
========

What is Mustache?
-----------------

[Mustache][1] is a logic-free template engine inspired by ctemplate and et. 

As ctemplates says, "It emphasizes separating logic from presentation: it is impossible to embed application logic in this template language".

Why?
----

I just needed a template engine for the application I develop with Fantom and I really like the idea of Mustache.

Usage
-----

    using mustache
    Mustache template := Mustache("Hello, {{ name }}!".in)
    template.render(["name":"world"])

Returns following:

    Hello, world!

To get the language-agnostic overview of Mustache's template syntax and more examples of Mustache templates, see <http://mustache.github.com/mustache.5.html>.

Licensing
---------

Mustache for fantom is licensed under the MIT license. 

I’m not a lawyer and this is not a legal advice, but it is free to use in any projects. Free as in “free beer”. Should you have any questions on licensing, consult your attorney.

IDE support
-----------

Vim
---

Thanks to Juvenn Woo for mustache.vim. It is included under the contrib/ directory.
See <http://gist.github.com/323622> for installation instructions.

Emacs
-----

mustache-mode.el is included under the contrib/ directory for any Emacs users. Based on Google's tpl-mode for ctemplates, it adds support for Mustache's more lenient tag values and includes a few commands for your editing pleasure.
See <http://gist.github.com/323619> for installation instructions.

TextMate
--------

Mustache.tmbundle
See <http://gist.github.com/323624> for installation instructions.

Enjoy !

[1]: http://github.com/defunkt/mustache

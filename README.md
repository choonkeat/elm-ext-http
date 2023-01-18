# choonkeat/elm-ext-http

While it is very tempting to just use [`Http.Error`](https://package.elm-lang.org/packages/elm/http/latest/Http#Error) that comes with the standard [elm/http](https://package.elm-lang.org/packages/elm/http/latest/). It does not contain important values needed to troubleshoot production issues, e.g. http response headers. Once your codebase is scattered with `Http.Error`, it is onerous to troubleshoot parts of your app without affecting others.

It is also common for [Http resolver functions](https://package.elm-lang.org/packages/elm/http/latest/Http#Resolver) to only return the json decoded value. But equally important are the http response headers, e.g. how many more http api calls can I make before I'm throttled?

This module provides
- a better error type: `Ext.Http.Error`
- a verbose json resolver function: `jsonResolver`
- a `identityResolver` useful for decoding non-json payloads like Bytes or String

Additionally, helper functions are provided to
- generate cookie string for http response headers
- and parse cookie value from http request headers
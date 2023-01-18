module Ext.Http.Cookie exposing
    ( Attribute(..)
    , Input
    , get
    , responseString
    )

{-| See <https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies>

But in general, don't use `Expires` anymore,

    [ SameSite "Lax"
    , Path "/"
    , Domain "example.com"
    , MaxAge 86400
    , Secure
    , HttpOnly
    ]

-}


type Attribute
    = SameSite String
    | Path String
    | Domain String
    | MaxAge Int
    | Expires String
    | Secure
    | HttpOnly


stringFromAttribute : Attribute -> String
stringFromAttribute attribute =
    case attribute of
        SameSite value ->
            "SameSite=" ++ value

        Path value ->
            "Path=" ++ value

        Domain value ->
            "Domain=" ++ value

        MaxAge value ->
            "Max-Age=" ++ String.fromInt value

        Expires value ->
            "Expires=" ++ value

        Secure ->
            "Secure"

        HttpOnly ->
            "HttpOnly"


{-| See <https://datatracker.ietf.org/doc/html/rfc6265> for valid characters in cookie names and values
-}
type alias Input =
    { name : String
    , value : String
    , attributes : List Attribute
    }


{-| Return a String value that can be used as the value of a `Set-Cookie` response header

    Http.header "Set-Cookie" (responseString Input)

The generated String will be in the format:

    responseString
        { name = "somekey"
        , value = "somevalue"
        , attributes =
            [ SameSite "Lax"
            , Path "/"
            , Domain "example.com"
            , MaxAge 86400
            , Expires "Wed, 21 Oct 2015 07:28:00 GMT"
            , Secure
            , HttpOnly
            ]
        }
    --> "somekey=somevalue; SameSite=Lax; Path=/; Domain=example.com; Max-Age=86400; Expires=Wed, 21 Oct 2015 07:28:00 GMT; Secure; HttpOnly"

-}
responseString : Input -> String
responseString { name, value, attributes } =
    String.join "; "
        ((name ++ "=" ++ value) :: List.map stringFromAttribute attributes)


{-| Obtains the cookie value for a given cookie name from a `Cookie` http request header

NOTE: the `Cookie` http request header that server sees does not come with the attributes you see in the `Set-Cookie` response header.

    requestString : String
    requestString =
        "somekey=somevalue; sess=somejwt"

    get "sess" requestString
    --> Just "somejwt"

    get "somekey" requestString
    --> Just "somevalue"

-}
get : String -> String -> Maybe String
get name requestString =
    requestString
        |> String.split "; "
        |> List.filter (String.startsWith (name ++ "="))
        |> List.head
        |> Maybe.map (String.replace (name ++ "=") "")

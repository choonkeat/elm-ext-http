module Ext.Http exposing (Error(..), TaskInput, errorString, Data, identityResolver, jsonResolver)

{-| This module extends the `Http` module with better error handling and more information in the success case.

@docs Error, TaskInput, errorString, Data, identityResolver, jsonResolver

-}

import Http
import Json.Decode


{-| Named type alias for the `Http.task` parameter
-}
type alias TaskInput x a =
    { method : String
    , headers : List Http.Header
    , url : String
    , body : Http.Body
    , resolver : Http.Resolver x a
    , timeout : Maybe Float
    }


{-| Use Ext.Http.Error instead of Http.Error to get more information about the error.
-}
type Error a
    = BadUrl String
    | Timeout
    | NetworkError
    | BadStatus Http.Metadata a
    | BadJson Http.Metadata a Json.Decode.Error


{-| Convenience function to convert an Ext.Http.Error to a String.
-}
errorString : Error String -> String
errorString err =
    case err of
        BadUrl url ->
            "BadUrl " ++ url

        Timeout ->
            "Timeout"

        NetworkError ->
            "NetworkError"

        BadStatus metadata response ->
            "BadStatus "
                ++ String.fromInt metadata.statusCode
                ++ " "
                ++ metadata.statusText
                ++ ": "
                ++ response

        BadJson metadata response error ->
            "BadJson "
                ++ String.fromInt metadata.statusCode
                ++ " "
                ++ metadata.statusText
                ++ ": "
                ++ response
                ++ " "
                ++ Json.Decode.errorToString error


{-| When http succeeds, you get a `Data` record with both the `Http.Metadata` and the `data` that was decoded from the response.

    Http.task request
        |> Task.andThen
            (\{ meta, data } ->
                -- do something with meta and/or data
                -- like checking the status code
            )

-}
type alias Data a =
    { meta : Http.Metadata
    , data : a
    }


{-| Resolver for `Http.task` that includes proper details in both the error case and metadata in the success case.

Usually metadata is not needed in the success case, just add `Task.map .data` to your existing code

    ```diff
     Http.task
         { method = "GET"
         , headers = []
         , url = "https://example.com"
         , body = Http.emptyBody
    -    , resolver = Http.stringResolver (otherJsonResolver myDecoder)
    +    , resolver = Http.stringResolver (Ext.Http.jsonResolver myDecoder)
         , timeout = Nothing
         }
    +    |> Task.map .data
    ```

But when you need it, having the metadata available is very useful.

    ```diff
     Http.task
         { method = "GET"
         , headers = []
         , url = "https://example.com"
         , body = Http.emptyBody
         , resolver = Http.stringResolver (Ext.Http.jsonResolver myDecoder)
         , timeout = Nothing
         }
    +    |> Task.map (Debug.log "{ meta, data }")
         |> Task.map .data
    ```

-}
jsonResolver : Json.Decode.Decoder a -> Http.Response String -> Result (Error String) (Data a)
jsonResolver decoder resp =
    case resp of
        Http.BadUrl_ url ->
            Err (BadUrl url)

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError

        Http.BadStatus_ metadata response ->
            Err (BadStatus metadata response)

        Http.GoodStatus_ metadata response ->
            Json.Decode.decodeString decoder response
                |> Result.mapError (BadJson metadata response)
                |> Result.map (\data -> { meta = metadata, data = data })


{-| Useful for non-json payloads like Bytes or String

A resolver that does not process the response at all. It just returns the response as-is, but with `Http.Metadata` included. And with error type as `Ext.Http.Error` instead of `Http.Error`.

-}
identityResolver : Http.Response a -> Result (Error a) (Data a)
identityResolver resp =
    case resp of
        Http.BadUrl_ url ->
            Err (BadUrl url)

        Http.Timeout_ ->
            Err Timeout

        Http.NetworkError_ ->
            Err NetworkError

        Http.BadStatus_ metadata response ->
            Err (BadStatus metadata response)

        Http.GoodStatus_ metadata response ->
            Ok { meta = metadata, data = response }

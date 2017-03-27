module JSON.Route exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.Route exposing (..)


{-| `Route` encoder.
-}
encoder : Route -> Encode.Value
encoder =
    toHashUrl >> Encode.string


{-| `Route` decoder.
-}
decoder : Decode.Decoder Route
decoder =
    let
        {- Creates a fake location ignoring everything except the hash so we can use `parseHash` from the urlParser
           library to do the route parsing for us.
        -}
        fakeLocation hash =
            { href = ""
            , protocol = ""
            , host = ""
            , hostname = ""
            , port_ = ""
            , pathname = ""
            , search = ""
            , hash = hash
            , origin = ""
            , password = ""
            , username = ""
            }

        fromStringDecoder encodedHash =
            let
                maybeRoute =
                    parseLocation <| fakeLocation encodedHash
            in
                case maybeRoute of
                    Nothing ->
                        Decode.fail <| encodedHash ++ " is not a valid encoded hash!"

                    Just aRoute ->
                        Decode.succeed aRoute
    in
        Decode.string
            |> Decode.andThen fromStringDecoder

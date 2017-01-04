module Models.TidbitType
    exposing
        ( cacheEncoder
        , cacheDecoder
        , TidbitType(..)
        )

import Json.Decode as Decode
import Json.Encode as Encode


{-| A tidbit can have many formats, as the website develops more will be added.
-}
type TidbitType
    = Basic


{-| TidbitType `cacheEncoder`.
-}
cacheEncoder : TidbitType -> Encode.Value
cacheEncoder tidbitType =
    Encode.string (toString tidbitType)


{-| TidbitType `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder TidbitType
cacheDecoder =
    let
        fromStringDecoder encodedTidbitType =
            case encodedTidbitType of
                "Basic" ->
                    Decode.succeed Basic

                _ ->
                    Decode.fail <|
                        encodedTidbitType
                            ++ " is not a valid tidbitType."
    in
        Decode.andThen fromStringDecoder Decode.string

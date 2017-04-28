module JSON.Opinion exposing (..)

import DefaultServices.Util as Util
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import JSON.ContentPointer
import JSON.Rating
import Models.Opinion exposing (..)


{-| `Opinion` encoder.
-}
encoder : Opinion -> Encode.Value
encoder opinion =
    Encode.object
        [ ( "contentPointer", JSON.ContentPointer.encoder opinion.contentPointer )
        , ( "rating", JSON.Rating.encoder opinion.rating )
        ]


{-| `Opinion` decoder.
-}
decoder : Decode.Decoder Opinion
decoder =
    decode Opinion
        |> required "contentPointer" JSON.ContentPointer.decoder
        |> required "rating" JSON.Rating.decoder

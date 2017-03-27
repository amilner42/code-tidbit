module Pages.Create.JSON exposing (..)

import DefaultServices.Util as Util
import JSON.TidbitType
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Pages.Create.Model exposing (..)


{-| `Create` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "showInfoFor", Util.justValueOrNull JSON.TidbitType.encoder model.showInfoFor )
        ]


{-| `Create` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "showInfoFor" (Decode.maybe JSON.TidbitType.decoder)

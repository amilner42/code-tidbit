module Pages.Create.JSON exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.TidbitType
import Pages.Create.Model exposing (..)


{-| `CreateModel` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "showInfoFor"
          , Util.justValueOrNull JSON.TidbitType.encoder model.showInfoFor
          )
        ]


{-| `CreateModel` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "showInfoFor" (Decode.maybe JSON.TidbitType.decoder)

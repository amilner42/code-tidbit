module JSON.CreateData exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import JSON.TidbitType
import Models.CreateData exposing (..)


{-| `CreateData` encoder.
-}
encoder : CreateData -> Encode.Value
encoder createData =
    Encode.object
        [ ( "showInfoFor", Util.justValueOrNull JSON.TidbitType.encoder createData.showInfoFor )
        ]


{-| `CreateData` decoder.
-}
decoder : Decode.Decoder CreateData
decoder =
    decode CreateData
        |> required "showInfoFor" (Decode.maybe JSON.TidbitType.decoder)

module Models.CreateData exposing (..)

import DefaultServices.Util as Util
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.TidbitType as TidbitType


{-| All the data required for the create page.
-}
type alias CreateData =
    { showInfoFor : Maybe TidbitType.TidbitType
    }


{-| Sets `showInfoFor`.
-}
setShowInfoFor : Maybe TidbitType.TidbitType -> CreateData -> CreateData
setShowInfoFor maybeTidbitType createData =
    { createData
        | showInfoFor = maybeTidbitType
    }


{-| The default create page data.
-}
defaultCreateData : CreateData
defaultCreateData =
    { showInfoFor = Nothing
    }


{-| CreateData encoder.
-}
encoder : CreateData -> Encode.Value
encoder createData =
    Encode.object
        [ ( "showInfoFor", Util.justValueOrNull TidbitType.encoder createData.showInfoFor )
        ]


{-| CreateData decoder.
-}
decoder : Decode.Decoder CreateData
decoder =
    decode CreateData
        |> required "showInfoFor" (Decode.maybe TidbitType.decoder)

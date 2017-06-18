module Pages.Profile.JSON exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.Util as Util
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Pages.Profile.Model exposing (..)


{-| `Profile` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "accountName", Util.justValueOrNull (Editable.encoder Encode.string) model.accountName )
        , ( "accountBio", Util.justValueOrNull (Editable.encoder Encode.string) model.accountBio )
        , ( "logOutError", Encode.null )
        ]


{-| `Profile` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "accountName" (Decode.maybe <| Editable.decoder Decode.string)
        |> required "accountBio" (Decode.maybe <| Editable.decoder Decode.string)
        |> required "logOutError" (Decode.succeed Nothing)

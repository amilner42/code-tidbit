module JSON.ProfileData exposing (..)

import DefaultServices.Util as Util
import DefaultServices.Editable as Editable
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.ProfileData exposing (..)


{-| `ProfileData` encoder.
-}
encoder : ProfileData -> Encode.Value
encoder profileData =
    Encode.object
        [ ( "accountName", Util.justValueOrNull (Editable.encoder Encode.string) profileData.accountName )
        , ( "accountBio", Util.justValueOrNull (Editable.encoder Encode.string) profileData.accountBio )
        , ( "logOutError", Encode.null )
        ]


{-| `ProfileData` decoder.
-}
decoder : Decode.Decoder ProfileData
decoder =
    decode ProfileData
        |> required "accountName" (Decode.maybe <| Editable.decoder Decode.string)
        |> required "accountBio" (Decode.maybe <| Editable.decoder Decode.string)
        |> required "logOutError" (Decode.succeed Nothing)

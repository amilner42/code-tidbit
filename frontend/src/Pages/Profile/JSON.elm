module Pages.Profile.JSON exposing (..)

import DefaultServices.Editable as Editable
import DefaultServices.Util as Util
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Pages.Profile.Model exposing (..)


{-| `ProfileModel` encoder.
-}
encoder : Model -> Encode.Value
encoder profileData =
    Encode.object
        [ ( "accountName"
          , Util.justValueOrNull
                (Editable.encoder Encode.string)
                profileData.accountName
          )
        , ( "accountBio"
          , Util.justValueOrNull
                (Editable.encoder Encode.string)
                profileData.accountBio
          )
        , ( "logOutError", Encode.null )
        ]


{-| `ProfileModel` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "accountName"
            (Decode.maybe <| Editable.decoder Decode.string)
        |> required "accountBio"
            (Decode.maybe <| Editable.decoder Decode.string)
        |> required "logOutError"
            (Decode.succeed Nothing)

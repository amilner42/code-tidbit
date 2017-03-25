module Pages.Profile.JSON exposing (..)

import DefaultServices.Util as Util
import DefaultServices.Editable as Editable
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
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

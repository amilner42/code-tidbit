module Pages.Welcome.JSON exposing (..)

import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Pages.Welcome.Model exposing (..)


{-| `Welcome` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "name", Encode.string model.name )
        , ( "email", Encode.string model.email )
        , ( "password", Encode.string "" )
        , ( "confirmPassword", Encode.string "" )
        , ( "errorCode", Encode.null )
        ]


{-| `Welcome` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "name" Decode.string
        |> required "email" Decode.string
        |> required "password" Decode.string
        |> required "confirmPassword" Decode.string
        |> required "errorCode" (Decode.null Nothing)

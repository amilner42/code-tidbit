module Pages.Browse.JSON exposing (..)

import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Pages.Browse.Model exposing (..)


{-| `Browse` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "content", Encode.null )
        , ( "pageNumber", Encode.null )
        , ( "noMoreContent", Encode.null )
        ]


{-| `Browse` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> hardcoded Nothing
        |> hardcoded 1
        |> hardcoded False

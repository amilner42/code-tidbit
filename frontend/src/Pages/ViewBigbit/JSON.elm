module Pages.ViewBigbit.JSON exposing (..)

import DefaultServices.Util as Util
import JSON.Bigbit
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Pages.ViewBigbit.Model exposing (..)


{-| `ViewBigbit` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "bigbit", Util.justValueOrNull JSON.Bigbit.encoder model.bigbit )
        , ( "isCompleted", Encode.null )
        , ( "maybeOpinion", Encode.null )
        , ( "relevantHC", Encode.null )
        ]


{-| `ViewBigbit` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "bigbit" (Decode.maybe JSON.Bigbit.decoder)
        |> hardcoded Nothing
        |> hardcoded Nothing
        |> hardcoded Nothing

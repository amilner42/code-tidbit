module Pages.ViewBigbit.JSON exposing (..)

import DefaultServices.Util as Util
import Dict
import JSON.Bigbit
import JSON.QA
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import Models.TutorialBookmark as TB
import Pages.ViewBigbit.Model exposing (..)


{-| `ViewBigbit` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "bigbit", Util.justValueOrNull JSON.Bigbit.encoder model.bigbit )
        , ( "isCompleted", Encode.null )
        , ( "possibleOpinion", Encode.null )
        , ( "relevantHC", Encode.null )
        , ( "qa", Encode.null )
        , ( "relevantQuestions", Encode.null )
        , ( "bookmark", Encode.null )
        , ( "qaState", JSON.QA.qaStateEncoder JSON.QA.bigbitCodePointerEncoder model.qaState )
        , ( "tutorialCodePointer", Encode.null )
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
        |> hardcoded Nothing
        |> hardcoded Nothing
        |> hardcoded TB.Introduction
        |> optional "qaState" (JSON.QA.qaStateDecoder JSON.QA.bigbitCodePointerDecoder) Dict.empty
        |> hardcoded Nothing

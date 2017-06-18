module Pages.ViewSnipbit.JSON exposing (..)

import DefaultServices.Util as Util
import Dict
import JSON.Completed
import JSON.QA
import JSON.Range
import JSON.Snipbit
import JSON.TutorialBookmark
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Models.TutorialBookmark as TB
import Pages.ViewSnipbit.Model exposing (..)


{-| `ViewSnipbit` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "snipbit", Util.justValueOrNull JSON.Snipbit.encoder model.snipbit )
        , ( "isCompleted", Encode.null )
        , ( "possibleOpinion", Encode.null )
        , ( "relevantHC", Encode.null )
        , ( "qa", Encode.null )
        , ( "relevantQuestions", Encode.null )
        , ( "bookmark", JSON.TutorialBookmark.encoder model.bookmark )
        , ( "qaState", JSON.QA.qaStateEncoder JSON.Range.encoder model.qaState )
        , ( "tutorialCodePointer", Encode.null )
        ]


{-| `ViewSnipbit` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "snipbit" (Decode.maybe JSON.Snipbit.decoder)
        |> hardcoded Nothing
        |> hardcoded Nothing
        |> hardcoded Nothing
        |> hardcoded Nothing
        |> hardcoded Nothing
        |> optional "bookmark" JSON.TutorialBookmark.decoder TB.Introduction
        |> optional "qaState" (JSON.QA.qaStateDecoder JSON.Range.decoder) Dict.empty
        |> hardcoded Nothing
